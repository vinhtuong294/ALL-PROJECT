import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/app_logger.dart';
import 'local_storage_service.dart';
import 'auth/auth_service.dart';

/// Interceptor để xử lý request/response và thêm token vào header
class NetworkInterceptor extends Interceptor {
  final LocalStorageService _localStorageService;
  final AuthService _authService = AuthService();

  NetworkInterceptor(this._localStorageService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Add authorization token if exists
    final token = await _localStorageService.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Add content type
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';

    // Log request
    AppLogger.logRequest(
      options.method,
      options.uri.toString(),
      data: options.data,
    );

    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // Log response
    AppLogger.logResponse(
      response.statusCode ?? 0,
      response.requestOptions.uri.toString(),
      data: response.data,
    );

    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Log error
    AppLogger.logApiError(
      err.requestOptions.method,
      err.requestOptions.uri.toString(),
      err.message,
    );

    // Handle 401 Unauthorized - Token expired
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      final refreshed = await _refreshToken(err.requestOptions);
      if (refreshed) {
        // Retry original request
        try {
          final response = await Dio().fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // If retry fails, continue with error
        }
      } else {
        // Refresh failed or not available - Logout
        await _authService.handleUnauthorized();
      }
    }

    handler.next(err);
  }

  /// Refresh token and retry request
  Future<bool> _refreshToken(RequestOptions options) async {
    try {
      final refreshToken = await _localStorageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // Call refresh token API
      final dio = Dio();
      final response = await dio.post(
        AppConfig.instance.getApiUrl('/auth/refresh'),
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final newToken = response.data['access_token'] as String?;
        final newRefreshToken = response.data['refresh_token'] as String?;

        if (newToken != null) {
          await _localStorageService.saveToken(newToken);
          if (newRefreshToken != null) {
            await _localStorageService.saveRefreshToken(newRefreshToken);
          }
          
          // Update token in failed request
          options.headers['Authorization'] = 'Bearer $newToken';
          return true;
        }
      }

      return false;
    } catch (e) {
      AppLogger.error('Failed to refresh token', e);
      return false;
    }
  }
}
