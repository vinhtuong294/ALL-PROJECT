# Hướng dẫn Cập nhật API chi tiết

Tài liệu này hướng dẫn bạn cách cập nhật các API mới vào ứng dụng một cách có hệ thống, giúp dễ dàng quản lý và thay đổi trong tương lai.

## Bước 1: Cập nhật Base URL trong `AppConfig`
Thay vì để URL ở nhiều nơi, chúng ta nên định nghĩa các Base URL cho từng role trong `lib/core/config/app_config.dart`.

```dart
// lib/core/config/app_config.dart

class AppConfig {
  // ... (giữ nguyên các phần cũ)

  // 1. Định nghĩa các Base URL mới cho từng Role
  // Hãy thay các URL dưới đây bằng URL thật của bạn
  static const String buyerBaseUrl = 'https://api-new.example.com/api/buyer';
  static const String sellerBaseUrl = 'https://api-new.example.com/api/seller';
  static const String adminBaseUrl = 'https://api-new.example.com/api/market-manager';
  static const String authBaseUrl = 'https://api-new.example.com/api/auth';
  
  // URL mặc định (nếu cần)
  static const String baseUrl = buyerBaseUrl; 
}
```

---

## Bước 2: Cập nhật Endpoints trong `AppConstant`
Khai báo các đường dẫn cụ thể trong `lib/core/config/app_constant.dart` để tránh viết sai chính tả.

```dart
// lib/core/config/app_constant.dart

class AppConstant {
  // Authentication
  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String profileEndpoint = '/me';

  // Seller
  static const String sellerOrders = '/orders';
  static const String sellerProducts = '/products';

  // Buyer
  static const String buyerOrders = '/orders';
  static const String buyerCart = '/cart';
  static const String ingredients = '/nguyen-lieu';
}
```

---

## Bước 3: Cập nhật các File Service
Đây là bước quan trọng nhất. Bạn cần thay thế các URL viết cứng bằng các hằng số đã định nghĩa.

### Ví dụ 1: Cập nhật `SellerOrderService`
Tìm file `lib/core/services/seller_order_service.dart`.

**Trước khi sửa:**
```dart
static const String _baseUrl = 'https://subtle-seat-475108-v5.et.r.appspot.com/api/seller';
```

**Sau khi sửa:**
```dart
import '../config/app_config.dart';

class SellerOrderService {
  // Sử dụng AppConfig thay vì viết cứng
  static const String _baseUrl = AppConfig.sellerBaseUrl;
  
  // ... các hàm khác sẽ tự động dùng _baseUrl mới
}
```

### Ví dụ 2: Cập nhật `AuthService`
Tìm file `lib/core/services/auth/auth_service.dart`.

**Sửa lại các hàm gọi URL:**
```dart
Future<AuthResponse> login({required String username, required String password}) async {
  // Kết hợp BaseUrl và Endpoint
  final loginUrl = '${AppConfig.authBaseUrl}${AppConstant.loginEndpoint}';
  
  // ... gọi API
}
```

---

## Bước 4: Danh sách các Service cần kiểm tra
Hãy mở các file sau và tìm từ khóa `https://` hoặc `_baseUrl` để thay thế:

1.  **Chung (Auth/Profile)**:
    - `lib/core/services/auth/auth_service.dart`
    - `lib/core/services/auth/simple_auth_helper.dart`
    - `lib/core/services/user_profile_service.dart`

2.  **Seller (Người bán)**:
    - `lib/core/services/seller_order_service.dart`
    - `lib/core/services/nhom_nguyen_lieu_service.dart`

3.  **Buyer (Người mua)**:
    - `lib/core/services/order_service.dart`
    - `lib/core/services/cart_api_service.dart`
    - `lib/core/services/nguyen_lieu_service.dart`
    - `lib/core/services/category_service.dart`
    - `lib/core/services/gian_hang_service.dart`
    - `lib/core/services/mon_an_service.dart`

4.  **Market Manager (Quản lý chợ)**:
    - `lib/core/services/market_manager_service.dart`

---

## Mẹo nhỏ (Pro Tip)
Để tìm tất cả các nơi đang chứa URL cũ, bạn hãy dùng tính năng **Tìm kiếm toàn cục (Ctrl + Shift + F)** trong VS Code và gõ địa chỉ server cũ: `subtle-seat-475108-v5.et.r.appspot.com`. 

Tất cả các kết quả hiện ra chính là những nơi bạn cần cập nhật sang `AppConfig`.
