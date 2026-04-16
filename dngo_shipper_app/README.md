# dngo_shipper_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


# 📋 CHANGELOG — dngo_shipper_app

## [2026-04-16] — Firebase Fix, Auto-polling Đơn Hàng, Auth 401 Handling

---

### 🐛 Bug Fixed

#### 1. Màn hình trắng khi chạy trên Chrome (Firebase crash)

**File**: `lib/main.dart`

**Nguyên nhân**: `Firebase.initializeApp()` được gọi không có `FirebaseOptions` → trên Web, Firebase bắt buộc cần options → app crash → màn trắng.

**Fix**:
```dart
// CHỈ khởi tạo Firebase trên Mobile (Android/iOS)
if (!kIsWeb) {
  await Firebase.initializeApp();
}
```
- Import thêm `package:flutter/foundation.dart` để dùng `kIsWeb`.
- Shipper app thực ra không dùng Firebase để auth — chỉ dùng REST API → bỏ Firebase init trên Web là an toàn.

---

#### 2. Không thấy đơn hàng nào (sai API URL)

**File**: `lib/core/services/api_service.dart`

**Nguyên nhân**: `getAvailableOrders` và `getMyOrders` dùng `coreBaseUrl = http://207.180.233.84:8000` (production server) trong khi đơn hàng đang ở **localhost**.

**Fix**:
```dart
// Trước: production server
static const String coreBaseUrl = 'http://207.180.233.84:8000';

// Sau: local dev
static const String coreBaseUrl = 'http://localhost:8000';
```

> ⚠️ **Nhớ đổi lại khi deploy production**: `'http://207.180.233.84:8000'`

---

#### 3. Loading mãi không tắt (token hết hạn)

**File**: `lib/core/services/api_service.dart` & `lib/feature/shipper/presentation/pages/tabs/orders_tab.dart`

**Nguyên nhân**: API trả `401 Not authenticated` khi token hết hạn → exception bị catch và swallow → `_loadingAvail` không bao giờ về `false` → spinner quay vĩnh viễn.

**Fix: Thêm `UnauthorizedException` class**:
```dart
class UnauthorizedException implements Exception {
  const UnauthorizedException();
}
```

**Fix: Detect 401/403 trong mọi API call**:
```dart
if (res.statusCode == 401 || res.statusCode == 403) {
  throw const UnauthorizedException();
}
```

**Fix: Timeout 12 giây**:
```dart
final res = await http.get(uri, headers: await _headers()).timeout(_timeout);
```

**Fix: Auto-logout khi token hết hạn**:
- Khi gặp `UnauthorizedException`, tự động:
  1. Xóa token khỏi `SharedPreferences`
  2. Hiện snackbar đỏ "Phiên đăng nhập hết hạn"
  3. Navigate về `LoginScreen` (xóa toàn bộ stack)

---

### ✨ Tính năng mới

#### Auto-polling Đơn Hàng (Nhảy Đơn Realtime)

**File**: `lib/feature/shipper/presentation/pages/tabs/orders_tab.dart`

**Cách hoạt động**:
- `Timer.periodic(10 giây)` → gọi `_pollNewOrders()` trong nền
- So sánh danh sách order IDs hiện tại vs lần trước
- Nếu có ID mới → hiện thông báo

**UI thông báo đơn mới**:
1. **Badge nhấp nháy** (pulse animation) góc trái header: `"⚡ X đơn mới!"`
2. **Snackbar banner** xanh lá to: `"🔔 Có đơn mới! Nhấn để xem ngay →"`
   - Nhấn vào → tự chuyển tab "Có sẵn" + ẩn badge

**Tính năng bổ sung**:
- Polling dừng tự động khi token hết hạn
- Silent fail khi mất mạng (không show lỗi)
- Ấn nút Refresh thủ công → xóa badge, reset baseline

---

### 📁 Files thay đổi

| File | Thay đổi |
|------|----------|
| `lib/main.dart` | Skip Firebase.initializeApp() trên Web |
| `lib/core/services/api_service.dart` | Fix coreBaseUrl, thêm UnauthorizedException, timeout 12s |
| `lib/feature/shipper/presentation/pages/tabs/orders_tab.dart` | Auto-polling 10s, badge nhấp nháy, auto-logout khi 401 |

---

### 📌 Tài khoản Shipper (Test)

Xem file `ACCOUNTS.md` ở thư mục gốc.

---

### 📌 Ghi chú chạy local

```bash
cd dngo_shipper_app
flutter run -d chrome --web-browser-flag "--disable-web-security"
```
- Cần `--disable-web-security` vì CORS khi gọi localhost từ Chrome.
- Nếu gặp màn trắng: kiểm tra terminal, thường do Firebase config.


