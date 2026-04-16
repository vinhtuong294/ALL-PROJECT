import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  group('Chạy Auto Test Vai Trò Shipper', () {
    final dio = Dio(BaseOptions(baseUrl: 'http://207.180.233.84:8000'));
    
    String? shipperToken;

    test('1. Tạo và Đăng nhập Shipper', () async {
      final shipperUsername = 'shipper_test_auto_002';
      final shipperPw = 'Trinh123456@';

      try {
        final regRes = await dio.post('/api/auth/register', data: {
          "ten_dang_nhap": shipperUsername,
          "password": shipperPw,
          "email": "$shipperUsername@test.com",
          "ten_nguoi_dung": "Shipper Test Auto",
          "gioi_tinh": "M",
          "sdt": "0901234567",
          "dia_chi": "123 Đường Shipper",
          "role": "shipper",
          "vai_tro": "shipper"
        });
        expect(regRes.statusCode == 200 || regRes.statusCode == 201, isTrue);
      } on DioException catch (e) {
        // Có thể user đã tồn tại, tiếp tục đăng nhập
        if (e.response?.statusCode != 400 && e.response?.statusCode != 422 && e.response?.statusCode != 409) {
          rethrow;
        }
      }

      final response = await dio.post('/api/auth/login', data: {
        'ten_dang_nhap': shipperUsername,
        'password': shipperPw
      });
      expect(response.statusCode, 200);
      shipperToken = response.data['token'];
      expect(shipperToken, isNotNull);
      print('Shipper Authenticated Successfully');
    });

    test('2. Test truy xuất Profile và List Đơn Hàng Shipper', () async {
      expect(shipperToken, isNotNull, reason: 'Chưa có token của shipper');
      
      // Get Profile
      final profileResponse = await dio.get('/api/shipper/me', options: Options(headers: {'Authorization': 'Bearer $shipperToken'}));
      expect(profileResponse.statusCode, 200);
      expect(profileResponse.data['success'], true);

      // Get Available Orders
      final availableResponse = await dio.get('/api/shipper/orders/available', options: Options(headers: {'Authorization': 'Bearer $shipperToken'}));
      expect(availableResponse.statusCode, 200);
      
      // Get My Orders
      final myOrdersResponse = await dio.get('/api/shipper/orders/my', options: Options(headers: {'Authorization': 'Bearer $shipperToken'}));
      expect(myOrdersResponse.statusCode, 200);
    });
  });
}
