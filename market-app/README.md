# Market App - Quản Lý Chợ Bắc Mỹ An

Dự án quản lý chợ được xây dựng bằng Flutter, hỗ trợ quản lý tiểu thương, sơ đồ gian hàng và thu thuế.

## Hướng dẫn chạy dự án

### 1. Cài đặt môi trường
Đảm bảo bạn đã cài đặt Flutter SDK trên máy tính. Bạn có thể kiểm tra bằng lệnh:
```bash
flutter doctor
```

### 2. Tải các thư viện (Dependencies)
Chạy lệnh sau để tải các package cần thiết:
```bash
flutter pub get
```

### 3. Tạo mã nguồn tự động (Code Generation)
Vì dự án sử dụng `freezed`, `json_serializable` và `retrofit`, bạn cần chạy lệnh này để tạo các file `.g.dart`:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Chạy ứng dụng

#### Chạy trên trình duyệt (Web/Chrome):
```bash
flutter run -d chrome
```

#### Chạy trên thiết bị thật hoặc trình giả lập (Android/iOS):
1. Kết nối thiết bị hoặc mở Emulator/Simulator.
2. Chạy lệnh:
```bash
flutter run
```

## Các tính năng chính
- Quản lý danh sách tiểu thương.
- Sơ đồ gian hàng trực quan (có lọc theo ngành hàng).
- Thu thuế và xuất hóa đơn điện tử.
- Quản lý thông tin cá nhân và bảo mật.


# 📋 CHANGELOG — market-app (Market Manager App)

## [2026-04-16] — Sơ Đồ Chợ: Zoom Controls & UI Improvements

### ✨ Tính năng mới

#### `lib/presentation/screens/home/market_map_screen.dart`

**1. Zoom Controls (Nút +/−/⊡)**
- Thêm `TransformationController` để điều khiển zoom theo chương trình.
- Thêm 3 nút tròn góc phải dưới màn hình:
  - **+** (Phóng to): tăng scale +0.2, tối đa 3.0x
  - **−** (Thu nhỏ): giảm scale −0.2, tối thiểu 0.2x
  - **⊡** (Vừa màn hình): reset về scale 0.7 (hiển thị toàn bộ bản đồ)
- **Lý do**: Flutter Web không hỗ trợ mouse wheel zoom trên `InteractiveViewer` — phải dùng nút bấm thay thế.

**2. Bảng chú giải (Legend)**
- Thêm legend box góc trái trên với màu sắc 3 khu:
  - 🟢 Khu Rau Củ & Gia Vị
  - 🔴 Khu Thịt
  - 🔵 Khu Hải Sản
  - ● Đang mở cửa / Đóng cửa

**3. Badge số lượng sạp**
- Badge xanh góc phải trên hiển thị **"X sạp"** (số lượng thực từ DB).

**4. Cải thiện Lối Vào**
- Thêm nhãn văn bản cho 4 lối vào: **CỬA BẮC, CỬA NAM, CỬA TÂY, CỬA ĐÔNG**.

**5. Màn hình lỗi cải tiến**
- Thay text đỏ đơn thuần bằng: Icon lỗi + mô tả lỗi + nút **"Thử lại"**.

---

### 🐛 Bug Fixed

**Root cause lỗi "Endpoint not found"** (đã fix từ phiên trước):
- API `GET /api/quan-ly-cho/stalls/map` trả về `success: True` với 69 sạp thật từ DB PostgreSQL.
- Xác nhận `MarketRepository.getMapStalls()` và `api_service.g.dart` đúng endpoint.

---

### 📁 Files thay đổi

| File | Thay đổi |
|------|----------|
| `lib/presentation/screens/home/market_map_screen.dart` | Zoom controls, legend, badges, improved error UI |

---

### 🗺️ Cấu trúc Bản Đồ Chợ

```
Grid: 14 cột × 5 hàng
Data: xCol (0-11), yRow (0-2) → hiển thị offset +1 mỗi chiều

Khu vực:
- Cols 1-4: Rau Củ (màu xanh lá nhạt)
- Cols 5-8: Thịt (màu đỏ nhạt)
- Cols 9-12: Hải Sản (màu xanh dương nhạt)
- Col 0, 13: Lối đi
- Row 0, 4: Lối đi
```

---

### 📌 Ghi chú

- API dùng dữ liệu thật 100% từ DB — không phải mock data.
- Chạy bằng: `flutter run -d chrome --web-browser-flag "--disable-web-security"`
- Base URL: `http://localhost:8000` (dev) / server production khi deploy.


