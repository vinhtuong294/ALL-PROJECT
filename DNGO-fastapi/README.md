# DNGO API - Đi Chợ Online

API Backend cho hệ thống đi chợ online, xây dựng bằng FastAPI và PostgreSQL.

## Cấu trúc Project

```
dngo-api/
├── app/
│   ├── main.py              # Entry point
│   ├── config.py            # Cấu hình
│   ├── database.py          # Kết nối PostgreSQL
│   ├── models/              # SQLAlchemy models
│   ├── schemas/             # Pydantic schemas
│   ├── routers/             # API routes
│   ├── repositories/        # Database queries
│   ├── middlewares/         # Auth middleware
│   └── utils/               # Helper functions
├── requirements.txt
├── .env
└── README.md
```

## Cài đặt

### 1. Clone và cài đặt dependencies

```bash
cd dngo-api
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate

pip install -r requirements.txt
```

### 2. Cấu hình .env

Tạo file `.env` (copy từ `.env.example` hoặc hỏi team lead):

```env
DATABASE_URL=postgresql://...
JWT_SECRET=your-super-secret-key-change-this
CORS_ORIGINS=*
FIREBASE_DATABASE_URL=https://dngo-app-default-rtdb.asia-southeast1.firebasedatabase.app
```

### 3. Cấu hình Firebase (tính năng Realtime Tracking)

> ⚠️ File `serviceAccountKey.json` **KHÔNG** có trong repo vì lý do bảo mật.  
> Liên hệ **team lead** để nhận file này qua kênh riêng tư (Zalo/Discord).

Sau khi có file, đặt vào thư mục gốc:
```
DNGO-fastapi/
├── app/
├── serviceAccountKey.json   ← đặt vào đây
├── .env
└── ...
```

Hoặc tự tạo từ Firebase Console:
1. Vào [Firebase Console](https://console.firebase.google.com) → Project **dngo-app**
2. ⚙️ Project Settings → **Service accounts**
3. Bấm **Generate new private key** → Download file JSON
4. Đổi tên thành `serviceAccountKey.json` và đặt vào thư mục gốc


### 3. Chạy server

```bash
# Development
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Production
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

## API Documentation

Sau khi chạy server, truy cập:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Endpoints

### Health Check
- `GET /health` - Kiểm tra server
- `GET /db/ping` - Kiểm tra database

### Buyer API (yêu cầu JWT token)
- `GET /api/buyer/khu-vuc` - Danh sách khu vực
- `GET /api/buyer/cho` - Danh sách chợ
- `GET /api/buyer/gian-hang` - Danh sách gian hàng
- `GET /api/buyer/gian-hang/{id}` - Chi tiết gian hàng
- `GET /api/buyer/nguyen-lieu` - Danh sách nguyên liệu
- `GET /api/buyer/danh-muc-nguyen-lieu` - Danh mục nguyên liệu
- `GET /api/buyer/danh-muc-mon-an` - Danh mục món ăn
- `GET /api/buyer/mon-an` - Danh sách món ăn
- `GET /api/buyer/mon-an/{id}` - Chi tiết món ăn

## So sánh với Express.js cũ

| Express.js | FastAPI |
|------------|---------|
| `router.get()` | `@router.get()` |
| `req.validated` | Pydantic Schema |
| `req.user` | `current_user: AuthUser` |
| `next(error)` | `raise HTTPException` |
| Prisma ORM | SQLAlchemy ORM |
| Joi validation | Pydantic validation |

## Deploy lên VPS Contabo

```bash
# SSH vào VPS
ssh root@207.180.233.84

# Clone code
git clone <your-repo> /opt/dngo-api
cd /opt/dngo-api

# Cài đặt
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Chạy với systemd hoặc supervisor
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## TODO

- [ ] Auth routes (login, register, refresh token)
- [ ] Cart routes
- [ ] Order routes
- [ ] Seller routes
- [ ] Shipper routes
- [ ] Chat/Chatbot routes
- [ ] VNPay payment integration
- [ ] Route optimization với OR-Tools


# 📋 CHANGELOG — DNGO-fastapi

## [2026-04-16] — Sửa lỗi Market Map API & Route Conflict

### 🐛 Bug Fixed

#### `app/routers/market_management.py`
- **Sửa lỗi Route Ordering conflict**: Route `GET /stalls/map` bị FastAPI nhầm với route động `GET /stalls/{stall_id}/status` do đăng ký sai thứ tự.
- **Fix**: Di chuyển route `/stalls/map` lên **trước** tất cả các route có path parameter `{stall_id}`.
- **Kết quả**: Endpoint `GET /api/quan-ly-cho/stalls/map` hoạt động đúng, trả về danh sách sạp với tọa độ bản đồ.

#### `app/repositories/market_management.py`
- Xác nhận logic `get_map_stalls()` đúng — JOIN `Stall`, `User`, `Merchant` để lấy thông tin người bán.

---

### ✅ Endpoint đang hoạt động

| Method | URL | Mô tả |
|--------|-----|-------|
| `GET` | `/api/quan-ly-cho/stalls/map` | Lấy toàn bộ sạp với tọa độ lưới (xCol, yRow) |
| `GET` | `/api/shipper/orders/available` | Danh sách đơn hàng shipper có thể nhận |
| `GET` | `/api/shipper/orders/my` | Đơn hàng shipper đang giao |
| `GET` | `/api/payment/vnpay/return` | Callback thanh toán VNPay |
| `GET` | `/api/payment/vnpay/ipn` | IPN VNPay (server-to-server) |

---

### ⚠️ Lưu ý kỹ thuật

> **Quy tắc bắt buộc với FastAPI**: Luôn đặt route **cụ thể** (ví dụ: `/stalls/map`) **TRƯỚC** route **động** (ví dụ: `/stalls/{stall_id}/status`). Nếu sai thứ tự, FastAPI sẽ match `map` như một `stall_id` và trả về lỗi 404 hoặc 422.

```python
# ✅ ĐÚNG — map trước, dynamic sau
@router.get("/stalls/map")        # ← route cụ thể lên trên
def get_map_stalls(...): ...

@router.get("/stalls/{stall_id}/status")  # ← dynamic xuống dưới
def get_stall_status(...): ...
```

---

### 🔄 Luồng VNPay Payment (đã xác nhận hoạt động)

```
Người dùng bấm "Thanh toán VNPay"
    ↓ App mở URL VNPay
    ↓ Thanh toán thành công
    ↓ VNPay callback → GET /api/payment/vnpay/return
    ↓ Backend: Payment.status → da_thanh_toan
    ↓ Backend: Order.status  → da_xac_nhan   ← Order tự động nhảy!
    ↓ Backend: Trừ tồn kho inventory
```

---

### 📌 Cấu hình hiện tại (Local Dev)

```env
# Server chạy tại:
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Firebase: cần serviceAccountKey.json (không có trong repo - bỏ qua khi dev local)
# VNPay: đã cấu hình trong .env
```

---

### 📌 Known Issues

- `serviceAccountKey.json` chưa có → Firebase Realtime DB không hoạt động (không ảnh hưởng chức năng chính)
- JWT token mặc định expire sau 24h — cần đăng nhập lại khi hết hạn


