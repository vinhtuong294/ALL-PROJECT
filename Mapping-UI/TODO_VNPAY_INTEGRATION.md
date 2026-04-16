# Hướng dẫn hoàn thiện tích hợp VNPay vào Frontend (DNGO)

Tôi (Gemini) đã phân tích file `payment_cubit.dart` và refactor lại file `vnpay_service.dart` của bạn. 
**Phần API + State Management (Cubit) cơ bản đã đầy đủ**. Tuy nhiên, để tính năng VNPay trên app thực sự hoạt động trơn tru (Mở browser -> User điền thẻ -> App tự động catch lại kết quả), bạn còn thiếu một số mảnh ghép bên dưới:

## 1. Xử lý Deep Link (App Links/Universal Links)
**Vấn đề:** Hiện tại `payment_cubit.dart` dùng `launchUrl(url)` để quăng user ra trình duyệt thanh toán. Khi thanh toán xong, làm sao Browser biết đường mở lại App?
**Việc cần làm:**
- [ ] Cấu hình URL Scheme (VD: `dngoapp://vnpay-return`) trên cổng thanh toán VNPay Dashboard.
- [ ] Đăng ký **Intent Filter** trong `android/app/src/main/AndroidManifest.xml` và cấu hình hệ thống trên `ios/Runner/Info.plist` cho Deep Link.
- [ ] Sử dụng package `uni_links` hoặc `app_links` tại file trang thanh toán để bắt tín hiệu khi User bị redirect về app, từ đó nhổ thẻ query params ra.
- [ ] Truyền chuỗi query params đó vào tính năng `verifyVNPayReturn(queryParams)` của `PaymentCubit`.

## 2. Hoàn thiện UI Lắng nghe State tại Trang Thanh Toán (`payment_page.dart`)
**Vấn đề:** Cubit hiện đã bắn ra các State `PaymentProcessing`, `PaymentSuccess`, `PaymentPendingVNPay` và `PaymentFailure`.
**Việc cần làm:**
- [ ] Thêm file UI `BlocListener` tại trang Checkout (Hoặc màn thanh toán).
- [ ] Nếu state là `PaymentPendingVNPay`: Vẽ 1 popup hoặc giao diện cho biết "Đơn hàng đang chờ VNPay xử lý", có nút bấm `Check lại tiến độ`. Nut này sẽ bắn event `checkPaymentStatus()` lại vào Cubit để poll status.
- [ ] Nếu state là `PaymentSuccess`: Navigate qua trang Hoàn Tất Đơn Hàng (Order Success Page), xoá giỏ hàng.

## 3. Quản lý trạng thái Resume (Lifecycle)
**Vấn đề:** Nếu người dùng thanh toán trên Webview / Browser nhưng VNPay bị đóng đột ngột (hoặc họ bấm mũi tên back quay lại App), làm sao app biết tiền đã vào chưa?
**Việc cần làm:**
- [ ] Sử dụng `WidgetsBindingObserver` ở trang thanh toán để theo dõi biến đổi `AppLifecycleState.resumed`.
- [ ] Khi App `resumed` từ việc mở URL VNPay, lập tức gọi `paymentCubit.checkPaymentStatus()` thay vì chờ Deep Link (Vì có trường hợp Browser đóng khẩn cấp URL gốc mà không quăng link về).

## Tôi có thể giúp gì tiếp?
Nếu bạn muốn tôi **tự động hoàn thiện 1 trong 3 bước trên**, hãy gõ prompt:
> *"Hãy áp dụng cấu hình tự động (mục số 1 hoặc số 3) trực tiếp vào code của tôi."* Tôi sẽ tiếp tục dùng tool dò tới thư mục `android/` hoặc trang UI để tự động nối code cho bạn.
