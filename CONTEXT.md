# Tổng quan dự án DNGO (Mô hình chợ Online đa đối tác)

**Tên dự án:** DNGO
**Loại hình:** Hệ thống thương mại điện tử kết nối nhiều đối tác (Người mua, Người bán, Shipper, Ban quản lý chợ) trong một khu vực chợ truyền thống/chợ online.
**Công nghệ sử dụng:**
- **Frontend:** Flutter (Sử dụng Clean Architecture, State Management: BLoC/Cubit).
- **Backend:** Python FastAPI (RESTful API).
- **AI/LLM:** Tích hợp RAG/Ollama cho Chatbot gợi ý món ăn và mục tiêu sức khỏe.

---

## 📂 Cấu trúc các ứng dụng Frontend trong Workspace (`c:\market_app 1\`)

Dự án Frontend được chia thành 3 App độc lập để phục vụ 4 đối tượng người dùng:

### 1. Ứng dụng Người mua & Người bán (`Done-demo`)
- **Vị trí:** `c:\market_app 1\Done-demo`
- **Tính năng Người mua (Buyer):** Xem gian hàng, xem sản phẩm, gợi ý món ăn qua AI Chatbot, thêm vào giỏ hàng, thanh toán (Tiền mặt/VNPay), chọn khung giờ giao hàng, theo dõi đơn hàng và GPS shipper.
- **Tính năng Người bán (Seller):** Quản lý nguyên liệu/sản phẩm của sạp, duyệt đơn hàng, chuẩn bị hàng hóa, thống kê doanh thu, nhận thông báo có đơn mới.
- **Kiến trúc:** Feature-driven architecture (Các module nằm trong `lib/feature/buyer/` và `lib/feature/seller/`).

### 2. Ứng dụng Shipper (`dngo_shipper_app`)
- **Vị trí:** `c:\market_app 1\dngo_shipper_app`
- **Tính năng:** Nhận đơn hàng, gom đơn (Batching orders từ nhiều khách hàng/gian hàng cùng lúc), lấy hàng theo từng nguyên liệu tại các sạp khác nhau (ingredient-level pickup), cập nhật trạng thái giao hàng, tracking GPS thời gian thực.
- **Quy trình gắt gao:** Shipper không thể bấm "Đang giao" nếu chưa xác nhận lấy đủ tất cả các món hàng từ các sạp (`da_lay_hang`).

### 3. Ứng dụng Ban Quản Lý Chợ - Admin (`market-app`)
- **Vị trí:** `c:\market_app 1\market-app`
- **Nền tảng:** Chủ yếu build trên Web (`flutter run -d chrome`).
- **Tính năng:** Xem Dashboard thống kê (tổng gian hàng, số gian hàng mở/đóng), xem Sơ đồ chợ trực quan (Map), xem chi tiết chủ sạp, và thu phí/thuế gian hàng.
- **Đặc điểm UI:** Giao diện thẻ (Card-based), tông màu Xanh lá/Trắng (Green branding).

---

## 🌐 Thông tin Backend API & Cấu hình
- **Base URL Hiện tại (Production):** `http://207.180.233.84:8000` (hoặc `/api` endpoint).
- **Base URL AI Chatbot:** `ws://207.180.233.84:8000/api/chat/ws`
- File cấu hình tập trung thường nằm ở: `lib/core/config/app_config.dart` hoặc `lib/core/services/api_service.dart`.

---

## 🧠 Các Quy tắc Nghiệp vụ Kỹ thuật Cần Lưu Ý (Business Logic)

1. **Thanh toán & Giao hàng (Buyer):**
   - Giới hạn giờ đặt hàng: Sau 19:00 sẽ chốt ca, không nhận đơn trong ngày.
   - Giờ giao hàng: Khách hàng yêu cầu giao sớm nhất phải cách thời điểm đặt hiện tại **1 tiếng** (để chuẩn bị món).

2. **Quy trình Order (Shipper):**
   - Vì một đơn hàng có thể bao gồm nhiều nguyên liệu/món ăn từ **nhiều sạp khác nhau**, Shipper phải đi gom hàng.
   - API Update Status cho phép cập nhật trạng thái từng "Item" trong đơn hàng thành `da_lay_hang`.

3. **Giao diện & UI/UX:**
   - **Màu chủ đạo:** Xanh lá cây chuẩn của DNGo (`#4CAF50` hoặc `#00B40F`).
   - Yêu cầu thiết kế học thuật, trang trọng nếu cần sinh báo cáo/đồ án tốt nghiệp.
   - Sử dụng Card, Border Radius bo góc, bóng đổ nhẹ (BoxShadow) để tạo cảm giác hiện đại (Glassmorphism/Clean UI).

---

## 🤖 Hướng dẫn cho AI Agents tiếp theo
1. Khi có yêu cầu sửa lỗi/thêm tính năng, hãy xác định rõ **App nào** đang được nhắc đến (`Done-demo`, `dngo_shipper_app`, hay `market-app`).
2. Luôn kiểm tra các file trong `lib/core/services/` để xem cách gọi API trước khi viết UI.
3. Khi debug giao diện, hãy sử dụng `grep_search` để tìm các Widget tái sử dụng thay vì code cứng từ đầu.
4. Dự án sử dụng tiếng Việt cho các biến trạng thái quan trọng từ Backend (VD: `mo_cua`, `dong_cua`, `da_lay_hang`, `dang_giao`). Hãy chú ý mapping string chính xác.
