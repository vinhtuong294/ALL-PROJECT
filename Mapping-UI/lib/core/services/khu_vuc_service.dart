import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../models/khu_vuc_model.dart';
import 'auth/auth_service.dart';

class KhuVucService {
  final AuthService _authService;
  late final Dio _dio;
  
  static const String baseUrl = AppConfig.baseUrl;

  KhuVucService(this._authService) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(milliseconds: 30000),
        receiveTimeout: const Duration(milliseconds: 30000),
      ),
    );
  }

  /// Lấy danh sách khu vực
  Future<List<KhuVucModel>> getKhuVucList({
    int page = 1,
    int limit = 12,
    String sort = 'phuong',
    String order = 'asc',
  }) async {
    try {
      final token = await _authService.getToken();
      
      final url = '/buyer/khu-vuc';
      print('🔍 [KhuVucService] Fetching khu vuc list...');
      print('   Full URL: $baseUrl$url');
      print('   Token: ${token?.substring(0, 20)}...');
      
      final response = await _dio.get(
        url,
        queryParameters: {
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

      print('🔍 [KhuVucService] Response status: ${response.statusCode}');
      print('🔍 [KhuVucService] Response data: ${response.data}');

      if (response.statusCode == 200) {
        final khuVucResponse = KhuVucResponse.fromJson(response.data);
        print('🔍 [KhuVucService] Parsed ${khuVucResponse.data.length} khu vuc');
        return khuVucResponse.data;
      } else {
        throw Exception('Failed to load khu vuc list: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('❌ [KhuVucService] DioException: ${e.type}');
      print('   Message: ${e.message}');
      print('   Response: ${e.response?.data}');
      rethrow;
    } catch (e, stackTrace) {
      print('❌ [KhuVucService] Error: $e');
      print('   StackTrace: $stackTrace');
      rethrow;
    }
  }
}
