import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/danh_muc_nguyen_lieu_model.dart';
import '../error/exceptions.dart';
import 'auth/auth_service.dart';
import '../dependency/injection.dart';

/// Service để fetch danh mục nguyên liệu
class DanhMucNguyenLieuService {
  static const String baseUrl = AppConfig.buyerBaseUrl;
  final AuthService _authService = getIt<AuthService>();

  /// Lấy danh sách danh mục nguyên liệu
  Future<DanhMucNguyenLieuResponse> getDanhMucNguyenLieuList({
    int page = 1,
    int limit = 12,
    String sort = 'ten_nhom_nguyen_lieu',
    String order = 'asc',
  }) async {
    try {
      final token = await _authService.getToken();
      
      final uri = Uri.parse('$baseUrl/danh-muc-nguyen-lieu').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'sort': sort,
          'order': order,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return DanhMucNguyenLieuResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token hết hạn hoặc không hợp lệ');
      } else {
        throw ServerException('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      if (e is UnauthorizedException || e is ServerException) {
        rethrow;
      }
      throw NetworkException('Lỗi kết nối: ${e.toString()}');
    }
  }
}
