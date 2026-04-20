# BÁO CÁO TOÀN VĂN: XÂY DỰNG ỨNG DỤNG THƯƠNG MẠI ĐIỆN TỬ DNGO – CHỢ ONLINE TÍCH HỢP AI

---

## CHƯƠNG 1: TỔNG QUAN DỰ ÁN

### 1.1 Bối cảnh hình thành ý tưởng
Trong bối cảnh chuyển đổi số quốc gia giai đoạn 2021–2030, việc số hóa các hoạt động thương mại dân sinh ngày càng trở nên cấp thiết. Đặc biệt sau đại dịch COVID-19, thói quen tiêu dùng đi chợ truyền thống gặp nhiều thách thức do sự cạnh tranh từ các nền tảng thương mại điện tử lớn và siêu thị. Mặc dù chợ truyền thống vẫn giữ vị thế quan trọng trong việc cung cấp thực phẩm tươi sống, việc thiếu nền tảng số hóa để kết nối người mua, tiểu thương, ban quản lý và người giao hàng (shipper) đã làm giảm năng lực cạnh tranh của tiểu thương. Từ đó, ý tưởng hình thành ứng dụng **DNGO - Chợ Online** ra đời với mục đích tạo ra một hệ sinh thái chợ thông minh.

### 1.2 Mục tiêu dự án
- **Đối với người mua:** Cung cấp trải nghiệm mua sắm tiện lợi, có tính năng AI gợi ý công thức món ăn dựa trên nguyên liệu sẵn có, cá nhân hóa theo khẩu vị và chỉ số dinh dưỡng (TDEE/BMR).
- **Đối với tiểu thương:** Hỗ trợ bán hàng đa kênh, quản lý gian hàng điện tử, tự động hóa thanh toán thông qua **ví thanh toán** nội bộ.
- **Đối với quản lý chợ:** Điện tử hóa quá trình duyệt gian hàng, kiểm soát tập trung sơ đồ chợ.
- **Đối với Shipper:** Tối ưu hóa hóa quy trình gom đơn, lấy hàng tại nhiều sạp (multi-stall) và vạch lộ trình thông minh bằng OSRM.

### 1.3 Phạm vi dự án
Dự án giới hạn trong phạm vi xây dựng kiến trúc hệ thống phục vụ một chợ truyền thống mẫu (ví dụ: Chợ Bắc Mỹ An), với 4 đối tượng người dùng chính: Người mua, Tiểu thương, Shipper, và Quản trị viên (Admin). 

### 1.4 Giải pháp công nghệ đề xuất
Khác với các ứng dụng nhỏ lẻ, hệ thống DNGO được thiết kế bằng các công nghệ hiện đại nhất:
- **Frontend:** Phát triển bằng **Flutter** theo kiến trúc BLoC cho ứng dụng Mobile (Khách hàng & Tiểu thương & Shipper) và ứng dụng Web (Quản lý).
- **Backend:** Xây dựng bằng **FastAPI (Python)**, đảm bảo hiệu năng xử lý cao, dễ dàng tích hợp các model AI. 
- **AI & Data:** Sử dụng Large Language Models (như Qwen qua Ollama) với kỹ thuật RAG (Retrieval-Augmented Generation) để đưa ra tư vấn ẩm thực.
- **Routing:** Tích hợp **OSRM** (Open Source Routing Machine) thay cho Google Maps nhằm tối ưu chi phí và tự chủ công nghệ bản đồ.

