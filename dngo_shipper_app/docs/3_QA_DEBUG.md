# 🛠 3. QA & DEBUG (Kiểm thử & Bắt Lỗi)
*File này tôi (Gemini) sẽ đọc để tự động chạy Flutter Analyze quét lỗi, thiết lập các quy tắc check crash và xử lý rủi ro.*

## A. Luồng nghiệp vụ (Business Rules)
*Đây là các luật cấm để tôi code logic chặn lại:*
1. Shipper chưa bấm "Đã lấy hàng" thì không thể bấm "Hoàn thành".
2. Bấm "Nhận đơn" nhưng nếu API trả về báo "Có người khác giựt mất rồi" -> Phải hiện Popup báo lỗi chứ không được sụp App.
3. (Bạn điền thêm quy tắc ở đây)...

## B. Yêu cầu Bắt lỗi (Exception Handling)
- **Khi rớt mạng:** App có popup báo "Không có kết nối mạng" hay hiện màn hình sập? (Mặc định tôi sẽ làm Snackbar hoặc Widget báo lỗi kết nối).
- **Lỗi hiển thị dữ liệu:** Nếu API trả về `null` thay vì danh sách, UI phải hiển thị text "Chưa có đơn hàng nào".

## C. Kịch bản chạy Debug tự động (Mặc định)
Khi code xong, tôi sẽ lấy mớ luật này, chạy `flutter analyze` để dọn sạch lỗi type, lỗi syntax, cảnh báo linter. Sau đó tôi sẽ rà soát chéo xem code BLoC ở Bước 2 có trói được logic của Bước 3 không.
