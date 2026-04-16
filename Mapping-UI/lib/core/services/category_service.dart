import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/category_model.dart';
import '../error/exceptions.dart';
import 'package:logger/logger.dart';

/// Service để gọi API lấy danh mục món ăn
class CategoryService {
  static const String _baseUrl = AppConfig.buyerBaseUrl;
  static const String _endpoint = '/danh-muc-mon-an';
  static const String _tokenKey = 'auth_token';

  final Dio _dio;
  final Logger _logger = Logger();

  CategoryService({Dio? dio}) : _dio = dio ?? Dio();

  /// Lấy danh mục món ăn từ API
  /// 
  /// [page] - Trang hiện tại (mặc định: 1)
  /// [limit] - Số lượng item trên 1 trang (mặc định: 12)
  /// 
  /// Trả về: List<CategoryModel> - Danh sách danh mục món ăn
  /// 
  /// Throws:
  /// - UnauthorizedException: Nếu token không hợp lệ hoặc hết hạn
  /// - NetworkException: Nếu có lỗi kết nối
  /// - ServerException: Nếu server trả về lỗi
  Future<List<CategoryModel>> getDanhMucMonAn({
    int page = 1,
    int limit = 12,
  }) async {
    try {
      // 1. Lấy token từ SharedPreferences
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        _logger.e('Token không tìm thấy');
        throw UnauthorizedException('Vui lòng đăng nhập lại');
      }

      // 2. Chuẩn bị headers với Bearer token
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // 3. Gửi GET request
      final url = '$_baseUrl$_endpoint?page=$page&limit=$limit';
      _logger.i('Gọi API: GET $url');

      final response = await _dio.get(
        url,
        options: Options(headers: headers),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logger.e('Timeout khi gọi API danh mục');
          throw NetworkException('Kết nối bị timeout, vui lòng thử lại');
        },
      );

      // 4. Kiểm tra status code
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 5. Parse response
        final data = response.data as Map<String, dynamic>;
        
        // 6. Lấy danh mục từ data
        final categoriesJson = data['data'] as List<dynamic>? ?? [];
        final categories = categoriesJson
            .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();

        // 7. Lấy meta nếu cần
        if (data.containsKey('meta')) {
          final metaJson = data['meta'] as Map<String, dynamic>;
          final meta = MetaModel.fromJson(metaJson);
          _logger.i('API trả về ${categories.length} danh mục (trang ${meta.page}/${(meta.total / meta.limit).ceil()})');
        }

        return categories;
      } else if (response.statusCode == 401) {
        _logger.e('Token không hợp lệ hoặc hết hạn');
        throw UnauthorizedException('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại');
      } else {
        _logger.e('Lỗi server: ${response.statusCode}');
        throw ServerException('Lỗi server: ${response.statusCode}');
      }
    } on UnauthorizedException catch (e) {
      _logger.e('UnauthorizedException: ${e.message}');
      rethrow;
    } on NetworkException catch (e) {
      _logger.e('NetworkException: ${e.message}');
      rethrow;
    } on ServerException catch (e) {
      _logger.e('ServerException: ${e.message}');
      rethrow;
    } on DioException catch (e) {
      _logger.e('DioException: ${e.message}');
      
      // Xử lý các lỗi cụ thể từ Dio
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Kết nối bị timeout, vui lòng thử lại');
      } else if (e.type == DioExceptionType.unknown) {
        throw NetworkException('Lỗi kết nối mạng, vui lòng kiểm tra kết nối');
      } else if (e.response?.statusCode == 401) {
        throw UnauthorizedException('Token không hợp lệ, vui lòng đăng nhập lại');
      } else {
        throw ServerException('Lỗi server: ${e.message}');
      }
    } catch (e) {
      _logger.e('Lỗi không xác định: $e');
      throw ServerException('Có lỗi xảy ra, vui lòng thử lại');
    }
  }

  /// Lấy token từ SharedPreferences
  /// 
  /// Trả về: String? - Token hoặc null nếu không tìm thấy
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      _logger.e('Lỗi khi lấy token: $e');
      return null;
    }
  }
}
