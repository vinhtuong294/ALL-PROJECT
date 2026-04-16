import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

/// Token hết hạn hoặc không hợp lệ
class UnauthorizedException implements Exception {
  const UnauthorizedException();
  @override
  String toString() => 'Phiên đăng nhập hết hạn';
}

class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  static const String coreBaseUrl = 'http://localhost:8000'; // Local dev

  static const _timeout = Duration(seconds: 12);

  // ── helpers ──
  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static dynamic _decode(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    return jsonDecode(body);
  }

  // ══════════════════════════════════════════════
  //  AUTH
  // ══════════════════════════════════════════════

  /// POST /api/auth/login
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'ten_dang_nhap': username, 'mat_khau': password}),
    );
    if (res.statusCode == 200) {
      final data = _decode(res);
      await AuthStorage.saveToken(data['token']);
      await AuthStorage.saveUserData(data['data']);
      return data;
    }
    throw Exception(_decode(res)['detail'] ?? 'Đăng nhập thất bại');
  }

  /// GET /api/auth/me
  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _decode(res);
      // Save wallet_id + shipper_id for later use
      final d = data['data'] as Map<String, dynamic>;
      await AuthStorage.saveUserData(d);
      return d;
    }
    throw Exception('Không thể lấy thông tin người dùng');
  }

  /// PUT /api/auth/profile
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) return _decode(res);
    throw Exception('Cập nhật thất bại');
  }

  /// POST /api/auth/change-password
  static Future<Map<String, dynamic>> changePassword(String oldPass, String newPass) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/change-password'),
      headers: await _headers(),
      body: jsonEncode({'mat_khau_cu': oldPass, 'mat_khau_moi': newPass}),
    );
    if (res.statusCode == 200) return _decode(res);
    throw Exception(_decode(res)['detail'] ?? 'Đổi mật khẩu thất bại');
  }

  /// GET /api/auth/login-history
  static Future<List<dynamic>> getLoginHistory() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/auth/login-history'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = _decode(res);
      return data['data'] as List<dynamic>;
    }
    throw Exception('Lỗi lấy lịch sử đăng nhập');
  }

  /// POST /api/auth/logout
  static Future<void> logout() async {
    try {
      await http.post(Uri.parse('$baseUrl/api/auth/logout'), headers: await _headers());
    } catch (_) {}
    await AuthStorage.clear();
  }

  // ══════════════════════════════════════════════
  //  SHIPPER
  // ══════════════════════════════════════════════

  /// GET /api/shipper/me
  static Future<Map<String, dynamic>> getShipperMe() async {
    final res = await http.get(
      Uri.parse('$coreBaseUrl/api/shipper/me'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return _decode(res);
    throw Exception('Lỗi lấy thông tin shipper');
  }

  /// GET /api/shipper/orders/available
  static Future<Map<String, dynamic>> getAvailableOrders({int page = 1, int limit = 10, String? status}) async {
    final params = {'page': '$page', 'limit': '$limit'};
    if (status != null) params['tinh_trang_don_hang'] = status;
    final uri = Uri.parse('$coreBaseUrl/api/shipper/orders/available').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers()).timeout(_timeout);
    if (res.statusCode == 200) return _decode(res);
    if (res.statusCode == 401 || res.statusCode == 403) throw const UnauthorizedException();
    throw Exception('Lỗi lấy đơn hàng có sẵn (${res.statusCode})');
  }

  /// GET /api/shipper/orders/my
  static Future<Map<String, dynamic>> getMyOrders({int page = 1, int limit = 10, String? status}) async {
    final params = {'page': '$page', 'limit': '$limit'};
    if (status != null) params['tinh_trang_don_hang'] = status;
    final uri = Uri.parse('$coreBaseUrl/api/shipper/orders/my').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers()).timeout(_timeout);
    if (res.statusCode == 200) return _decode(res);
    if (res.statusCode == 401 || res.statusCode == 403) throw const UnauthorizedException();
    throw Exception('Lỗi lấy đơn hàng của tôi (${res.statusCode})');
  }

  /// POST /api/shipper/orders/accept
  static Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    final res = await http.post(
      Uri.parse('$coreBaseUrl/api/shipper/orders/accept'),
      headers: await _headers(),
      body: jsonEncode({'ma_don_hang': orderId}),
    );
    if (res.statusCode == 200) return _decode(res);
    throw Exception(_decode(res)['detail'] ?? 'Nhận đơn thất bại');
  }

  /// PATCH /api/shipper/orders/{ma_don_hang}/status
  static Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    final res = await http.patch(
      Uri.parse('$coreBaseUrl/api/shipper/orders/$orderId/status'),
      headers: await _headers(),
      body: jsonEncode({'tinh_trang_don_hang': status}),
    );
    if (res.statusCode == 200) return _decode(res);
    throw Exception(_decode(res)['detail'] ?? 'Cập nhật trạng thái thất bại');
  }

  /// GET /api/shipper/orders/{ma_don_hang}/details
  static Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    final res = await http.get(
      Uri.parse('$coreBaseUrl/api/shipper/orders/$orderId/details'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return _decode(res);
    throw Exception('Lỗi lấy chi tiết đơn hàng');
  }

  // ══════════════════════════════════════════════
  //  WALLET
  // ══════════════════════════════════════════════

  /// GET /api/wallets/{wallet_id}/balance
  static Future<Map<String, dynamic>> getWalletBalance({String? filterType, String? fromDate, String? toDate}) async {
    final walletId = await AuthStorage.getWalletId();
    if (walletId == null) throw Exception('Không tìm thấy ví');
    final params = <String, String>{};
    if (filterType != null) params['filter_type'] = filterType;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    final uri = Uri.parse('$baseUrl/api/wallets/$walletId/balance').replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) return _decode(res);
    throw Exception('Lỗi lấy số dư ví');
  }

  /// POST /api/wallets/{wallet_id}/withdraw
  static Future<Map<String, dynamic>> requestWithdraw(int amount, String bankBin, String bankAccountNo, String accountName) async {
    final walletId = await AuthStorage.getWalletId();
    if (walletId == null) throw Exception('Không tìm thấy ví');
    final res = await http.post(
      Uri.parse('$baseUrl/api/wallets/$walletId/withdraw'),
      headers: await _headers(),
      body: jsonEncode({
        'amount': amount,
        'bank_bin': bankBin,
        'bank_account_no': bankAccountNo,
        'account_name': accountName,
      }),
    );
    if (res.statusCode == 200) return _decode(res);
    throw Exception(_decode(res)['detail'] ?? 'Yêu cầu rút tiền thất bại');
  }

  // ══════════════════════════════════════════════
  //  DASHBOARD & EARNINGS
  // ══════════════════════════════════════════════

  /// GET /api/shipper/dashboard
  static Future<Map<String, dynamic>> getDashboard() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/shipper/dashboard'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return _decode(res);
    throw Exception('Lỗi lấy thống kê dashboard');
  }

  /// GET /api/shipper/earnings
  static Future<Map<String, dynamic>> getEarnings({String? filterType, String? fromDate, String? toDate}) async {
    final params = <String, String>{};
    if (filterType != null) params['filter_type'] = filterType;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    final uri = Uri.parse('$baseUrl/api/shipper/earnings').replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) return _decode(res);
    throw Exception('Lỗi lấy lịch sử thu nhập');
  }

  // ══════════════════════════════════════════════
  //  PROFILE UPDATE
  // ══════════════════════════════════════════════

  /// PUT /api/shipper/profile
  static Future<Map<String, dynamic>> updateShipperProfile(Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/shipper/profile'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) return _decode(res);
    throw Exception('Cập nhật profile shipper thất bại');
  }

  // ══════════════════════════════════════════════
  //  POD & FAILED DELIVERY
  // ══════════════════════════════════════════════

  /// POST /api/shipper/orders/{id}/pod
  static Future<Map<String, dynamic>> submitPod(String orderId, String imageUrl, {String? note}) async {
    final body = <String, dynamic>{'image_url': imageUrl};
    if (note != null && note.isNotEmpty) body['note'] = note;
    final res = await http.post(
      Uri.parse('$baseUrl/api/shipper/orders/$orderId/pod'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) return _decode(res);
    throw Exception(_decode(res)['detail'] ?? 'Lỗi gửi POD');
  }

  /// POST /api/shipper/orders/{id}/fail
  static Future<Map<String, dynamic>> reportFailedDelivery(String orderId, String reason, {String? note, String? evidenceUrl}) async {
    final body = <String, dynamic>{'reason': reason};
    if (note != null && note.isNotEmpty) body['note'] = note;
    if (evidenceUrl != null && evidenceUrl.isNotEmpty) body['evidence_image_url'] = evidenceUrl;
    final res = await http.post(
      Uri.parse('$baseUrl/api/shipper/orders/$orderId/fail'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) return _decode(res);
    throw Exception(_decode(res)['detail'] ?? 'Lỗi báo cáo giao thất bại');
  }

  // ══════════════════════════════════════════════
  //  REVIEWS
  // ══════════════════════════════════════════════

  /// GET /api/shipper/reviews
  static Future<Map<String, dynamic>> getReviews({int page = 1, int limit = 10}) async {
    final uri = Uri.parse('$baseUrl/api/shipper/reviews').replace(queryParameters: {'page': '$page', 'limit': '$limit'});
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) return _decode(res);
    throw Exception('Lỗi lấy đánh giá');
  }

  // ══════════════════════════════════════════════
  //  NOTIFICATIONS
  // ══════════════════════════════════════════════

  /// GET /api/shipper/notifications
  static Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/api/shipper/notifications').replace(queryParameters: {'page': '$page', 'limit': '$limit'});
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode == 200) return _decode(res);
    throw Exception('Lỗi lấy thông báo');
  }

  /// PATCH /api/shipper/notifications/{id}/read
  static Future<Map<String, dynamic>> markNotificationRead(int notiId) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/shipper/notifications/$notiId/read'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return _decode(res);
    throw Exception('Lỗi đánh dấu đã đọc');
  }

  /// PATCH /api/shipper/notifications/read-all
  static Future<Map<String, dynamic>> markAllNotificationsRead() async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/shipper/notifications/read-all'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) return _decode(res);
    throw Exception('Lỗi đánh dấu tất cả đã đọc');
  }
}
