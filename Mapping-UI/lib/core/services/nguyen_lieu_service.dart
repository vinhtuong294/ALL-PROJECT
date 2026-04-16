import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/nguyen_lieu_model.dart';
import '../models/nguyen_lieu_detail_model.dart';
import '../config/app_config.dart';
import '../error/exceptions.dart';
import 'auth/auth_service.dart';
import '../dependency/injection.dart';

/// Service để fetch danh sách nguyên liệu
class NguyenLieuService {
  static const String baseUrl = AppConfig.buyerBaseUrl;
  final AuthService _authService = getIt<AuthService>();

  /// Lấy danh sách nguyên liệu
  Future<NguyenLieuResponse> getNguyenLieuList({
    int page = 1,
    int limit = 12,
    String sort = 'ten_nguyen_lieu',
    String order = 'asc',
    String? maCho, // Thêm parameter mã chợ
    String? maNhomNguyenLieu, // Thêm parameter mã nhóm nguyên liệu
    String? search, // Thêm parameter search
    bool hinhAnh = true, // Thêm parameter hình ảnh
  }) async {
    try {
      final token = await _authService.getToken();
      
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sort,
        'order': order,
        'hinh_anh': hinhAnh.toString(),
        if (maCho != null && maCho.isNotEmpty) 'ma_cho': maCho,
        if (maNhomNguyenLieu != null && maNhomNguyenLieu.isNotEmpty) 'ma_nhom_nguyen_lieu': maNhomNguyenLieu,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      
      final uri = Uri.parse('$baseUrl/nguyen-lieu').replace(
        queryParameters: queryParams,
      );

      debugPrint('🔍 [NguyenLieuService] Fetching nguyen lieu...');
      debugPrint('   URL: $uri');
      debugPrint('   Ma cho: $maCho');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🔍 [NguyenLieuService] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        final result = NguyenLieuResponse.fromJson(jsonData);
        debugPrint('✅ [NguyenLieuService] Fetched ${result.data.length} nguyen lieu');
        return result;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token hết hạn hoặc không hợp lệ');
      } else {
        throw ServerException('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [NguyenLieuService] Error: $e');
      if (e is UnauthorizedException || e is ServerException) {
        rethrow;
      }
      throw NetworkException('Lỗi kết nối: ${e.toString()}');
    }
  }

  /// Lấy chi tiết nguyên liệu theo mã
  Future<NguyenLieuDetailResponse> getNguyenLieuDetail(String maNguyenLieu) async {
    try {
      final token = await _authService.getToken();
      
      final uri = Uri.parse('$baseUrl/nguyen-lieu/$maNguyenLieu');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return NguyenLieuDetailResponse.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token hết hạn hoặc không hợp lệ');
      } else if (response.statusCode == 404) {
        throw ServerException('Không tìm thấy nguyên liệu');
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
