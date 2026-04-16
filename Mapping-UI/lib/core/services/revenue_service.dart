import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth/auth_service.dart';
import '../services/auth/simple_auth_helper.dart';

class RevenueService {
  static const String _baseUrl = AppConfig.sellerBaseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getRevenue({
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final token = await getToken();
      if (token == null) throw Exception('User not logged in');

      final uri = Uri.parse('$_baseUrl/revenue').replace(
        queryParameters: {
          'from_date': fromDate,
          'to_date': toDate,
        },
      );

      print('💰 [REVENUE_SERVICE] GET $uri');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('💰 [REVENUE_SERVICE] Response: ${response.statusCode}');
      print('💰 [REVENUE_SERVICE] Body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 401) {
        await _authService.handleUnauthorized();
        throw Exception('Phiên đăng nhập hết hạn');
      } else {
        throw Exception('Failed to load revenue: ${response.statusCode}');
      }
    } catch (e) {
      print('💰 [REVENUE_SERVICE] Exception: $e');
      rethrow;
    }
  }
}
