# CHƯƠNG 6: KIỂM THỬ VÀ ĐÁNH GIÁ HỆ THỐNG

---

## MỤC LỤC CHƯƠNG 6

- [6.1 Phương pháp kiểm thử](#61-phương-pháp-kiểm-thử)
- [6.2 Kịch bản kiểm thử (Test Cases)](#62-kịch-bản-kiểm-thử-test-cases)
- [6.3 Kết quả kiểm thử các luồng nghiệp vụ chính](#63-kết-quả-kiểm-thử-các-luồng-nghiệp-vụ-chính)
- [6.4 Kiểm thử hiệu năng hệ thống](#64-kiểm-thử-hiệu-năng-hệ-thống)
- [6.5 Đánh giá tổng thể](#65-đánh-giá-tổng-thể)

---

## 6.1 Phương pháp kiểm thử

Nhóm áp dụng hai phương pháp kiểm thử chính trong quá trình phát triển:

### 6.1.1 Kiểm thử đơn vị (Unit Testing)
- **Backend:** Kiểm thử từng function/service độc lập bằng `pytest`. Ưu tiên kiểm thử các logic nhạy cảm: tính toán Ví điện tử, kiểm tra giờ chợ, phân chia tiền cho Seller.
- **Frontend:** Kiểm thử Widget với `flutter_test` package và kiểm thử BLoC với `bloc_test`.

### 6.1.2 Kiểm thử tích hợp (Integration Testing)
Kiểm thử các luồng nghiệp vụ đầu cuối (End-to-End) sử dụng Postman Collection cho Backend API và thao tác thực tế trên thiết bị Android thật (Samsung Galaxy A52s - Android 13) cho Frontend.

---

## 6.2 Kịch bản kiểm thử (Test Cases)

### 6.2.1 Test Cases – Luồng Ví điện tử

**Bảng 6.2.1: Test Cases cho module Ví điện tử**

| Mã TC | Mô tả kịch bản | Điều kiện đầu vào | Kết quả mong đợi | Kết quả thực tế | Trạng thái |
|-------|---------------|-----------------|-----------------|----------------|-----------|
| TC-WL-01 | Đặt hàng khi số dư Ví ĐỦ | available_balance = 200,000đ; total_order = 83,000đ; payment = WALLET | Order tạo thành công; available_balance → 117,000đ; reserved_balance → 83,000đ; Transaction RESERVE ghi vào DB | Đúng như mong đợi | ✅ PASS |
| TC-WL-02 | Đặt hàng khi số dư ví KHÔNG ĐỦ | available_balance = 50,000đ; total_order = 83,000đ; payment = WALLET | HTTP 400; thông báo "Số dư không đủ, cần thêm 33,000đ"; Ví không thay đổi | Đúng như mong đợi | ✅ PASS |
| TC-WL-03 | Giao hàng thành công → Release tiền | Đơn đặt 83,000đ (Sạp A: 45,000đ, Sạp B: 23,000đ, phí ship: 15,000đ); Shipper bấm "Xác nhận giao thành công" | Buyer reserved -83,000đ; Seller A +45,000đ; Seller B +23,000đ; Shipper Wallet +15,000đ; Order status = DELIVERED | Đúng như mong đợi | ✅ PASS |
| TC-WL-04 | Seller từ chối đơn → Hoàn tiền | Đặt hàng ví 60,000đ; Seller bấm "Từ chối" | reserved_balance Buyer -60,000đ; available_balance Buyer +60,000đ; Transaction REFUND ghi vào DB | Đúng như mong đợi | ✅ PASS |
| TC-WL-05 | Race condition – 2 request đặt hàng cùng lúc | Buyer gửi 2 request đặt hàng mỗi cái 80,000đ; Ví chỉ có 100,000đ | Chỉ 1 request thành công; 1 request nhận HTTP 400; tổng reserved ≤ 100,000đ | Row-level lock (with_for_update) ngăn chặn thành công | ✅ PASS |
| TC-WL-06 | Rollback khi lỗi giữa Transaction | Simulate lỗi DB sau khi trừ Buyer nhưng trước khi cộng Seller | Toàn bộ Transaction rollback; Buyer available không bị trừ; DB trở về trạng thái ban đầu | Rollback hoạt động đúng | ✅ PASS |
| TC-WL-07 | Rút tiền về ngân hàng (Seller) | Seller có available_balance = 500,000đ; yêu cầu rút 300,000đ | WithdrawRequest ghi vào DB; available_balance -300,000đ (trạng thái PENDING) | Đúng như mong đợi | ✅ PASS |

### 6.2.2 Test Cases – Luồng đặt hàng và trạng thái đơn

**Bảng 6.2.2: Test Cases cho module Đặt hàng**

| Mã TC | Mô tả | Điều kiện | Kết quả mong đợi | Thực tế | Trạng thái |
|-------|-------|----------|-----------------|---------|-----------|
| TC-OR-01 | Đặt hàng từ nhiều sạp hợp lệ | 2 sạp; giờ 10:00 sáng; Ví đủ tiền | Tạo 1 Order + N OrderItems; trạng thái PENDING; Seller nhận notification | ✅ Đúng | ✅ PASS |
| TC-OR-02 | Đặt hàng sau 19:00 | Giờ hệ thống 19:01 | HTTP 400 với code MARKET_CLOSED; Không tạo đơn | ✅ Đúng | ✅ PASS |
| TC-OR-03 | Đặt hàng khi tồn kho = 0 | Product stock_quantity = 0 | HTTP 400 với thông báo "Sản phẩm hết hàng" | ✅ Đúng | ✅ PASS |
| TC-OR-04 | Đặt hàng COD | payment = COD | Order tạo thành công; Không có Transaction Ví; Seller nhận notification | ✅ Đúng | ✅ PASS |
| TC-OR-05 | Seller xác nhận đơn | Order status = PENDING → Seller bấm xác nhận | Order status → SELLER_CONFIRMED; Notification gửi Buyer | ✅ Đúng | ✅ PASS |
| TC-OR-06 | Shipper nhận và hoàn thành chuyến | Order status = PICKING → Shipper xác nhận giao | Order status → DELIVERED; Wallet Release kích hoạt | ✅ Đúng | ✅ PASS |
| TC-OR-07 | Buyer hủy đơn | Order status = PENDING; Buyer bấm hủy | Status → CANCELLED; Ví Buyer hoàn tiền (nếu WALLET) | ✅ Đúng | ✅ PASS |

### 6.2.3 Test Cases – Luồng Seller đăng ký và duyệt gian hàng

**Bảng 6.2.3: Test Cases cho module Duyệt gian hàng**

| Mã TC | Mô tả | Điều kiện | Kết quả mong đợi | Thực tế | Trạng thái |
|-------|-------|----------|-----------------|---------|-----------|
| TC-SE-01 | Seller nộp hồ sơ đăng ký gian hàng | Seller đã có tài khoản; chưa có Stall | StallRegistration tạo ra với status = PENDING | ✅ Đúng | ✅ PASS |
| TC-SE-02 | Market Manager duyệt hồ sơ | StallRegistration status = PENDING; Manager click Duyệt | Stall record được tạo; Wallet Seller được tạo; Notification gửi Seller; Seller có thể đăng sản phẩm | ✅ Đúng | ✅ PASS |
| TC-SE-03 | Market Manager từ chối hồ sơ | Manager click Từ chối + nhập lý do | StallRegistration status = REJECTED; Seller nhận notification với lý do | ✅ Đúng | ✅ PASS |
| TC-SE-04 | Seller nộp trùng hồ sơ | Seller đã có Stall đang PENDING; nộp thêm lần nữa | HTTP 400: "Bạn đã có hồ sơ đang chờ duyệt" | ✅ Đúng | ✅ PASS |
| TC-SE-05 | Seller nộp hồ sơ sai loại sạp | stall_location không nằm trong danh mục hợp lệ | HTTP 400: Validation error về stall_location | ✅ Đúng | ✅ PASS |

### 6.2.4 Test Cases – Luồng AI Chat

**Bảng 6.2.4: Test Cases cho module AI Chat**

| Mã TC | Câu hỏi kiểm thử | Kết quả mong đợi | Kết quả thực tế | Trạng thái |
|-------|-----------------|-----------------|----------------|-----------|
| TC-AI-01 | "Tôi có thịt bò và 150k, nấu gì?" | Gợi ý 2-3 món từ thịt bò; liệt kê nguyên liệu; estimated cost ≤ 150k | Gợi ý đúng, có bò xào xả ớt và canh bò rau củ; nguyên liệu phù hợp | ✅ PASS |
| TC-AI-02 | "Con tôi 8 tuổi, muốn nấu gì tốt cho sức khỏe?" | Gợi ý các món phù hợp trẻ em; đề cập đến dinh dưỡng | Gợi ý cơm tấm thịt, cá hấp, canh rau; giải thích dinh dưỡng | ✅ PASS |
| TC-AI-03 | Câu hỏi không liên quan (test hallucination): "iPhone 16 giá bao nhiêu?" | AI từ chối hoặc chuyển hướng về chuyên môn đi chợ | AI trả lời: "Tôi chỉ có thể hỗ trợ gợi ý món ăn và nguyên liệu mua sắm tại chợ" | ✅ PASS |
| TC-AI-04 | "Hôm nay tôi không muốn ăn thịt, gợi ý món chay" | Gợi ý món chay; nguyên liệu không có thịt | Gợi ý canh bí đỏ, đậu hũ sốt cà chua, rau xào tỏi | ✅ PASS |
| TC-AI-05 | Câu hỏi về nguyên liệu không có trong chợ | Nguyên liệu exotic (truffle, foie gras) | AI gợi ý nguyên liệu thay thế phù hợp hơn với chợ truyền thống | ✅ PASS |
| TC-AI-06 | Kiểm thử timeout khi server GPU quá tải | Gửi 10 request đồng thời | API retry + trả về HTTP 504 với thông báo "Hệ thống AI đang bận, thử lại sau" | ⚠️ Thông báo lỗi OK nhưng UX chưa có retry tự động | ⚠️ PARTIAL |

---

## 6.3 Kết quả kiểm thử các luồng nghiệp vụ chính

### 6.3.1 Tổng hợp kết quả kiểm thử

**Bảng 6.3.1: Tổng hợp kết quả kiểm thử**

| Module | Tổng số test case | PASS | PARTIAL | FAIL | Tỉ lệ PASS |
|-------|-----------------|------|---------|------|-----------|
| Ví điện tử (Wallet) | 7 | 7 | 0 | 0 | **100%** |
| Đặt hàng (Order) | 7 | 7 | 0 | 0 | **100%** |
| Duyệt gian hàng (Stall Approval) | 5 | 5 | 0 | 0 | **100%** |
| AI Chat | 6 | 5 | 1 | 0 | **83%** |
| Xác thực (Auth) | 5 | 5 | 0 | 0 | **100%** |
| Shipper – Lộ trình | 4 | 4 | 0 | 0 | **100%** |
| **Tổng cộng** | **34** | **33** | **1** | **0** | **97%** |

### 6.3.2 Lỗi đã gặp và cách xử lý trong quá trình phát triển

**Bảng 6.3.2: Các lỗi đã gặp và hướng xử lý**

| Lỗi | Triệu chứng | Nguyên nhân | Giải pháp |
|-----|------------|------------|----------|
| Wallet âm số dư | Race condition khi 2 request đặt hàng đồng thời | Không có locking khi đọc/ghi Wallet | Thêm `SELECT ... FOR UPDATE` (Row-level lock) trong Transaction |
| Seller vẫn hiện trong danh sách "Pending" sau khi đã được duyệt | UI không refresh sau khi Approve xong | BLoC không invalidate cache sau Approve | Emit RefreshEvent sau khi API Approve thành công |
| API AI trả về 500 khi câu hỏi quá dài | LLM crash do prompt vượt context window | Không giới hạn độ dài input | Thêm truncation: cắt input nếu token > 2048 |
| Ảnh sản phẩm không hiển thị trên một số thiết bị | Lỗi SSL certificate khi load ảnh từ HTTP | Dev server dùng HTTP thay vì HTTPS | Thêm `android:usesCleartextTraffic="true"` cho dev; staging chuyển sang HTTPS |
| OSRM trả về route sai | Lộ trình vẽ không khớp với đường thực tế một số khu vực | Dữ liệu OSM trong khu vực một số hẻm nhỏ ở Đà Nẵng chưa chính xác | Cải thiện bằng cách cho phép Shipper điều chỉnh thủ công; đánh dấu khu vực lỗi để báo OSM community |

---

## 6.4 Kiểm thử hiệu năng hệ thống

### 6.4.1 Kiểm thử tải (Load Testing) Backend API

Nhóm sử dụng công cụ **Locust** để mô phỏng tải đồng thời nhiều người dùng:

**Bảng 6.4.1: Kết quả Load Testing FastAPI Backend**

| Endpoint | Số người dùng đồng thời | Requests/giây | Thời gian phản hồi TB | Thời gian phản hồi P95 | Tỉ lệ lỗi |
|---------|------------------------|--------------|---------------------|----------------------|---------|
| GET /api/products/ | 100 users | 250 req/s | 45ms | 120ms | 0% |
| POST /api/orders/ | 50 users | 80 req/s | 180ms | 450ms | 0% |
| POST /api/wallet (Reserve) | 30 users | 45 req/s | 230ms | 680ms | 0% |
| POST /api/ai/chat | 5 users | 2 req/s | 4,800ms | 8,200ms | ~2% (timeout) |

**Nhận xét:** Hầu hết API đáp ứng tốt ở mức tải đồng thời 50–100 người. Endpoint AI Chat chậm hơn do phụ thuộc vào GPU server, cần tối ưu thêm ở giai đoạn sau.

### 6.4.2 Kiểm thử hiệu năng Flutter App

**Bảng 6.4.2: Metrics hiệu năng Flutter App trên thiết bị thực**

| Điều kiện đo | Chỉ số | Kết quả | Mục tiêu |
|------------|-------|---------|---------|
| Khởi động App lần đầu (Cold Start) | Thời gian đến màn hình Login | 2.1 giây | ≤ 3 giây ✅ |
| Load trang chủ (20 sản phẩm) | Thời gian render xong | 850ms | ≤ 1 giây ✅ |
| Scroll danh sách sản phẩm | FPS trung bình | 58 FPS | ≥ 60 FPS ⚠️ |
| Load ảnh sản phẩm (cached) | Thời gian hiển thị | < 50ms | Nhanh ✅ |
| Chuyển màn hình (route transition) | Thời gian animation | 250ms | Mượt ✅ |
| Memory sử dụng | RAM khi dùng bình thường | ~180MB | Chấp nhận được ✅ |

---

## 6.5 Đánh giá tổng thể

### 6.5.1 Những gì đã đạt được

**Bảng 6.5.1: Bảng đối chiếu mục tiêu và kết quả thực hiện**

| Mục tiêu đề ra | Kết quả đạt được | Mức độ hoàn thành |
|---------------|-----------------|------------------|
| Xây dựng Mobile App đa vai trò (Buyer/Seller) trên Flutter | App hoạt động đầy đủ với 4 vai trò; kiến trúc BLoC sạch | ✅ 95% |
| Triển khai Backend API FastAPI kết nối DB PostgreSQL | ~25 endpoints; kiểm thử ổn định; Swagger UI sẵn sàng | ✅ 95% |
| Tích hợp AI RAG gợi ý thực đơn | RAG hoạt động với Qwen2.5; phản hồi đúng ngữ nghĩa đạt 92% | ✅ 85% |
| Hệ thống Ví điện tử nội bộ | Toàn bộ luồng Reserve/Release/Refund hoạt động; atomic transaction | ✅ 100% |
| Ứng dụng Shipper riêng với OSRM | App Shipper hoàn chỉnh; bản đồ OSRM vẽ lộ trình | ✅ 90% |
| Quy trình Seller đăng ký và duyệt gian hàng | End-to-end flow hoàn chỉnh; tạo Wallet tự động | ✅ 100% |
| Kiểm soát thời gian đặt hàng (trước 19:00) | Rule triển khai đúng; thông báo lỗi rõ ràng | ✅ 100% |

### 6.5.2 Những tồn tại và hạn chế chưa giải quyết

| Hạn chế | Lý do tồn tại | Kế hoạch xử lý |
|---------|--------------|--------------|
| AI Chat chưa có retry mechanism khi server quá tải | Hết thời gian sprint | Giai đoạn kế tiếp: Widget loading state + auto-retry sau 3 giây |
| FPS App thỉnh thoảng xuống 58 fps khi scroll danh sách dài | Chưa tối ưu ListView | Dùng ListView.builder với const Widget |
| Nạp tiền vào Ví cần Admin xác nhận thủ công | Chưa tích hợp webhook ngân hàng | Tích hợp VietQR API hoặc MoMo webhook ở release tiếp theo |
| Chưa có chức năng Chat giữa Buyer và Seller | Chưa hoàn thiện WebSocket | Sẽ bổ sung ở release cuối kỳ |
| App chưa publish lên CH Play / App Store | Chi phí tài khoản nhà phát triển; cần hội đủ điều kiện | Demo APK file & TestFlight link |

---

*[Hết Chương 6 – Tiếp theo: Chương 7: Kết luận và Hướng phát triển]*
