# CHƯƠNG 7: KẾT LUẬN VÀ HƯỚNG PHÁT TRIỂN

---

## MỤC LỤC CHƯƠNG 7

- [7.1 Tóm tắt những gì đã thực hiện](#71-tóm-tắt-những-gì-đã-thực-hiện)
- [7.2 Bài học kinh nghiệm rút ra trong quá trình phát triển](#72-bài-học-kinh-nghiệm-rút-ra-trong-quá-trình-phát-triển)
- [7.3 Hướng phát triển trong tương lai](#73-hướng-phát-triển-trong-tương-lai)
- [7.4 Đánh giá khả năng thương mại hóa](#74-đánh-giá-khả-năng-thương-mại-hóa)
- [7.5 Lời kết](#75-lời-kết)

---

## 7.1 Tóm tắt những gì đã thực hiện

Dự án **DNGo – Chợ Online tích hợp AI** trong học phần Thực hành Dự án Thương mại Điện tử là bước chuyển hóa mang tính đột phá từ một báo cáo nghiên cứu trong học phần Capstone 2 thành một **sản phẩm phần mềm hoạt động trên thiết bị thực**.

Tính đến thời điểm báo cáo giữa kỳ, nhóm đã đạt được những cột mốc quan trọng sau:

### 7.1.1 Về sản phẩm phần mềm

Hệ thống được hoàn thiện đầy đủ với **3 ứng dụng** và **1 backend server**:

| Thành phần | Công nghệ | Số màn hình/endpoint | Trạng thái |
|----------|----------|---------------------|-----------|
| App Khách hàng & Người bán (`Done-demo`) | Flutter/Dart, BLoC | ~25 màn hình | Hoàn thiện ✅ |
| App Shipper (`dngo_shipper_app`) | Flutter/Dart, BLoC | ~10 màn hình | Hoàn thiện ✅ |
| Backend API (`LLM-master`) | FastAPI, PostgreSQL | ~25 API endpoints | Hoàn thiện ✅ |
| AI/RAG Server | Ollama, Qwen2.5, FAISS | 1 endpoint /ai/chat | Đang tối ưu ⚠️ |

### 7.1.2 Về chức năng nghiệp vụ

Tất cả **8 module nghiệp vụ chính** đều được triển khai thực tế:

1. ✅ **Module xác thực người dùng** – Đăng ký, đăng nhập, phân quyền JWT theo 5 vai trò.
2. ✅ **Module quản lý sản phẩm** – Seller đăng sản phẩm; Buyer tìm kiếm, xem, thêm vào giỏ.
3. ✅ **Module giỏ hàng đa sạp** – Đặt hàng từ nhiều sạp trong một giao dịch.
4. ✅ **Module Ví điện tử nội bộ** – Reserve/Release/Refund với Atomic Transaction.
5. ✅ **Module đặt hàng và quản lý trạng thái** – Luồng PENDING → DELIVERED đầy đủ.
6. ✅ **Module Shipper và định tuyến OSRM** – Gom đơn đa điểm, bản đồ thực tế.
7. ✅ **Module duyệt gian hàng** – Quy trình Market Manager duyệt và tạo Ví Seller.
8. ⚠️ **Module AI Chat RAG** – Hoạt động nhưng còn cần tối ưu thời gian phản hồi.

### 7.1.3 Về kỹ thuật

- **Kiến trúc phần mềm** được thiết kế rõ ràng theo Feature-first (Flutter-BLoC) và Service-layer (FastAPI), dễ dàng bảo trì và mở rộng.
- **Bảo mật tài chính** được đảm bảo thông qua Row-level locking và Atomic Transaction trong PostgreSQL.
- **Tự chủ công nghệ** nhờ sử dụng LLM self-hosted (không phụ thuộc API trả phí) và OSRM (không tốn phí Google Maps).
- **Kiểm thử nghiêm túc** với 34 test cases, tỉ lệ PASS đạt 97%.

---

## 7.2 Bài học kinh nghiệm rút ra trong quá trình phát triển

### 7.2.1 Về quản lý dự án

**Bảng 7.2.1: Bài học từ quản lý dự án nhóm**

| Vấn đề gặp phải | Bài học rút ra |
|----------------|--------------|
| Thiếu convention đặt tên API và DTO dẫn đến nội dung khác nhau giữa FE và BE | **Phải viết API Contract rõ ràng từ đầu** – định nghĩa Request/Response schema trước khi code cả hai phía |
| Git conflict thường xuyên ở các file shared (constants, router) | **Dùng Feature Branch Pattern** – mỗi người code trên branch riêng, merge vào develop sau khi review |
| Estimate thời gian task sai (thực tế luôn tốn hơn 2x thời gian ước tính) | **Áp dụng hệ số rủi ro × 1.5** khi estimate, cộng thêm buffer time cho debugging |
| AI module mất nhiều thời gian tích hợp hơn dự kiến | **Phải prototype AI riêng** trong môi trường cô lập trước khi tích hợp vào hệ thống chính |

### 7.2.2 Về kỹ thuật

| Vấn đề kỹ thuật | Giải pháp và bài học |
|----------------|---------------------|
| Data inconsistency giữa App khi nhiều request cùng lúc | Hiểu rõ tầm quan trọng của Database Transaction và locking cơ chế |
| LLM trả về định dạng JSON không consistent | Cần dùng **structured output** (JSON schema enforcement) hoặc retry với parsing validation |
| Flutter setState quá nhiều gây rebuild không cần thiết | BLoC giúp kiểm soát rebuild chính xác hơn, nên dùng BLoC cho state phức tạp thay vì setState |
| OSRM tính route đôi khi không phù hợp địa hình trong chợ | Bản đồ trong nhà (Indoor Maps) cần giải pháp khác – OSM chỉ phù hợp đường ngoài trời |

### 7.2.3 Về thiết kế sản phẩm

- Việc **tham khảo báo cáo Cap 2 kỹ** trước khi lập trình giúp tiết kiệm đáng kể thời gian thiết kế luồng nghiệp vụ, tránh phải làm đi làm lại.
- **Tính năng Ví điện tử** – dù phức tạp hơn dự kiến – là tính năng được cả nhóm đánh giá có giá trị CAO NHẤT về mặt nghiệp vụ. Nó giải quyết trực tiếp vấn đề dòng tiền của tiểu thương chợ truyền thống.
- **Test sớm với người dùng thật** (tiểu thương, người nội trợ) giúp nhóm phát hiện ra nhiều vấn đề UX mà không bao giờ xuất hiện khi chỉ test trong nhóm. Ví dụ: Nút "Xác nhận đơn" của Seller cần to và rõ ràng hơn vì tiểu thương thường xem trên điện thoại cũ màn hình nhỏ.

---

## 7.3 Hướng phát triển trong tương lai

### 7.3.1 Kế hoạch ngắn hạn (Cuối học kỳ – T6/2026)

Đây là những tính năng nhóm cam kết hoàn thiện trước khi nộp báo cáo cuối kỳ:

| Hạng mục | Mô tả | Độ ưu tiên |
|---------|-------|-----------|
| Chat Buyer-Seller | Tính năng nhắn tin trong App giữa khách và tiểu thương về thông tin đơn hàng | Cao |
| Retry mechanism AI Chat | Tự động retry khi GPU server quá tải, UI hiển thị loading state rõ ràng hơn | Cao |
| Nạp tiền Ví bán tự động | Tích hợp VietQR để tự động nhận biết khi Buyer chuyển khoản (không cần Admin xác nhận thủ công) | Cao |
| Đánh giá và xếp hạng sản phẩm | Buyer đánh giá sau khi nhận hàng; hiển thị sao trên trang sản phẩm Seller | Trung bình |
| Optimization danh sách sản phẩm | Phân trang (pagination), infinite scroll, lazy load ảnh | Trung bình |
| Dashboard thống kê cho Market Manager | Biểu đồ tổng hợp hoạt động chợ: tổng đơn, tổng doanh thu, top Seller | Thấp |

### 7.3.2 Kế hoạch trung hạn (1 năm sau out – 2027)

Nếu được tiếp tục phát triển và thử nghiệm thực tế:

**a) Mở rộng AI:**
- Tích hợp **Image Recognition**: Người dùng chụp ảnh tủ lạnh → AI nhận biết nguyên liệu có sẵn và gợi ý món.
- **AI Forecasting** dự báo nhu cầu nguyên liệu theo ngày và mùa, giúp tiểu thương nhập hàng chính xác hơn.
- **Personalization Engine**: Học thói quen mua sắm của từng người dùng để cá nhân hóa gợi ý.

**b) Mở rộng hệ thống Logistic:**
- **Shipper Pool nội chợ**: Chia sẻ Shipper giữa nhiều chợ trong cùng quận, tối ưu hóa thời gian nhàn rỗi của Shipper.
- **Batch Delivery Optimization**: Gom đơn của nhiều khách ở gần nhau thành một chuyến giao, giảm chi phí ship.

**c) Mở rộng thanh toán:**
- Tích hợp **MoMo/ZaloPay API** cho người dùng muốn nạp tiền Ví từ ví điện tử bên ngoài.
- **Hóa đơn điện tử** tự động cho mỗi giao dịch.
- **Chương trình điểm thưởng (Loyalty Program)**: Cộng điểm mỗi lần mua hàng qua Ví, dùng điểm đổi voucher.

### 7.3.3 Kế hoạch dài hạn (3–5 năm – Scale up)

**Bảng 7.3.3: Lộ trình chiến lược phát triển của DNGo**

| Giai đoạn | Thời điểm | Mục tiêu | Chỉ số |
|---------|----------|---------|-------|
| **Pilot** | Q2/2026 | Thử nghiệm thực tế tại Chợ Bắc Mỹ An, Đà Nẵng | 20 Seller, 200 Buyer, 5 Shipper |
| **Local Scale** | Q4/2026 | Mở rộng ra 5 chợ tại Đà Nẵng | 100 Seller, 2,000 Buyer, 30 Shipper |
| **Regional Scale** | Q2/2027 | Mở rộng vào TP.HCM (thí điểm 2 chợ) | 300 Seller, 10,000 Buyer |
| **National Scale** | Q4/2027 | Hiện diện tại 3 thành phố lớn | 1,000+ Seller, 50,000+ Buyer |
| **AI-First Platform** | 2028+ | Ra mắt tính năng AI Forecasting, Personalization, Image Recognition | Tỉ lệ Retention ≥ 40% |

---

## 7.4 Đánh giá khả năng thương mại hóa

### 7.4.1 Mô hình doanh thu

DNGo có thể tạo ra doanh thu bền vững từ nhiều nguồn:

**Bảng 7.4.1: Mô hình doanh thu của DNGo**

| Nguồn doanh thu | Mô tả | Tỉ lệ ước tính |
|----------------|-------|--------------|
| **Phí giao dịch Ví** | Thu 1% trên mỗi giao dịch đặt hàng qua Ví DNGo | ~30% doanh thu |
| **Phí hoa hồng Seller** | Thu 2–3% doanh thu của Seller mỗi tháng (sau khi đạt ngưỡng GMV nhất định) | ~35% doanh thu |
| **Phí thuê gian hàng số** | Seller trả phí tháng để duy trì gian hàng trên nền tảng | ~20% doanh thu |
| **Quảng cáo nổi bật** | Seller trả phí để sản phẩm hiển thị nổi bật trong kết quả tìm kiếm | ~10% doanh thu |
| **Premium AI** | Gói Premium cho Buyer: Gợi ý thực đơn theo tuần, kế hoạch dinh dưỡng dài hạn | ~5% doanh thu |

### 7.4.2 Phân tích SWOT

**Bảng 7.4.2: Phân tích SWOT của DNGo**

| | Điểm mạnh (Strengths) | Điểm yếu (Weaknesses) |
|--|----------------------|----------------------|
| **Nội bộ** | • AI gợi ý thực đơn tích hợp trực tiếp vào mua sắm – độc đáo và thiết thực<br>• Ví điện tử nội bộ giảm chi phí giao dịch<br>• OSRM miễn phí giúp tối ưu chi phí vận hành<br>• Codebase có kiến trúc tốt, dễ mở rộng | • Đội ngũ nhỏ (3 sinh viên), nguồn lực hạn chế<br>• AI đôi khi phản hồi chậm (>5 giây)<br>• Chưa có dữ liệu nguyên liệu realtime từ tiểu thương |
| **Bên ngoài** | **Cơ hội (Opportunities)** | **Thách thức (Threats)** |
| | • Thị trường FMCG online Việt Nam tăng trưởng 22%/năm<br>• Chính phủ đẩy mạnh chuyển đổi số chợ truyền thống<br>• Tiểu thương khát nhu cầu kinh doanh online nhưng thiếu nền tảng phù hợp | • Cạnh tranh từ ShopeeFood, GrabMart, BeFood<br>• Tiểu thương cao tuổi khó chấp nhận công nghệ mới<br>• Chi phí marketing để thu hút Seller và Buyer ban đầu rất cao |

---

## 7.5 Lời kết

Dự án **DNGo – Chợ Online tích hợp AI** là minh chứng cho khả năng của sinh viên Trường Đại học Kinh tế – Đại học Đà Nẵng trong việc **biến ý tưởng nghiên cứu thành sản phẩm số thực tế** có giá trị ứng dụng cao.

Khác với nhiều dự án học phần chỉ dừng lại ở mức prototype giao diện, nhóm PROA đã mạnh dạn đầu tư thời gian học thêm và tự triển khai các công nghệ phức tạp như **RAG pipeline với LLM**, **Atomic Transaction trong Engine quản lý Ví**, và **thuật toán tối ưu định tuyến OSRM** – những công nghệ được sử dụng rộng rãi trong các startup công nghệ hàng đầu thế giới.

Hành trình từ bản báo cáo Cap 2 đến ứng dụng chạy trên thiết bị thực đã dạy nhóm rất nhiều bài học quý giá không chỉ về kỹ thuật, mà còn về tư duy sản phẩm: luôn đặt câu hỏi *"Người dùng thực sự cần gì?"* trước khi quyết định xây dựng tính năng nào.

Nhóm tin tưởng rằng với sự tiếp tục hoàn thiện và cơ hội thử nghiệm thực tế, **DNGo có tiềm năng thực sự trở thành nền tảng chợ số hàng đầu tại Đà Nẵng**, góp phần bảo tồn và phát huy giá trị của chợ truyền thống Việt Nam trong kỷ nguyên số hóa.

---

## TÀI LIỆU THAM KHẢO

1. Google LLC (2024). *Flutter Documentation – State Management with BLoC.* https://docs.flutter.dev
2. Sebastián Ramírez (2024). *FastAPI Documentation.* https://fastapi.tiangolo.com
3. PostgreSQL Global Development Group (2024). *PostgreSQL 16 Documentation.* https://www.postgresql.org/docs/
4. OSRM Project (2024). *Open Source Routing Machine Documentation.* http://project-osrm.org/
5. Alibaba Cloud (2024). *Qwen2.5 Technical Report.* https://qwenlm.github.io/
6. Lewis, P., Perez, E., et al. (2020). *Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks.* NeurIPS 2020.
7. Temasek, Google, Bain & Company (2024). *e-Conomy SEA 2024 Report.* https://economysea.withgoogle.com/
8. Sở Công Thương Đà Nẵng (2024). *Báo cáo tổng kết hoạt động chợ truyền thống trên địa bàn thành phố Đà Nẵng năm 2024.*
9. Nghị quyết 05-NQ/TU của Thành ủy Đà Nẵng (2023). *Về chuyển đổi số trên địa bàn thành phố Đà Nẵng đến năm 2025.*
10. Mifflin, M.D., St Jeor, S.T., et al. (1990). *A new predictive equation for resting energy expenditure in healthy individuals.* American Journal of Clinical Nutrition.

---

*[Hết báo cáo. Đà Nẵng, tháng 4 năm 2026]*

---

## PHỤ LỤC

### Phụ lục A: Danh sách màn hình ứng dụng Done-demo

| STT | Tên màn hình | Route | Vai trò |
|-----|------------|-------|--------|
| 1 | Splash Screen | `/splash` | Tất cả |
| 2 | Login Screen | `/login` | Tất cả |
| 3 | Register Screen | `/register` | Buyer, Seller |
| 4 | Home Screen (Buyer) | `/home` | Buyer |
| 5 | Product List Screen | `/products` | Buyer |
| 6 | Product Detail Screen | `/products/:id` | Buyer |
| 7 | Cart Screen | `/cart` | Buyer |
| 8 | Checkout Screen | `/checkout` | Buyer |
| 9 | Order Tracking Screen | `/orders/:id` | Buyer |
| 10 | Order History Screen | `/orders` | Buyer, Seller |
| 11 | AI Chat Screen | `/ai-chat` | Buyer |
| 12 | Wallet Screen (Buyer) | `/wallet` | Buyer |
| 13 | Transaction History Screen | `/wallet/transactions` | Buyer, Seller |
| 14 | Deposit Request Screen | `/wallet/deposit` | Buyer |
| 15 | Profile Screen | `/profile` | Tất cả |
| 16 | Seller Dashboard | `/seller` | Seller |
| 17 | Seller Products List | `/seller/products` | Seller |
| 18 | Add/Edit Product | `/seller/products/edit` | Seller |
| 19 | Seller Orders | `/seller/orders` | Seller |
| 20 | Seller Revenue | `/seller/revenue` | Seller |
| 21 | Seller Wallet | `/seller/wallet` | Seller |
| 22 | Withdraw Request Screen | `/seller/wallet/withdraw` | Seller |
| 23 | Register Stall Screen | `/seller/register-stall` | Seller |
| 24 | Market Manager Dashboard | `/admin` | Market Manager |
| 25 | Pending Sellers Screen | `/admin/pending-sellers` | Market Manager |

### Phụ lục B: Danh sách màn hình ứng dụng dngo_shipper_app

| STT | Tên màn hình | Mô tả |
|-----|------------|-------|
| 1 | Login Screen | Đăng nhập Shipper |
| 2 | Home / Available Orders | Danh sách chuyến hàng chờ nhận |
| 3 | Order Detail Screen | Chi tiết đơn hàng sẽ nhận |
| 4 | Map/Route Screen | Bản đồ OSRM với lộ trình gom đơn |
| 5 | Pickup Confirmation | Xác nhận đã lấy hàng tại từng sạp |
| 6 | Delivery Confirmation | Xác nhận giao hàng + upload ảnh |
| 7 | Earnings Screen | Thu nhập ngày/tuần |
| 8 | Profile Screen | Thông tin Shipper |
| 9 | Wallet Screen | Ví Shipper – số dư và lịch sử |
| 10 | Market Map | Sơ đồ chợ để định hướng |
