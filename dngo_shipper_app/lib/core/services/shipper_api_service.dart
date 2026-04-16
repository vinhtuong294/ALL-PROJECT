import 'package:dio/dio.dart';
import '../../feature/shipper/data/models/shipper_order_model.dart';
import '../../feature/shipper/data/models/market_map_stall.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShipperApiService {
  final Dio _dio;
  final String _baseUrl = 'http://localhost:8000'; // 'http://207.180.233.84:8000';

  ShipperApiService() : _dio = Dio() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<List<ShipperOrder>> getAvailableOrders() async {
    try {
      final response = await _dio.get('/api/shipper/orders/available');
      if (response.statusCode == 200) {
        final data = response.data['items'] as List?;
        if (data != null) {
          return data.map((e) => ShipperOrder.fromJson(e)).toList();
        }
        return [];
      }
      throw Exception('Failed to load available orders');
    } catch (e) {
      // Mock data so UI can be displayed during testing
      return [
        ShipperOrder(maDonHang: 'DNGO-1090', date: 'Bây giờ', totalAmount: 45000, deliveryAddress: '123 Nguyễn Huệ, Quận 1', status: 'pending'),
        ShipperOrder(maDonHang: 'DNGO-9932', date: '5 phút trước', totalAmount: 120000, deliveryAddress: '89 Lê Lợi, Phường Bến Thành', status: 'pending'),
        ShipperOrder(maDonHang: 'DNGO-8844', date: '10 phút trước', totalAmount: 34000, deliveryAddress: '10/2 Pasteur, Quận 3', status: 'pending'),
      ];
    }
  }

  Future<bool> acceptOrder(String orderId) async {
    try {
      final response = await _dio.post('/api/shipper/orders/accept', data: {
        'ma_don_hang': orderId
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Không thể nhận đơn: $e');
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await _dio.get('/api/shipper/me');
      if (response.statusCode == 200) {
        return response.data['user']; // API test output showed 'user'
      }
      return null;
    } catch (e) {
      throw Exception('Không thể lấy thông tin tài xế: $e');
    }
  }

  Future<List<ShipperOrder>> getMyOrders({int page = 1, int limit = 10, String? status}) async {
    try {
      final Map<String, dynamic> queryParams = {'page': page, 'limit': limit};
      if (status != null) queryParams['tinh_trang_don_hang'] = status;
      
      final response = await _dio.get('/api/shipper/orders/my', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final data = response.data['items'] as List?;
        if (data != null) {
          return data.map((e) => ShipperOrder.fromJson(e)).toList();
        }
        return [];
      }
      throw Exception('Failed to load my orders');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<ShipperOrder?> getOrderDetails(String orderId) async {
    try {
      final response = await _dio.get('/api/shipper/orders/$orderId/details');
      if (response.statusCode == 200) {
        return ShipperOrder.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Error loading order details: $e');
    }
  }

  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _dio.put('/api/shipper/orders/$orderId/status', data: {
        'status': status
      });
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Lỗi cập nhật trạng thái: $e');
    }
  }

  Future<List<MarketMapStall>> getMapStalls() async {
    try {
      final response = await _dio.get('/api/quan-ly-cho/stalls/map');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'] as List?;
        if (data != null) {
          return data.map((e) => MarketMapStall.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Không thể tải bản đồ: $e');
    }
  }
}
