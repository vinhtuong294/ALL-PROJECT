import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/cho_model.dart';
import 'auth/auth_service.dart';

class ChoService {
  final AuthService _authService;
  late final Dio _dio;
  
  static const String baseUrl = AppConfig.baseUrl;

  ChoService(this._authService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: 30000),
        receiveTimeout: const Duration(milliseconds: 30000),
      ),
    );
  }

  /// Lấy danh sách chợ theo khu vực
  Future<List<ChoModel>> getChoListByKhuVuc({
    required String maKhuVuc,
    int page = 1,
    int limit = 12,
    String sort = 'ten_cho',
    String order = 'asc',
  }) async {
    try {
      final token = await _authService.getToken();
      
      final url = '/buyer/cho';
      print('🔍 [ChoService] Fetching cho list...');
      print('   Full URL: $baseUrl$url');
      print('   Ma khu vuc: $maKhuVuc');
      print('   Token: ${token?.substring(0, 20)}...');
      
      final response = await _dio.get(
        url,
        queryParameters: {
          'ma_khu_vuc': maKhuVuc,
          'page': page,
          'limit': limit,
          'sort': sort,
          'order': order,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('🔍 [ChoService] Response status: ${response.statusCode}');
      print('🔍 [ChoService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final choResponse = ChoResponse.fromJson(response.data);
        print('🔍 [ChoService] Parsed ${choResponse.data.length} cho');
        return choResponse.data;
      } else {
        throw Exception('Failed to load cho list: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [ChoService] DioException: ${e.type}');
      print('   Message: ${e.message}');
      print('   Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      print('❌ [ChoService] Error: $e');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }
}
