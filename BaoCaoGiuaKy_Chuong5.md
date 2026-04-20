# CHƯƠNG 5: TRIỂN KHAI ỨNG DỤNG VÀ CÁC CHỨC NĂNG CHÍNH

---

## MỤC LỤC CHƯƠNG 5

- [5.1 Kiến trúc tổng thể ứng dụng Flutter](#51-kiến-trúc-tổng-thể-ứng-dụng-flutter)
- [5.2 Triển khai Frontend – Ứng dụng Người mua và Người bán (Done-demo)](#52-triển-khai-frontend--ứng-dụng-người-mua-và-người-bán-done-demo)
- [5.3 Triển khai Frontend – Ứng dụng Shipper (dngo_shipper_app)](#53-triển-khai-frontend--ứng-dụng-shipper-dngo_shipper_app)
- [5.4 Triển khai Backend API – FastAPI](#54-triển-khai-backend-api--fastapi)
- [5.5 Hệ thống Ví điện tử – Chi tiết triển khai](#55-hệ-thống-ví-điện-tử--chi-tiết-triển-khai)
- [5.6 Hệ thống định tuyến Shipper – OSRM Integration](#56-hệ-thống-định-tuyến-shipper--osrm-integration)

---

## 5.1 Kiến trúc tổng thể ứng dụng Flutter

### 5.1.1 Feature-First Architecture

Hệ thống Frontend sử dụng **Feature-First Architecture** – tổ chức code theo tính năng thay vì theo loại file. Mỗi feature là một thư mục độc lập, đóng gói toàn bộ UI, Logic và Data liên quan:

```
Done-demo/lib/
├── core/
│   ├── constants/         # App constants (colors, strings, API URLs)
│   ├── di/                # Dependency Injection setup
│   ├── errors/            # Custom error classes
│   ├── network/           # HTTP client, API base class
│   └── utils/             # Shared utilities, formatters
│
├── feature/
│   ├── auth/              # Đăng nhập / Đăng ký
│   │   ├── data/          # AuthRepository, AuthRemoteDataSource
│   │   ├── domain/        # User entity, LoginUseCase, SignupUseCase
│   │   └── presentation/  # LoginPage, SignupPage, AuthBloc/Cubit
│   │
│   ├── home/              # Trang chủ
│   ├── products/          # Danh sách sản phẩm, Chi tiết sản phẩm
│   ├── cart/              # Giỏ hàng đa sạp
│   ├── order/             # Đặt hàng, Theo dõi đơn
│   ├── wallet/            # Ví điện tử, Lịch sử giao dịch, Nạp tiền
│   ├── ai_chat/           # Chat AI gợi ý thực đơn
│   ├── seller/            # Quản lý gian hàng Seller
│   │   ├── products/      # Quản lý sản phẩm
│   │   ├── orders/        # Nhận đơn, xác nhận đơn
│   │   └── revenue/       # Thống kê doanh thu
│   └── admin/             # Quản lý chợ (Market Manager)
│       └── seller/        # Duyệt hồ sơ tiểu thương
│
└── main.dart
```

### 5.1.2 BLoC Pattern – Luồng dữ liệu

Mỗi feature sử dụng BLoC (hoặc Cubit – simplified BLoC) để quản lý trạng thái:

**Ví dụ – WalletBloc:**
```
Events:                         States:
- LoadWalletEvent          →    WalletLoadingState
- DepositRequestEvent      →    WalletLoadedState(wallet, transactions)
- WithdrawRequestEvent     →    WalletErrorState(message)
- RefreshTransactionEvent  →    WalletUpdatedState
```

**Cấu trúc code WalletBloc:**
```dart
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository _walletRepository;

  WalletBloc({required WalletRepository walletRepository})
      : _walletRepository = walletRepository, super(WalletInitialState()) {
    on<LoadWalletEvent>(_onLoadWallet);
    on<DepositRequestEvent>(_onDepositRequest);
  }

  Future<void> _onLoadWallet(LoadWalletEvent event, Emitter<WalletState> emit) async {
    emit(WalletLoadingState());
    try {
      final wallet = await _walletRepository.getMyWallet();
      final transactions = await _walletRepository.getTransactionHistory();
      emit(WalletLoadedState(wallet: wallet, transactions: transactions));
    } catch (e) {
      emit(WalletErrorState(message: e.toString()));
    }
  }
}
```

---

## 5.2 Triển khai Frontend – Ứng dụng Người mua và Người bán (Done-demo)

### 5.2.1 Luồng đăng nhập và phân quyền vai trò

Sau khi Người dùng đăng nhập, hệ thống nhận JWT Token có chứa `role` trong Payload. Dựa vào Role, App tự động điều hướng người dùng đến màn hình phù hợp:

```dart
// AuthBloc xử lý sau khi đăng nhập thành công
void _handleLoginSuccess(LoginResponse response) {
  final role = response.user.role;
  switch (role) {
    case UserRole.buyer:
      router.go('/home'); // Màn hình chủ Buyer
      break;
    case UserRole.seller:
      if (response.user.stallStatus == StallStatus.approved) {
        router.go('/seller/dashboard'); // Màn hình quản lý gian hàng
      } else {
        router.go('/seller/register-stall'); // Đăng ký gian hàng
      }
      break;
    case UserRole.marketManager:
      router.go('/admin/dashboard'); // Dashboard quản lý chợ
      break;
  }
}
```

### 5.2.2 Màn hình Giỏ hàng đa sạp (Multi-stall Cart)

Đây là tính năng kỹ thuật phức tạp nhất ở phía Frontend. Giỏ hàng cần nhóm sản phẩm theo Sạp để hiển thị rõ ràng và để Backend biết phân chia đơn thế nào:

**Mô hình dữ liệu Cart:**
```dart
class CartState {
  final Map<String, List<CartItem>> itemsByStall;
  // Key: stall_id, Value: danh sách sản phẩm của sạp đó
  
  double get totalAmount {
    return itemsByStall.values
        .expand((items) => items)
        .fold(0, (sum, item) => sum + item.subtotal);
  }
  
  int get totalStalls => itemsByStall.length;
}
```

**Giao diện Giỏ hàng:**
- Hiển thị danh sách có Header phân tách theo từng Sạp.
- Mỗi nhóm Sạp có: Tên sạp, ảnh thumbnail, nhóm sản phẩm thuộc sạp đó với nút tăng/giảm số lượng.
- Cuối trang: Tổng tiền hàng + phí ship ước tính → Nút "Đặt hàng".

### 5.2.3 Màn hình Thanh toán và chọn phương thức

```
┌─────────────────────────────────┐
│ 🛒 Xác nhận đặt hàng           │
├─────────────────────────────────┤
│ 📍 Địa chỉ giao:               │
│ 132 Nguyễn Chí Thanh, Q.NHSơn  │
│                    [Đổi địa chỉ]│
├─────────────────────────────────┤
│ 📦 Từ Sạp Cô Hoa (Khu A)      │
│   • Thịt heo ba chỉ    300g    │
│                       45.000đ  │
├─────────────────────────────────┤
│ 📦 Từ Sạp Rau Xanh (Khu B)    │
│   • Cà chua            500g    │
│                       15.000đ  │
│   • Rau cải            1 bó    │
│                        8.000đ  │
├─────────────────────────────────┤
│ 💳 Phương thức thanh toán:     │
│   ● Ví DNGo (Số dư: 250.000đ) │
│   ○ Tiền mặt khi nhận (COD)   │
├─────────────────────────────────┤
│ Tổng tiền hàng:      68.000đ  │
│ Phí vận chuyển:      15.000đ  │
│                      ────────  │
│ Tổng cộng:           83.000đ  │
│                                │
│    [   XÁC NHẬN ĐẶT HÀNG   ]  │
└─────────────────────────────────┘
```

### 5.2.4 Màn hình Ví điện tử Người mua

```
┌─────────────────────────────────┐
│ 💳 Ví DNGo của tôi             │
├─────────────────────────────────┤
│                                 │
│   Số dư khả dụng               │
│   ┌─────────────────────────┐   │
│   │    250,000 đ            │   │
│   └─────────────────────────┘   │
│   Đang tạm giữ: 83,000 đ       │
│                                 │
│   [  Nạp tiền  ]  [ Lịch sử ]  │
├─────────────────────────────────┤
│ 📋 Giao dịch gần đây           │
│                                 │
│ ✅ Nạp tiền          +300,000đ │
│    20/04/2026 - 09:15          │
│                                 │
│ 🛒 Thanh toán ĐH #001  -83,000đ│
│    20/04/2026 - 14:22  (Đang TG)│
│                                 │
│ ✅ Nạp tiền          +100,000đ │
│    18/04/2026 - 16:40          │
└─────────────────────────────────┘
```

### 5.2.5 Màn hình Quản lý gian hàng (Seller Dashboard)

Sau khi được Quản lý chợ phê duyệt hồ sơ, Seller có thể truy cập màn hình quản lý gian hàng:

- **Trang chủ Seller:** Thống kê tổng quan (tổng đơn hôm nay, doanh thu tuần, sản phẩm bán chạy).
- **Quản lý sản phẩm:** Danh sách sản phẩm với ảnh, giá, tồn kho. Nút "+" để thêm sản phẩm mới.
- **Đơn hàng chờ xử lý:** Danh sách đơn cần xác nhận, hiển thị nổi bật với badge thông báo số lượng.
- **Ví tiểu thương:** Tương tự Ví Buyer nhưng có thêm nút "Yêu cầu rút tiền".

---

## 5.3 Triển khai Frontend – Ứng dụng Shipper (dngo_shipper_app)

### 5.3.1 Cấu trúc riêng biệt

`dngo_shipper_app` là một **dự án Flutter độc lập** (không phải module trong Done-demo). Lý do:
- Giao diện Shipper tối giản, tập trung vào chức năng giao hàng.
- Không cần nhiều feature phức tạp như cart, AI chat.
- Có thể deploy và update độc lập mà không ảnh hưởng App chính.

### 5.3.2 Màn hình Home – Danh sách chuyến giao

```
┌─────────────────────────────────┐
│ 🛵 DNGO Shipper               │
│ Xin chào, Minh Tuấn!          │
├─────────────────────────────────┤
│ ⬤ Trực tuyến  [Toggle OFF]    │
├─────────────────────────────────┤
│ 📦 Chuyến hàng chờ bạn nhận:  │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ ĐH #2025-001                │ │
│ │ 📍 Giao đến: 45 Lê Duẩn    │ │
│ │ 🏪 Lấy tại: 2 sạp          │ │
│ │ 💰 Phí ship: 15,000đ        │ │
│ │ 🕐 Đặt lúc: 14:22          │ │
│ │          [NHẬN CHUYẾN HÀng] │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ ĐH #2025-002                │ │
│ │ ...                         │ │
│ └─────────────────────────────┘ │
├─────────────────────────────────┤
│ 💰 Thu nhập hôm nay: 85,000đ  │
└─────────────────────────────────┘
```

### 5.3.3 Màn hình bản đồ định tuyến OSRM

Sau khi nhận chuyến, App hiển thị bản đồ với:
- **Vị trí hiện tại** của Shipper (GPS) – đánh dấu màu xanh.
- **Các Pickup Points** (vị trí từng sạp cần lấy hàng) – đánh dấu màu cam với số thứ tự ưu tiên.
- **Delivery Point** (địa chỉ khách) – đánh dấu màu đỏ.
- **Tuyến đường tối ưu** – vạch đường màu tím do OSRM tính toán.

```dart
// Gọi OSRM API để tối ưu lộ trình
Future<RouteResult> optimizeRoute({
  required LatLng shipperLocation,
  required List<LatLng> pickupPoints,
  required LatLng deliveryPoint,
}) async {
  final waypoints = [
    shipperLocation,
    ...pickupPoints,
    deliveryPoint,
  ];
  
  final coordinatesStr = waypoints
      .map((p) => "${p.longitude},${p.latitude}")
      .join(";");
  
  final response = await dio.get(
    "http://router.project-osrm.org/trip/v1/driving/$coordinatesStr",
    queryParameters: {
      'source': 'first',
      'destination': 'last',
      'roundtrip': 'false',
      'geometries': 'geojson',
      'annotations': 'duration,distance',
    }
  );
  
  return RouteResult.fromJson(response.data);
}
```

### 5.3.4 Màn hình Xác nhận giao hàng

```
┌─────────────────────────────────┐
│ 📦 Đơn hàng #2025-001          │
│ 🟡 Đang giao đến khách         │
├─────────────────────────────────┤
│ 📍 Điểm đang giao:             │
│ 45 Lê Duẩn, Q.Hải Châu        │
│                                 │
│ 👤 Khách: Linh Nguyễn          │
│ 📱 0905.123.456 [GỌI]         │
├─────────────────────────────────┤
│ 📸 Upload ảnh bằng chứng:     │
│ ┌─────────────────────────────┐ │
│ │           +                 │ │
│ │   Chụp ảnh xác nhận         │ │
│ └─────────────────────────────┘ │
│                                 │
│ [ ✅ XÁC NHẬN ĐÃ GIAO THÀNH CÔNG]│
│ [ ❌ Báo khó khăn khi giao    ]│
└─────────────────────────────────┘
```

Khi Shipper bấm "Xác nhận giao thành công", hệ thống:
1. Upload ảnh lên server lưu vào OrderDetails.proof_image_url.
2. Gọi API `PATCH /orders/{id}/status` với body `{status: "DELIVERED"}`.
3. Backend tự động kích hoạt Wallet Release Transaction.
4. Push notification đến Buyer và Seller.

---

## 5.4 Triển khai Backend API – FastAPI

### 5.4.1 Cấu trúc thư mục Backend

```
LLM-master/
├── app/
│   ├── main.py                 # Khởi tạo FastAPI app, mount routers
│   ├── config.py               # Cấu hình từ .env (DB URL, JWT secret...)
│   ├── database.py             # SQLAlchemy engine, session factory
│   │
│   ├── models/                 # SQLAlchemy ORM models
│   │   ├── user.py             # User model
│   │   ├── wallet.py           # Wallet + Transaction models
│   │   ├── stall.py            # Stall + StallRegistration models
│   │   ├── product.py          # Product model
│   │   ├── order.py            # Order + OrderItem models
│   │   └── market.py           # Market model
│   │
│   ├── schemas/                # Pydantic schemas (Request/Response DTOs)
│   │   ├── user.py
│   │   ├── wallet.py
│   │   ├── order.py
│   │   └── ...
│   │
│   ├── routers/                # Phân nhóm API theo chức năng
│   │   ├── auth.py             # /api/auth/* (login, register, refresh)
│   │   ├── users.py            # /api/users/*
│   │   ├── products.py         # /api/products/*
│   │   ├── orders.py           # /api/orders/*
│   │   ├── wallet.py           # /api/wallet/*
│   │   ├── ai.py               # /api/ai/chat
│   │   └── market.py           # /api/quan-ly-cho/*
│   │
│   ├── services/               # Business Logic (tách khỏi router)
│   │   ├── wallet_service.py   # Reserve/Release/Refund logic
│   │   ├── order_service.py    # Tạo đơn, phân công shipper
│   │   ├── ai_service.py       # RAG pipeline, LLM call
│   │   └── osrm_service.py     # Gọi OSRM API định tuyến
│   │
│   └── utils/
│       ├── auth.py             # JWT helpers
│       ├── time_rules.py       # Kiểm tra giờ chợ hoạt động
│       └── notifications.py    # FCM push notification
│
├── alembic/                    # Database migrations
├── requirements.txt
└── .env
```

### 5.4.2 Danh sách API Endpoints chính

**Bảng 5.4.2: Danh sách các API Endpoints chính của hệ thống**

| Method | Endpoint | Role | Mô tả |
|--------|---------|------|-------|
| POST | `/api/auth/register` | Public | Đăng ký tài khoản mới |
| POST | `/api/auth/login` | Public | Đăng nhập, nhận JWT Token |
| GET | `/api/users/me` | All auth | Xem thông tin cá nhân |
| PATCH | `/api/users/me` | All auth | Cập nhật thông tin cá nhân |
| GET | `/api/products/` | Public | Lấy danh sách sản phẩm (có filter) |
| GET | `/api/products/{id}` | Public | Chi tiết sản phẩm |
| POST | `/api/products/` | Seller | Thêm sản phẩm mới |
| PUT | `/api/products/{id}` | Seller | Cập nhật sản phẩm |
| DELETE | `/api/products/{id}` | Seller | Xóa (soft delete) sản phẩm |
| POST | `/api/orders/` | Buyer | Tạo đơn hàng mới |
| GET | `/api/orders/` | Buyer/Seller/Shipper | Danh sách đơn hàng (theo role) |
| GET | `/api/orders/{id}` | All auth | Chi tiết đơn hàng |
| PATCH | `/api/orders/{id}/status` | Seller/Shipper | Cập nhật trạng thái đơn |
| GET | `/api/wallet/me` | Buyer/Seller/Shipper | Xem thông tin Ví |
| GET | `/api/wallet/me/transactions` | Buyer/Seller/Shipper | Lịch sử giao dịch |
| POST | `/api/wallet/deposit-request` | Buyer | Yêu cầu nạp tiền |
| POST | `/api/wallet/withdraw-request` | Seller/Shipper | Yêu cầu rút tiền |
| POST | `/api/ai/chat` | Buyer | AI gợi ý thực đơn |
| GET | `/api/quan-ly-cho/pending-sellers` | Market Manager | Danh sách Seller chờ duyệt |
| POST | `/api/quan-ly-cho/approve-seller/{id}` | Market Manager | Phê duyệt hồ sơ Seller |
| POST | `/api/quan-ly-cho/reject-seller/{id}` | Market Manager | Từ chối hồ sơ Seller |
| GET | `/api/markets/` | Public | Danh sách chợ |
| GET | `/api/markets/{id}` | Public | Chi tiết chợ |

### 5.4.3 Kiểm soát giờ hoạt động chợ

Rule nghiệp vụ quan trọng: Không nhận đơn sau 19:00 – được triển khai như một Dependency trong FastAPI:

```python
from datetime import datetime, time
from fastapi import HTTPException

def check_market_hours():
    """Dependency – kiểm tra giờ đặt hàng hợp lệ"""
    now = datetime.now().time()
    market_close = time(19, 0, 0)  # 19:00:00
    market_open = time(6, 0, 0)    # 06:00:00
    
    if now >= market_close or now < market_open:
        raise HTTPException(
            status_code=400,
            detail={
                "code": "MARKET_CLOSED",
                "message": "Chợ đã đóng cửa. Vui lòng đặt hàng từ 6:00 đến 19:00.",
                "open_time": "06:00",
                "close_time": "19:00"
            }
        )

@router.post("/orders/", dependencies=[Depends(check_market_hours)])
async def create_order(order_data: CreateOrderSchema, ...):
    # Chỉ chạy khi giờ hợp lệ
    ...
```

---

## 5.5 Hệ thống Ví điện tử – Chi tiết triển khai

### 5.5.1 Atomic Transaction cho Wallet Operations

Điều quan trọng nhất của hệ thống Ví là đảm bảo **tính nguyên tử (Atomicity)** – mỗi thao tác ví phải thành công hoàn toàn hoặc thất bại hoàn toàn, không được có trạng thái giữa chừng (ví dụ: tiền đã bị trừ khỏi Buyer nhưng chưa cộng vào Seller).

```python
from sqlalchemy.orm import Session
from sqlalchemy import select, update
from contextlib import asynccontextmanager

class WalletService:
    
    async def reserve_payment(self, db: Session, buyer_wallet_id: str, amount: float, order_id: str):
        """Tạm giữ tiền khi Buyer đặt hàng"""
        async with db.begin():  # Bắt đầu DB Transaction
            # 1. Lock Wallet record to prevent race conditions
            wallet = await db.execute(
                select(Wallet)
                .where(Wallet.id == buyer_wallet_id)
                .with_for_update()  # Row-level lock
            )
            wallet = wallet.scalar_one()
            
            # 2. Kiểm tra số dư đủ không
            if wallet.available_balance < amount:
                raise InsufficientBalanceException(
                    available=wallet.available_balance,
                    required=amount
                )
            
            # 3. Trừ available, cộng reserved
            wallet.available_balance -= amount
            wallet.reserved_balance += amount
            
            # 4. Ghi lịch sử giao dịch
            transaction = Transaction(
                wallet_id=buyer_wallet_id,
                amount=amount,
                transaction_type=TransactionType.RESERVE,
                reference_id=order_id,
                description=f"Tạm giữ cho đơn hàng #{order_id}"
            )
            db.add(transaction)
            
            # 5. Commit – nếu có lỗi ở bước nào, toàn bộ Rollback tự động
        # Transaction kết thúc – Commit thành công
    
    async def release_to_sellers(self, db: Session, order_id: str):
        """Phân chia tiền cho Sellers sau khi giao hàng xong"""
        async with db.begin():
            order = await db.get(Order, order_id)
            order_items = await db.execute(
                select(OrderItem).where(OrderItem.order_id == order_id)
            )
            
            # Nhóm OrderItems theo Stall
            items_by_stall = {}
            for item in order_items.scalars():
                if item.stall_id not in items_by_stall:
                    items_by_stall[item.stall_id] = 0
                items_by_stall[item.stall_id] += item.subtotal
            
            # Trừ reserved của Buyer
            buyer_wallet = await db.execute(
                select(Wallet).where(Wallet.user_id == order.buyer_id).with_for_update()
            )
            buyer_wallet = buyer_wallet.scalar_one()
            buyer_wallet.reserved_balance -= order.total_amount
            
            # Cộng tiền vào ví từng Seller
            for stall_id, subtotal in items_by_stall.items():
                stall = await db.get(Stall, stall_id)
                seller_wallet = await db.execute(
                    select(Wallet).where(Wallet.id == stall.wallet_id).with_for_update()
                )
                seller_wallet = seller_wallet.scalar_one()
                seller_wallet.available_balance += subtotal
                
                db.add(Transaction(
                    wallet_id=stall.wallet_id,
                    amount=subtotal,
                    transaction_type=TransactionType.RECEIVE,
                    reference_id=order_id,
                    description=f"Nhận tiền đơn #{order_id}"
                ))
            
            # Cộng phí ship cho Shipper
            if order.shipper_id:
                shipper_wallet = await db.execute(
                    select(Wallet).where(Wallet.user_id == order.shipper_id).with_for_update()
                )
                shipper_wallet = shipper_wallet.scalar_one()
                shipper_wallet.available_balance += order.shipping_fee
```

---

## 5.6 Hệ thống định tuyến Shipper – OSRM Integration

### 5.6.1 Quy trình tạo lộ trình

```python
class OsrmService:
    OSRM_BASE_URL = "http://router.project-osrm.org"  # hoặc self-hosted
    
    async def get_optimized_trip(
        self,
        shipper_location: Coordinates,
        pickup_points: List[Coordinates],  # Vị trí các sạp
        delivery_point: Coordinates       # Nhà khách
    ) -> TripResult:
        """
        Gọi OSRM /trip endpoint để tối ưu lộ trình.
        source=first: Xuất phát từ vị trí Shipper.
        destination=last: Kết thúc tại nhà khách.
        """
        all_points = [shipper_location] + pickup_points + [delivery_point]
        coordinates = ";".join([f"{p.lng},{p.lat}" for p in all_points])
        
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.OSRM_BASE_URL}/trip/v1/driving/{coordinates}",
                params={
                    "source": "first",
                    "destination": "last",
                    "roundtrip": "false",
                    "geometries": "geojson",
                    "annotations": "duration,distance"
                }
            )
        
        data = response.json()
        return TripResult(
            waypoints=data["waypoints"],
            total_duration=sum([leg["duration"] for leg in data["trips"][0]["legs"]]),
            total_distance=sum([leg["distance"] for leg in data["trips"][0]["legs"]]),
            geometry=data["trips"][0]["geometry"]  # GeoJSON LineString
        )
```

**Kết quả trả về từ OSRM:**

| Thông tin | Ví dụ giá trị |
|----------|--------------|
| Tổng thời gian dự kiến | 12 phút 30 giây |
| Tổng khoảng cách | 3.2 km |
| Thứ tự điểm dừng tối ưu | Shipper → Sạp B (Thịt) → Sạp A (Rau) → Nhà khách |
| LineString GeoJSON | Dữ liệu để vẽ đường trên bản đồ Flutter |

---

*[Hết Chương 5 – Tiếp theo: Chương 6: Kiểm thử và Đánh giá]*