### 1.9 Preview Cap 2: Kế thừa và cải tiến
Dự án DNGO hiện tại là sự nâng cấp đột phá từ nền tảng nghiên cứu kinh doanh của học phần Capstone 2 (Quản trị dự án TMĐT).
- **Phân tích từ Cap 2:** Bản báo cáo Cap 2 đã xây dựng xuất sắc khung nghiên cứu Business Case (BRD, SRS), vạch ra rõ lộ trình trải nghiệm (Customer Journey) của người mua và người bán. Tuy nhiên, giới hạn của Cap 2 chỉ dừng ở mức *Prototype giao diện* (Figma) và các kiến trúc tĩnh. 
- **Hạn chế của mô hình cũ:** Mô hình Cap 2 chưa có phương án xử lý điều phối đơn hàng phức tạp (khách mua từ nhiều sạp cùng lúc) và quy trình dối soát tiền hàng cho tiểu thương còn gặp nhiều bất cập nếu phụ thuộc hoàn toàn vào cổng thanh toán ngoài.
- **Cải tiến ở dự án hiện tại:** 
  1. **Thực thi toàn bộ kiến trúc:** Đưa ứng dụng từ bản vẽ vào code thực tế (Production-ready) với FastAPI và Flutter.
  2. **Giải pháp gom đơn & Shipper nội bộ:** Xây dựng riêng một ứng dụng `dngo_shipper_app` cùng thuật toán tối ưu hóa đa điểm dừng (OSRM).
  3. **Tích hợp "Ví thanh toán":** Đây là tính năng hoàn toàn mới bổ sung so với Cap 2. Để giải quyết dòng tiền nhanh gọn, hệ thống cung cấp "Ví điện tử nội bộ" cho cả Người mua và Người bán, cho phép tiền chuyển trực tiếp vào ví người bán ngay khi hoàn tất giao dịch, giảm phí trung gian và đẩy nhanh chu kỳ quay vòng vốn của tiểu thương.

---

## CHƯƠNG 2: CƠ SỞ LÝ THUYẾT VÀ CÔNG NGHỆ ÁP DỤNG

### 2.1 Front-end: Flutter và BLoC Pattern
- **Flutter:** Là UI Toolkit của Google sử dụng ngôn ngữ Dart. Flutter được chọn nhờ khả năng build đa nền tảng (Android, iOS, Web) từ một codebase duy nhất. Điều này giúp dự án tiết kiệm 50% thời gian phát triển so với native.
- **BLoC (Business Logic Component):** Kiến trúc tách biệt rõ ràng giữa UI và Logic. BLoC sử dụng Streams và Sinks, giúp trạng thái giao diện (ví dụ: giỏ hàng, thông báo ví tiền) cập nhật mượt mà theo thời gian thực mà không làm nghẽn luồng chính.

### 2.2 Back-end: FastAPI, PostgreSQL, và Redis
- **FastAPI:** Nền tảng web hiện đại, hiệu năng cao viết bằng Python. FastAPI tự động gen ra tài liệu Swagger UI, xử lý bất đồng bộ (async/await) tốt, phù hợp với các request nặng từ AI và tính toán lộ trình.
- **PostgreSQL:** Hệ quản trị CSDL quan hệ mạnh mẽ, đảm bảo tính toàn vẹn dữ liệu (ACID) cho các thông tin quan trọng như "Giao dịch ví thanh toán", "Đơn hàng".
- **Redis:** Được sử dụng để caching (ví dụ: lưu trữ trạng thái rule thời gian cấm mua sau 19h00) nhằm giảm tải cho CSDL chính.

### 2.3 Mô hình AI và RAG (Retrieval-Augmented Generation)
- **Large Language Models (LLM):** Hệ thống không dùng ChatGPT API mà tự host model (ví dụ Qwen2) tối ưu cho tiếng Việt để gợi ý đồ ăn dựa vào LLM RAG.
- **RAG:** Giúp mô hình truy xuất dữ liệu từ CSDL món ăn cục bộ của hệ thống (Vector Database) trước khi sinh ra câu trả lời, đảm bảo nguyên liệu gợi ý thực sự có bán tại các sạp trong chợ.

### 2.4 Hệ thống định vị OSRM
Giới hạn tài chính không cho phép sử dụng Google Maps API với tần suất lớn. Khắc phục vấn đề này, DNGO tích hợp **OpenStreetMap (OSM)** và thuật toán **OSRM**. Nó giúp giải bài toán TSP (Traveling Salesperson Problem) để Shipper đi một vòng lô-gic nhất gom các mặt hàng khác nhau từ nhiều sạp rau, thịt trong chợ, sau đó giao định tuyến tới khách hàng.
