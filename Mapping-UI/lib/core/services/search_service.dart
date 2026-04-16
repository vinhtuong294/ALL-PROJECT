import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/search_response.dart';
import '../error/exceptions.dart';
import 'auth/auth_service.dart';
import '../dependency/injection.dart';

/// Service để tìm kiếm gian hàng, món ăn, nguyên liệu
class SearchService {
  static const String baseUrl = AppConfig.baseUrl;
  final AuthService _authService = getIt<AuthService>();

  /// Tìm kiếm với query
  Future<SearchResponse> search(String query) async {
    try {
      final token = await _authService.getToken();
      
      final uri = Uri.parse('$baseUrl/search/').replace(
        queryParameters: {'q': query},
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
        return SearchResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token hết hạn hoặc không hợp lệ');
      } else if (response.statusCode == 404) {
        throw ServerException('Không tìm thấy kết quả');
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
