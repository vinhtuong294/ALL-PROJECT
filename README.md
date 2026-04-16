# 🛒 DNGO — ALL-PROJECT

Hệ thống đi chợ trực tuyến gồm các ứng dụng và dịch vụ:

---

## 📦 Danh sách Projects

| Thư mục | Loại | Mô tả |
|---------|------|-------|
| `DNGO-fastapi/` | Backend API | FastAPI + PostgreSQL — Backend chính cho toàn bộ hệ thống |
| `market-app/` | Flutter Web | App cho **Quản lý chợ** — xem sơ đồ, quản lý gian hàng |
| `dngo_shipper_app/` | Flutter Web/Mobile | App cho **Shipper** — nhận và giao đơn hàng |
| `online_market_app/` | Flutter | App cho **Người mua** — đặt hàng trực tuyến |
| `Mapping-UI/` | Flutter Web | App bản đồ — định vị và tracking |
| `LLM/` | Python | Chatbot / AI integration |

---

## 📅 Update Log

### [2026-04-16] — Market Map, Shipper App Fixes

#### 🔧 DNGO-fastapi (Backend)
- **Fix route conflict**: Route `GET /api/quan-ly-cho/stalls/map` bị shadow bởi route động `/{stall_id}` → đã fix thứ tự đăng ký route trong FastAPI.
- **Xác nhận VNPay flow**: Sau khi thanh toán VNPay thành công, `order_status` tự động chuyển sang `da_xac_nhan`.
- **69 đơn hàng** sẵn sàng cho shipper nhận (status `da_xac_nhan` / `dang_giao`).
- 👉 Xem chi tiết: [`DNGO-fastapi/CHANGELOG.md`](./DNGO-fastapi/CHANGELOG.md)

#### 🗺️ market-app (Market Manager App)
- **Zoom controls**: Thêm nút +/−/⊡ cho Sơ Đồ Chợ (Flutter Web không hỗ trợ mouse wheel zoom).
- **Legend box**: Bảng chú giải 3 khu (Rau, Thịt, Hải Sản) + trạng thái sạp.
- **Badge số sạp**: Hiển thị tổng số sạp đang hoạt động.
- **Cải thiện lối vào**: Nhãn CỬA BẮC/NAM/TÂY/ĐÔNG.
- API trả về dữ liệu thật 100% từ PostgreSQL.
- 👉 Xem chi tiết: [`market-app/CHANGELOG.md`](./market-app/CHANGELOG.md)

#### 🚚 dngo_shipper_app (Shipper App)
- **Fix màn trắng**: Skip `Firebase.initializeApp()` khi chạy trên Web.
- **Fix 0 đơn hàng**: `coreBaseUrl` sai → đổi về `localhost:8000`.
- **Fix loading stuck**: Thêm `UnauthorizedException` + timeout 12s.
- **Auto-logout**: Khi token hết hạn (401) → tự động về màn hình Login.
- **Auto-polling đơn mới**: Polling 10 giây, badge nhấp nháy, snackbar thông báo.
- 👉 Xem chi tiết: [`dngo_shipper_app/CHANGELOG.md`](./dngo_shipper_app/CHANGELOG.md)

---

## 🚀 Chạy local

### Backend API
```bash
cd DNGO-fastapi
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
> API Docs: http://localhost:8000/docs

### Market Manager App
```bash
cd market-app
flutter pub get
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

### Shipper App
```bash
cd dngo_shipper_app
flutter pub get
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

### Mapping UI
```bash
cd Mapping-UI
flutter pub get
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

---

## 🔐 Accounts & Credentials

Xem file [`ACCOUNTS.md`](./ACCOUNTS.md) để biết tài khoản test cho từng role (buyer, shipper, market manager).

---

## 🗄️ Database

- **Engine**: PostgreSQL
- **Local**: `postgresql://localhost:5432/dngo_db`
- **Production**: VPS Contabo `207.180.233.84`
- **ORM**: SQLAlchemy

---

## ⚠️ Lưu ý quan trọng khi deploy Production

1. Đổi `baseUrl` và `coreBaseUrl` trong Flutter apps từ `localhost` → `207.180.233.84:8000`
2. Thêm `serviceAccountKey.json` vào `DNGO-fastapi/` (lấy từ Firebase Console)
3. Kiểm tra `.env` có đủ `VNP_*` keys cho VNPay
4. Tắt `--disable-web-security` flag khi build production

---

## 🏗️ Kiến trúc hệ thống

```
┌─────────────────────────────────────────────────────┐
│                    DNGO Platform                     │
├──────────────┬──────────────┬───────────────────────┤
│  Người Mua   │   Shipper    │    Quản Lý Chợ        │
│  online_     │  dngo_       │  market-app           │
│  market_app  │  shipper_app │  (Flutter Web)        │
└──────┬───────┴──────┬───────┴──────────┬────────────┘
       │              │                  │
       └──────────────▼──────────────────┘
                      │
         ┌────────────▼────────────┐
         │      DNGO-fastapi       │
         │  FastAPI + PostgreSQL   │
         │  + VNPay + Firebase     │
         └─────────────────────────┘
```
