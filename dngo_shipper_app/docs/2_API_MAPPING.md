# 🔗 2. API MAPPING (Yêu cầu Ghép Data API - Đã tự động Sync)
*File này tôi (Gemini) đã tự động trích xuất từ tài liệu Swagger FastAPI Backend của bạn.*

## A. Cấu hình Core Platform
- **Base URL:** `http://207.180.233.84:8000`
- **Authentication:** Header chứa `Authorization: Bearer <token>`

## B. Collection API Shipper (FastAPI Đã Mở)

### 1. Profile Tài xế (Me)
- **Method:** `GET /api/shipper/me`
- **Nhiệm vụ:** Lấy thông tin, tên tuổi, biến số xe của shipper đang đăng nhập.

### 2. Danh sách Đơn Mới (Order Pool)
- **Method:** `GET /api/shipper/orders/available`
- **Params:** `page`, `limit`, `tinh_trang_don_hang`

### 3. Danh sách Đơn Của Tôi (My Orders - Đang giao)
- **Method:** `GET /api/shipper/orders/my`
- **Params:** `page`, `limit`, `tinh_trang_don_hang`

### 4. Chi tiết một Đơn Hàng (Order Details & Routing)
- **Method:** `GET /api/shipper/orders/{ma_don_hang}/details`

### 5. Giành / Nhận Cuốc (Accept Order)
- **Method:** `POST /api/shipper/orders/accept`
- **Body (JSON):**  
```json
{
  "ma_don_hang": "string"
}
```

### 6. Cập nhật trạng thái Giao (Đã tới / Đang ship / Done)
- **Method:** `PATCH /api/shipper/orders/{ma_don_hang}/status`
- **Body (JSON):**
```json
{
  "tinh_trang_don_hang": "string"
}
```
