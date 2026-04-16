import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth/simple_auth_helper.dart';
import '../utils/app_logger.dart';

/// Exception riêng cho VNPay để BLoC/Cubit dễ dàng catch và báo lỗi UI chính xác
class VNPayException implements Exception {
  final String message;
  final int? statusCode;
  VNPayException(this.message, [this.statusCode]);

  @override
  String toString() => 'VNPayException: $message ${statusCode != null ? '(Status: $statusCode)' : ''}';
}

/// Service để xử lý thanh toán VNPay
class VNPayService {
  // Thay vì hardcode IP, lấy baseUrl chuẩn và tự động làm sạch (xoá /api nếu cần thiết)
  String get _baseUrl {
    String base = AppConfig.baseUrl; // Vd: http://207.180.233.84:8000/api
    if (base.endsWith('/api')) {
      return base.substring(0, base.length - 4); // Cắt '/api' ra để lấy root domain cho vnpay return
    }
    return base;
  }

  /// Get order status để check kết quả thanh toán
  Future<OrderStatusResponse> getOrderStatus(String maDonHang) async {
    AppLogger.info('💳 [VNPAY] Getting order status for: $maDonHang');

    try {
      final token = await getToken();
      if (token == null) throw VNPayException('User not logged in', 401);

      final url = Uri.parse('${AppConfig.baseUrl}/orders/$maDonHang');
      AppLogger.info('💳 [VNPAY] Request URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info('💳 [VNPAY] Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return OrderStatusResponse.fromJson(jsonData);
      } else {
        throw VNPayException('Failed to get order status: ${response.body}', response.statusCode);
      }
    } catch (e) {
      AppLogger.error('❌ [VNPAY] Error: $e');
      if (e is VNPayException) rethrow;
      throw VNPayException('Lỗi mạng hoặc server không phản hồi', 500);
    }
  }

  /// Verify payment result từ VNPay callback
  Future<VNPayReturnResponse> verifyPaymentReturn({
    required Map<String, String> queryParams,
  }) async {
    AppLogger.info('💳 [VNPAY] Verifying payment return...');
    AppLogger.info('💳 [VNPAY] Query params: $queryParams');

    try {
      final token = await getToken();
      if (token == null) throw VNPayException('User not logged in', 401);

      // Build URL với query parameters
      final uri = Uri.parse('$_baseUrl/vnpay/return').replace(
        queryParameters: queryParams,
      );

      AppLogger.info('💳 [VNPAY] Request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      AppLogger.info('💳 [VNPAY] Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return VNPayReturnResponse.fromJson(jsonData);
      } else {
        throw VNPayException('Failed to verify payment: ${response.body}', response.statusCode);
      }
    } catch (e) {
      AppLogger.error('❌ [VNPAY] Error: $e');
      if (e is VNPayException) rethrow;
      throw VNPayException('Lỗi khi verify kết quả VNPay', 500);
    }
  }

  /// Tạo checkout VNPay
  Future<VNPayCheckoutResponse> createVNPayCheckout({
    required String maThanhToan,
    String bankCode = 'NCB',
  }) async {
    AppLogger.info('💳 [VNPAY] Creating checkout...');
    AppLogger.info('💳 [VNPAY] ma_thanh_toan: $maThanhToan, bankCode: $bankCode');

    try {
      final token = await getToken();
      if (token == null) throw VNPayException('User not logged in', 401);

      final url = Uri.parse('$_baseUrl/vnpay/checkout');
      final requestBody = {
        'order_id': maThanhToan,
        'bankCode': bankCode,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      AppLogger.info('💳 [VNPAY] Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        return VNPayCheckoutResponse.fromJson(jsonData);
      } else {
        throw VNPayException('Failed to create VNPay checkout: ${response.body}', response.statusCode);
      }
    } catch (e) {
      AppLogger.error('❌ [VNPAY] Error: $e');
      if (e is VNPayException) rethrow;
      throw VNPayException('Lỗi kết nối khi khởi tạo thanh toán VNPay', 500);
    }
  }
}

/// Model cho VNPay checkout response
class VNPayCheckoutResponse {
  final bool success;
  final String redirect;
  final String maThanhToan;
  final double amount;

  VNPayCheckoutResponse({
    required this.success,
    required this.redirect,
    required this.maThanhToan,
    required this.amount,
  });

  factory VNPayCheckoutResponse.fromJson(Map<String, dynamic> json) {
    return VNPayCheckoutResponse(
      success: json['success'] ?? false,
      redirect: json['redirect'] ?? '',
      maThanhToan: json['ma_thanh_toan'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Model cho Order status response
class OrderStatusResponse {
  final bool success;
  final String maDonHang;
  final String trangThai; // VD: "da_thanh_toan", "cho_thanh_toan", "huy"
  final String? message;
  final double? tongTien;

  OrderStatusResponse({
    required this.success,
    required this.maDonHang,
    required this.trangThai,
    this.message,
    this.tongTien,
  });

  factory OrderStatusResponse.fromJson(Map<String, dynamic> json) {
    // Xử lý cả trường hợp response có nested "order" object hoặc flat
    final orderData = json['order'] as Map<String, dynamic>? ?? json;
    
    return OrderStatusResponse(
      success: json['success'] ?? true,
      maDonHang: orderData['ma_don_hang'] ?? json['ma_don_hang'] ?? '',
      trangThai: orderData['trang_thai'] ?? json['trang_thai'] ?? '',
      message: json['message'],
      tongTien: (orderData['tong_tien'] as num?)?.toDouble() ?? 
               (json['tong_tien'] as num?)?.toDouble(),
    );
  }

  bool get isPaid => trangThai == 'da_thanh_toan' || trangThai == 'paid';
  bool get isPending => trangThai == 'cho_thanh_toan' || trangThai == 'pending';
  bool get isCancelled => trangThai == 'huy' || trangThai == 'cancelled';
}

/// Model cho VNPay return response (kết quả thanh toán)
class VNPayReturnResponse {
  final bool success;
  final String message;
  final String maDonHang;
  final bool clearCart;

  VNPayReturnResponse({
    required this.success,
    required this.message,
    required this.maDonHang,
    required this.clearCart,
  });

  factory VNPayReturnResponse.fromJson(Map<String, dynamic> json) {
    return VNPayReturnResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      maDonHang: json['ma_don_hang'] ?? '',
      clearCart: json['clear_cart'] ?? false,
    );
  }
}
