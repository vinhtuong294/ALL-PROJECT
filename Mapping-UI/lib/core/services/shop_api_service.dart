import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../utils/app_logger.dart';
import 'auth/simple_auth_helper.dart';

/// Service để fetch thông tin gian hàng từ API
class ShopApiService {
  static const String _baseUrl = AppConfig.buyerBaseUrl;

  /// Fetch thông tin chi tiết của một gian hàng
  /// API: GET /api/buyer/shops/{ma_gian_hang}
  Future<ShopDetailResponse> getShopDetail(String maGianHang) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('🏪 [SHOP API] Fetching shop detail: $maGianHang');
    }

    try {
      final token = await getToken();

      if (token == null) {
        if (AppConfig.enableApiLogging) {
          AppLogger.warning('🏪 [SHOP API] No token found - user not logged in');
        }
        throw Exception('User not logged in');
      }

      final url = Uri.parse('$_baseUrl/shops/$maGianHang');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🏪 [SHOP API] Response Status: ${response.statusCode}');
      print('🏪 [SHOP API] Response Body: ${response.body}');

      if (AppConfig.enableApiLogging) {
        AppLogger.info('🏪 [SHOP API] Response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));

        if (AppConfig.enableApiLogging) {
          AppLogger.info('🏪 [SHOP API] Response data: $jsonData');
        }

        final shopResponse = ShopDetailResponse.fromJson(jsonData);

        if (AppConfig.enableApiLogging) {
          AppLogger.info('✅ [SHOP API] Success - ${shopResponse.shop.maGianHang}');
        }

        return shopResponse;
      } else {
        throw Exception(
            'Failed to load shop: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [SHOP API] Error: $e');
      }
      rethrow;
    }
  }

  /// Fetch danh sách sản phẩm của gian hàng
  /// API: GET /api/buyer/shops/{ma_gian_hang}/products
  Future<ShopProductsResponse> getShopProducts(String maGianHang) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('🏪 [SHOP API] Fetching shop products: $maGianHang');
    }

    try {
      final token = await getToken();

      if (token == null) {
        throw Exception('User not logged in');
      }

      final url = Uri.parse('$_baseUrl/shops/$maGianHang/products');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('🏪 [SHOP API] Products Response Status: ${response.statusCode}');
      print('🏪 [SHOP API] Products Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return ShopProductsResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to load products: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [SHOP API] Error loading products: $e');
      }
      rethrow;
    }
  }
}

/// Response model cho shop detail
class ShopDetailResponse {
  final bool success;
  final ShopDetail shop;

  ShopDetailResponse({
    required this.success,
    required this.shop,
  });

  factory ShopDetailResponse.fromJson(Map<String, dynamic> json) {
    return ShopDetailResponse(
      success: json['success'] ?? false,
      shop: ShopDetail.fromJson(json['shop'] ?? {}),
    );
  }
}

/// Model cho thông tin chi tiết gian hàng
class ShopDetail {
  final String maGianHang;
  final String tenGianHang;
  final String? hinhAnh;
  final double? danhGia;
  final int? soMatHangBan;
  final int? soDonHangBan;
  final String? diaChi;

  ShopDetail({
    required this.maGianHang,
    required this.tenGianHang,
    this.hinhAnh,
    this.danhGia,
    this.soMatHangBan,
    this.soDonHangBan,
    this.diaChi,
  });

  factory ShopDetail.fromJson(Map<String, dynamic> json) {
    return ShopDetail(
      maGianHang: json['ma_gian_hang'] ?? '',
      tenGianHang: json['ten_gian_hang'] ?? '',
      hinhAnh: json['hinh_anh'],
      danhGia: _parseToDouble(json['danh_gia']),
      soMatHangBan: _parseToInt(json['so_mat_hang_ban']),
      soDonHangBan: _parseToInt(json['so_don_hang_ban']),
      diaChi: json['dia_chi'],
    );
  }

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Response model cho shop products
class ShopProductsResponse {
  final bool success;
  final List<ShopProductItem> products;

  ShopProductsResponse({
    required this.success,
    required this.products,
  });

  factory ShopProductsResponse.fromJson(Map<String, dynamic> json) {
    final productsList = json['products'] as List<dynamic>? ?? [];
    return ShopProductsResponse(
      success: json['success'] ?? false,
      products: productsList
          .map((item) => ShopProductItem.fromJson(item))
          .toList(),
    );
  }
}

/// Model cho sản phẩm trong gian hàng
class ShopProductItem {
  final String maNguyenLieu;
  final String tenNguyenLieu;
  final double giaCuoi;
  final String? hinhAnh;
  final String maGianHang;

  ShopProductItem({
    required this.maNguyenLieu,
    required this.tenNguyenLieu,
    required this.giaCuoi,
    this.hinhAnh,
    required this.maGianHang,
  });

  factory ShopProductItem.fromJson(Map<String, dynamic> json) {
    return ShopProductItem(
      maNguyenLieu: json['ma_nguyen_lieu'] ?? '',
      tenNguyenLieu: json['ten_nguyen_lieu'] ?? '',
      giaCuoi: _parseToDouble(json['gia_cuoi']),
      hinhAnh: json['hinh_anh'],
      maGianHang: json['ma_gian_hang'] ?? '',
    );
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
