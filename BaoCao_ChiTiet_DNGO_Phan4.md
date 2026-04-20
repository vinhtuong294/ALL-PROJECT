# BÁO CÁO TOÀN VĂN: XÂY DỰNG ỨNG DỤNG THƯƠNG MẠI ĐIỆN TỬ DNGO – CHỢ ONLINE TÍCH HỢP AI

---

## CHƯƠNG 6: ĐÁNH GIÁ VÀ THỬ NGHIỆM HỆ THỐNG

### 6.1 Kịch bản kiểm thử (Test Scenarios)
Dự án được đánh giá theo 3 tiêu chí cốt lõi: 1. Logic đặt hàng đa sạp (Multi-stall); 2. Độ chính xác của AI RAG; 3. Quy trình bảo mật của Ví thanh toán.

- **Đơn hàng Đa sạp:** Bỏ 2 mặt hàng (Thịt cá, Rau) từ hai sạp A và B vào giỏ -> Tạo Đơn. 
    - *Kết quả thực tế:* Backend tự động gọi logic chia đơn order (Split Order). Ứng dụng Shipper nhận được 1 Assignment, nhưng có 2 Pickup Points trong màn hình bản đồ chợ. Thành công.
- **AI Recommendation:** Sử dụng endpoint external GPU (như proxy Runpod chạy model Qwen) để gọi hội thoại. 
    - *Kết quả thực tế:* Thời gian phản hồi trong 3-5 giây. Vector Search trả về danh sách nguyên liệu match tới 80% sản phẩm có thực ở chợ Bắc Mỹ An.
- **Ví thanh toán:** Giả lập trường hợp User có 50.000, món hàng 70.000. 
    - *Kết quả thực tế:* Giao diện ứng dụng bắn lỗi hợp lệ (Cảnh báo: Số dư ví không đủ). Cho phép chuyển hướng sang nạp tiền (Top-up). Ràng buộc bảo mật của Database đảm bảo tiền không bị âm và lock ID wallet song song giải quyết data race. Vượt qua thử nghiệm an toàn dòng tiền.

### 6.2 Kết quả triển khai trải nghiệm thực tế
Giao diện ứng dụng mượt mà (60 FPS do đặc tính của Flutter). Codebase Frontend cho phép chia component riêng biệt, giúp tái sử dụng trang Đăng ký (Signup) chung cho Seller và Buyer. Shipper App vận hành GPS location chuẩn, giúp đo đếm khoảng cách bằng OSRM thực tế mà không đội chi phí maps API. Lỗi xử lý giao diện khi người Mua không xác thực được ID lô/sạp của Gian Hàng khi tạo cũng đã được bắt lỗi HTTP 400 và fix hoàn chỉnh.

---

## CHƯƠNG 7: KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN

### 7.1 Kết quả đạt được
- So với các dự án giả lập trước đó, nhóm đã hoàn thành xuất sắc hệ thống "code thực, vận hành thực". Toàn bộ Business Flow tại giai đoạn Cap 2 được chuyển hóa thành các App di động chuyên sâu (`Done-demo` và `dngo_shipper_app`).
- Chức năng "Ví điện tử" mới ra được xây dựng trọn vẹn, khép kín vòng tài chính, giảm phụ thuộc vào sự chênh lệch chi phí hoa hồng của cổng thanh toán thứ ba so với thực trạng những hạn chế TMĐT gây khó dễ người bán ở chợ dân sinh.
- RAG LLM đã chứng tỏ giá trị vượt mong đợi, biến việc đi chợ nhàm chán hàng ngày trở thành thao tác trải nghiệm tư vấn số tinh vi và hữu ích.

### 7.2 Hạn chế còn tồn tại
- Dữ liệu nguyên vật liệu và bản đồ chợ trên OSRM vẫn chủ yếu dựa vào việc mapping thủ công. Cần ứng dụng thêm Data scraping chạy real-time để update giá cả của các chủ sạp.
- Host Server cho model GPU (Ollama/RAG) rất nhạy cảm với việc tăng giảm RAM, đôi lúc API AI tốn hơn 10 giây để respond nếu luồng concurrent cao.
- Mobile App hiện chưa gắn Apple/Google Sign In do giới hạn bản quyền publish ứng dụng.

### 7.3 Hướng phát triển trong tương lai
- Ứng dụng hệ thống Machine Learning mạnh mẽ hơn dự đoán (Forecasting) mức tiêu thụ nguyên vật liệu tại chợ theo ngày và mùa. 
- Ra mắt tính năng tích hợp Voucher điện tử hoặc hệ thống điểm thưởng (Royalty points) sử dụng chính Ví thanh toán vừa xây.
- Chính thức thí điểm rộng rãi cho 3 đến 5 chợ loại 1 tại thành phố Đà Nẵng, đào tạo tiểu thương quen với quá trình vận hành O2O (Online to Offline). Mở rộng chuỗi logistic giao hàng cho Shipper xuyên chợ.

---
*(Hết Báo Cáo. Nội dung này có thể kết dính với Trang bìa, Lời mở đầu, Danh mục tham khảo của bản Góp Ý/Giữa Kỳ PDF cũ để trở thành 1 bản Báo cáo hoàn thiện)*
