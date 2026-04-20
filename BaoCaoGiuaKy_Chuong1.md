# TRƯỜNG ĐẠI HỌC KINH TẾ – ĐẠI HỌC ĐÀ NẴNG
# KHOA THƯƠNG MẠI ĐIỆN TỬ

---

# BÁO CÁO GIỮA KỲ
## XÂY DỰNG ỨNG DỤNG THƯƠNG MẠI ĐIỆN TỬ DNGO – CHỢ ONLINE TÍCH HỢP AI GỢI Ý MÓN ĂN VÀ NGUYÊN VẬT LIỆU

**GVHD:** TS. Trương Hồng Tuấn  
**Học phần:** Thực Hành Dự Án Thương Mại Điện Tử  
**Nhóm:** PROA  
**Lớp:** 48K22.1 + 48K22.2  
**Thành viên:**  
- Phạm Vĩnh Tường (48K22.2)  
- Nguyễn Ngọc Phương Nhi (48K22.2)  
- Phạm Thị Quỳnh Như (48K22.1)  

---

*Đà Nẵng, tháng 4 năm 2026*

---

## MỤC LỤC

- [CHƯƠNG 1: TỔNG QUAN DỰ ÁN](#chương-1-tổng-quan-dự-án)
  - [1.1 Giới thiệu chung về dự án](#11-giới-thiệu-chung-về-dự-án)
  - [1.2 Sứ mệnh (Mission)](#12-sứ-mệnh-mission)
  - [1.3 Tầm nhìn (Vision)](#13-tầm-nhìn-vision)
  - [1.4 Giá trị cốt lõi (Core Values)](#14-giá-trị-cốt-lõi-core-values)
  - [1.5 Mục tiêu dự án](#15-mục-tiêu-dự-án)
  - [1.6 Phạm vi dự án](#16-phạm-vi-dự-án)
  - [1.7 Đối tượng người dùng mục tiêu](#17-đối-tượng-người-dùng-mục-tiêu)
  - [1.8 Thông tin dự án và thành viên](#18-thông-tin-dự-án-và-thành-viên)
  - [1.9 Preview Cap 2 – Kế thừa và cải tiến từ báo cáo trước](#19-preview-cap-2--kế-thừa-và-cải-tiến-từ-báo-cáo-trước)

---

# CHƯƠNG 1: TỔNG QUAN DỰ ÁN

## 1.1 Giới thiệu chung về dự án

**DNGo – Chợ Online** là một nền tảng thương mại điện tử ứng dụng trí tuệ nhân tạo (AI), được phát triển với mục tiêu số hóa hoạt động của chợ truyền thống và mang đến cho người tiêu dùng trải nghiệm mua sắm thực phẩm tươi sống tiện lợi, minh bạch và nhanh chóng.

Thông qua hệ thống AI gợi ý món ăn theo khẩu vị, thời tiết và nguyên liệu sẵn có, DNGo giúp người dùng lên ý tưởng bữa ăn, chọn nguyên liệu và đặt hàng trực tiếp từ các tiểu thương địa phương. Đặc biệt, DNGo kết nối với mạng lưới **shipper nội chợ** để đảm bảo giao hàng nhanh – đúng giá – đúng nguồn, giúp người mua yên tâm về chất lượng và người bán mở rộng kênh kinh doanh online.

Ra đời từ dự án của nhóm sinh viên Trường Đại học Kinh Tế – Đại học Đà Nẵng, DNGo hướng đến việc kết hợp giữa giá trị truyền thống và công nghệ hiện đại, tạo ra **hệ sinh thái chợ số thông minh**, góp phần nâng cao đời sống tiểu thương và hiện đại hóa hoạt động mua sắm của người dân đô thị.

So với giai đoạn nghiên cứu trước (Capstone 2 – học phần Quản trị dự án TMĐT), ứng dụng ở giai đoạn hiện tại đã được đưa vào **triển khai thực tế**: toàn bộ hệ thống được lập trình đầy đủ bằng Flutter và FastAPI, có khả năng deploy và vận hành thật sự trên thiết bị di động Android/iOS. Ngoài ra, dự án còn bổ sung thêm nhiều tính năng nâng cao so với bản thiết kế ban đầu, trong đó nổi bật nhất là:

- **Ứng dụng riêng cho Shipper** (`dngo_shipper_app`) với thuật toán định tuyến sử dụng OSRM (Open Source Routing Machine) thay thế Google Maps.
- **Hệ thống Ví điện tử nội bộ** (Payment Wallet) cho phép vận hành dòng tiền khép kín, minh bạch giữa người mua – tiểu thương – shipper mà không phụ thuộc hoàn toàn vào cổng thanh toán bên thứ ba.
- **Mô hình AI gợi ý thực đơn sử dụng RAG** (Retrieval-Augmented Generation) với LLM được self-host tại server riêng, đảm bảo hiệu năng và tính bảo mật dữ liệu người dùng.

---

## 1.2 Sứ mệnh (Mission)

> *"Kết nối chợ truyền thống với người tiêu dùng hiện đại thông qua công nghệ số, giúp việc đi chợ trở nên nhanh hơn, tiện hơn và đáng tin cậy hơn."*

DNGo cam kết đồng hành cùng cộng đồng tiểu thương trong quá trình chuyển đổi số, mang lại thu nhập bền vững, giảm chi phí trung gian, và tạo niềm tin mới giữa người bán – người mua – người giao hàng. Hệ sinh thái ứng dụng không chỉ đơn thuần là một kênh bán hàng trực tuyến, mà còn là **công cụ quản lý nghiệp vụ toàn diện** giúp tiểu thương chủ động điều hành gian hàng số của mình.

---

## 1.3 Tầm nhìn (Vision)

> *"Trở thành nền tảng thương mại điện tử hàng đầu Việt Nam trong lĩnh vực chợ truyền thống số hóa, góp phần định hình thói quen đi chợ thông minh và bền vững."*

DNGo hướng tới các cột mốc chiến lược trong vòng 3–5 năm tới:

- Mở rộng mô hình đến **50 chợ** tại Đà Nẵng, Thành phố Hồ Chí Minh, và Hà Nội.
- Trở thành ứng dụng quen thuộc của các **hộ gia đình Việt**, đặc biệt nhóm người nội trợ 25–45 tuổi.
- Xây dựng **mạng lưới tiểu thương và shipper nội chợ mạnh nhất** khu vực miền Trung.
- Tích hợp **AI dự báo nhu cầu** thực phẩm theo mùa vụ, giúp tiểu thương điều phối nguồn hàng hợp lý.

---

## 1.4 Giá trị cốt lõi (Core Values)

| Giá trị | Diễn giải |
|---------|-----------|
| **Tận tâm (Dedication)** | Mỗi đơn hàng là một cam kết về chất lượng và niềm tin. Nhóm phát triển luôn đặt trải nghiệm người dùng lên hàng đầu trong mọi quyết định thiết kế. |
| **Đổi mới (Innovation)** | Ứng dụng công nghệ AI thế hệ mới (LLM, RAG, Vector DB) để tạo ra trải nghiệm khác biệt và hiệu quả so với các ứng dụng thương mại thông thường. |
| **Kết nối (Connection)** | Liên kết chặt chẽ cộng đồng người mua, tiểu thương và shipper trong một hệ sinh thái thống nhất, xuyên suốt từ đặt hàng đến giao nhận thanh toán. |
| **Bền vững (Sustainability)** | Hỗ trợ sinh kế lâu dài cho tiểu thương, giảm lãng phí thực phẩm thông qua AI dự báo, và bảo vệ giá trị văn hóa chợ truyền thống Việt Nam. |
| **Minh bạch (Transparency)** | Mọi giao dịch tài chính qua Ví điện tử đều được ghi nhận tự động, sao kê rõ ràng, giúp người bán và người mua tin tưởng lẫn nhau. |

---

## 1.5 Mục tiêu dự án

### 1.5.1 Mục tiêu tổng quát

Dự án DNGo hướng đến việc **chuyển đổi số toàn diện hoạt động chợ truyền thống**, giúp người dân có thể "đi chợ online" thuận tiện, minh bạch và hiện đại, đồng thời tăng doanh thu và năng suất cho tiểu thương địa phương. Ở giai đoạn thực hành dự án hiện tại, nhóm tập trung vào việc **hoàn thiện sản phẩm có thể vận hành thực tế** (Production-ready), bao gồm:

- Xây dựng hệ thống Mobile App đa vai trò (Multi-role) trên nền tảng Flutter.
- Triển khai Backend API dựa trên FastAPI (Python) với kiến trúc RESTful.
- Tích hợp mô hình AI gợi ý thực đơn dựa trên kỹ thuật RAG với LLM tự host.
- Triển khai hệ thống Ví điện tử nội bộ, quản lý dòng tiền giữa các bên.
- Tích hợp thuật toán định tuyến OSRM cho Shipper để tối ưu hóa lộ trình giao hàng.

### 1.5.2 Mục tiêu cụ thể (SMART)

| Thành phần | Nội dung cụ thể |
|------------|----------------|
| **S – Specific** | Phát triển và triển khai ứng dụng DNGo hoàn chỉnh bao gồm: App Khách hàng/Seller (Done-demo), App Shipper (dngo_shipper_app), và Backend API (LLM-master), phục vụ vận hành thử nghiệm tại chợ Bắc Mỹ An. |
| **M – Measurable** | ≥ 90% các tính năng đã thiết kế trong SRS hoạt động ổn định; Thời gian phản hồi API ≤ 2 giây; Độ chính xác gợi ý AI ≥ 75%; Luồng thanh toán Ví không lỗi trong 100% kịch bản kiểm thử. |
| **A – Achievable** | Nhóm đã có nền tảng kỹ thuật từ các môn học trước, tham khảo code mẫu và tài liệu chính thức Flutter/FastAPI; Thời gian thực hiện phù hợp với khối lượng công việc. |
| **R – Relevant** | Dự án giải quyết trực tiếp nhu cầu thực của tiểu thương và người tiêu dùng tại Đà Nẵng; Phù hợp với chiến lược chuyển đổi số của thành phố theo Nghị quyết 05-NQ/TU (2023). |
| **T – Time-bound** | Hoàn thiện sản phẩm trong vòng học kỳ, với mốc demo giữa kỳ vào tháng 4/2026 và sản phẩm cuối kỳ vào tháng 6/2026. |

---

## 1.6 Phạm vi dự án

### 1.6.1 Trong phạm vi (In Scope)

**Phạm vi chức năng – Ứng dụng người mua (Buyer App):**
- Đăng ký / Đăng nhập bằng email và mật khẩu.
- Xem danh sách sản phẩm (nguyên liệu, thực phẩm tươi sống) theo từng gian hàng và từng chợ.
- Tìm kiếm sản phẩm, lọc theo danh mục và giá.
- Sử dụng AI Chat để nhận gợi ý món ăn, công thức, nguyên liệu cần mua.
- Thêm sản phẩm từ **nhiều sạp khác nhau** vào một giỏ hàng duy nhất (Multi-stall Cart).
- Đặt hàng và chọn phương thức thanh toán: **Ví điện tử nội bộ** hoặc **COD (tiền mặt khi nhận hàng)**.
- Theo dõi trạng thái đơn hàng theo thời gian thực.
- Xem lịch sử giao dịch và số dư Ví.
- Nhận thông báo push notification khi trạng thái đơn thay đổi.

**Phạm vi chức năng – Ứng dụng người bán (Seller App):**
- Đăng ký tài khoản và nộp hồ sơ đăng ký gian hàng (chờ duyệt từ Quản lý).
- Quản lý sản phẩm: thêm, sửa, xóa, cập nhật tồn kho và giá bán.
- Nhận và xác nhận đơn hàng từ khách.
- Xem thống kê doanh thu theo ngày, tuần, tháng.
- Quản lý Ví tiểu thương: xem số dư, lịch sử nhận tiền, yêu cầu rút tiền về tài khoản ngân hàng.
- Nhận thông báo khi có đơn hàng mới.

**Phạm vi chức năng – Ứng dụng Shipper:**
- Xem danh sách chuyến giao hàng được phân công.
- Xem lộ trình gom hàng tại nhiều sạp trong chợ dựa trên bản đồ tích hợp OSRM.
- Cập nhật trạng thái giao hàng từng bước (Đang lấy hàng → Đang giao → Đã giao).
- Upload hình ảnh xác nhận giao hàng thành công.
- Xem thu nhập giao hàng trong ngày / tuần.

**Phạm vi chức năng – Quản lý chợ (Market Management):**
- Đăng nhập và quản lý hồ sơ.
- Xem và duyệt/từ chối hồ sơ đăng ký gian hàng của tiểu thương.
- Xem sơ đồ bố trí gian hàng trong chợ.
- Cập nhật thông tin chợ (tên, địa chỉ, giờ hoạt động).

**Phạm vi kỹ thuật:**
- Mobile App đa vai trò xây dựng bằng **Flutter (Dart)**.
- Backend RESTful API xây dựng bằng **FastAPI (Python)**.
- Cơ sở dữ liệu **PostgreSQL** cho dữ liệu quan hệ.
- Mô hình AI sử dụng kỹ thuật **RAG + LLM** (Ollama – Qwen2.5).
- Tích hợp bản đồ và định tuyến **OpenStreetMap + OSRM**.
- Quản lý trạng thái Frontend theo kiến trúc **BLoC Pattern**.
- Push notification qua **Firebase Cloud Messaging (FCM)**.

### 1.6.2 Ngoài phạm vi (Out of Scope)

| Hạng mục | Lý do |
|----------|-------|
| Tích hợp cổng thanh toán thật (MoMo, ZaloPay, VNPay) | Giới hạn học phần; hệ thống Ví nội bộ thay thế chức năng này. |
| Phát hành chính thức lên CH Play / App Store | Chưa đủ điều kiện đăng ký tài khoản nhà phát triển trả phí. |
| Hệ thống quản trị tài chính và thuế | Nằm ngoài phạm vi môn học và yêu cầu pháp lý phức tạp. |
| Mở rộng ra ngoài thành phố Đà Nẵng | Kế hoạch phát triển giai đoạn tiếp theo (sau khi hoàn chỉnh pilot tại Đà Nẵng). |
| Hỗ trợ ngôn ngữ đa quốc gia (i18n) | Không nằm trong yêu cầu tối thiểu của học phần. |

---

## 1.7 Đối tượng người dùng mục tiêu

### 1.7.1 Người mua (Buyer)

**Bảng 1.7.1: Chân dung người mua mục tiêu**

| Thuộc tính | Mô tả |
|-----------|-------|
| **Tên đại diện** | Nguyễn Khánh Linh |
| **Độ tuổi** | 25–35 tuổi |
| **Nghề nghiệp** | Nhân viên văn phòng, công chức, người nội trợ có đi làm |
| **Địa điểm sinh sống** | Đà Nẵng, khu vực gần chợ truyền thống |
| **Mức thu nhập** | 8–15 triệu đồng/tháng |
| **Trình độ công nghệ** | Trung bình – khá; quen dùng ứng dụng đặt đồ ăn (ShopeeFood, GrabFood), thanh toán qua Momo |
| **Mục tiêu** | Nấu ăn tại nhà nhanh hơn mà không cần mất thời gian đi chợ; muốn có gợi ý món ăn hàng ngày; tiết kiệm chi phí so với đặt đồ ăn ngoài |
| **Hành vi** | Đặt hàng thực phẩm tươi sống 2–4 lần/tuần; thường đặt vào buổi sáng sớm hoặc trưa; thích hàng có nguồn gốc rõ ràng |
| **Nỗi đau (Pain Points)** | Tốn thời gian đi chợ, đặc biệt giờ cao điểm hoặc thời tiết xấu; không biết nấu món gì; dịch vụ giao hàng siêu thị chậm và đắt; lo ngại hàng online không tươi |
| **Nhu cầu chính** | App dễ dùng, giao hàng nhanh trong ngày, giá thật của chợ, có gợi ý món ăn thông minh |

### 1.7.2 Người bán – Tiểu thương (Seller)

**Bảng 1.7.2: Chân dung người bán mục tiêu**

| Thuộc tính | Mô tả |
|-----------|-------|
| **Tên đại diện** | Nguyễn Thị Lan |
| **Độ tuổi** | 35–55 tuổi |
| **Nghề nghiệp** | Tiểu thương bán rau củ, thịt cá, gia vị tại chợ truyền thống |
| **Kinh nghiệm** | 10–20 năm buôn bán tại chợ |
| **Mức thu nhập** | 300.000 – 1.000.000 đồng/ngày (tùy mùa và khách) |
| **Trình độ công nghệ** | Cơ bản; biết dùng Zalo, Facebook, chụp ảnh sản phẩm nhưng chưa quen ứng dụng quản lý bán hàng phức tạp |
| **Thiết bị** | Điện thoại Android trung bình thấp |
| **Mục tiêu** | Bán được nhiều hàng hơn; duy trì khách quen; có kênh bán hàng online đơn giản; không lo bị bom hàng |
| **Nỗi đau (Pain Points)** | Lượng khách đến chợ giảm do siêu thị, ứng dụng lớn cạnh tranh; không có kênh online riêng; lo sợ phức tạp khi dùng app; không có shipper giao hàng |
| **Nhu cầu chính** | App bán hàng đơn giản, thông báo đơn mới rõ ràng, có shipper nội chợ hỗ trợ, ví thu tiền tự động tránh rủi ro tiền mặt |

### 1.7.3 Shipper (Người giao hàng nội chợ)

**Bảng 1.7.3: Chân dung Shipper**

| Thuộc tính | Mô tả |
|-----------|-------|
| **Độ tuổi** | 20–40 tuổi, chủ yếu nam giới |
| **Đặc điểm** | Người quen với địa hình chợ, có phương tiện cá nhân (xe máy) |
| **Mục tiêu** | Nhận được nhiều chuyến giao hàng mỗi ngày, thu nhập ổn định từ phí vận chuyển |
| **Nhu cầu chính** | App chỉ đường rõ ràng, thông báo chuyến hàng mới nhanh, thanh toán thu nhập minh bạch |

### 1.7.4 Quản lý chợ (Market Manager)

**Bảng 1.7.4: Chân dung Quản lý chợ**

| Thuộc tính | Mô tả |
|-----------|-------|
| **Vai trò** | Ban quản lý chợ truyền thống |
| **Mục tiêu** | Kiểm soát danh sách tiểu thương hoạt động trên nền tảng; đảm bảo chất lượng hàng hóa và uy tín chợ |
| **Nhu cầu chính** | Công cụ duyệt hồ sơ Seller nhanh, xem sơ đồ vị trí gian hàng, báo cáo hoạt động chợ |

---

## 1.8 Thông tin dự án và thành viên

### 1.8.1 Thông tin chung

| Hạng mục | Chi tiết |
|----------|---------|
| **Tên dự án** | Chợ Online Đà Nẵng – DNGo (Giai đoạn thực hành) |
| **Tên nhóm** | PROA |
| **Loại sản phẩm** | Mobile Application (Android/iOS) + Backend API |
| **Thời gian bắt đầu** | Tháng 9/2025 |
| **Thời gian dự kiến hoàn thành** | Tháng 6/2026 |
| **Thị trường mục tiêu** | Thành phố Đà Nẵng (Pilot: Chợ Bắc Mỹ An) |

### 1.8.2 Thành viên trong dự án

**Bảng 1.8.2: Phân chia công việc và đóng góp của thành viên**

| Tên | Lớp | Vai trò | Nhiệm vụ chính | Đóng góp |
|-----|-----|---------|---------------|----------|
| Phạm Vĩnh Tường | 48K22.2 | Leader / Backend Developer | Phân chia quản lý công việc; thiết kế và lập trình Backend API (FastAPI); tích hợp AI RAG; hỗ trợ Frontend; triển khai hệ thống ví điện tử | 100% |
| Nguyễn Ngọc Phương Nhi | 48K22.2 | Business Analyst / Frontend | Phân tích nghiệp vụ các vai trò người dùng; thiết kế Figma; lập trình Flutter (Buyer App); viết báo cáo và tài liệu dự án | 100% |
| Phạm Thị Quỳnh Như | 48K22.1 | Designer / Frontend | Thiết kế UI/UX; lập trình Flutter (Seller & Admin features); xây dựng các luồng chức năng trên App; hoàn thiện báo cáo | 100% |

---

## 1.9 Preview Cap 2 – Kế thừa và cải tiến từ báo cáo trước

### 1.9.1 Bối cảnh kế thừa

Dự án **DNGO – Chợ Online** trong giai đoạn hiện tại được phát triển **trực tiếp từ kết quả nghiên cứu** của học phần Quản trị Dự án Thương mại Điện tử (Cap 2). Trong học phần đó, nhóm PROA đã xây dựng một bản **báo cáo toàn văn** rất chi tiết bao gồm:

- **Phần A – Tổng quan dự án:** Project Charter, Target Audience Profiles, Customer Journey Map của người mua và người bán.
- **Phần B – Business Case:** Phân tích bối cảnh thị trường, thực trạng chợ truyền thống tại Đà Nẵng, đối thủ cạnh tranh (ShopeeFood, GrabMart, Danamart.vn), phân tích khả thi (Operational, Technical, Economic, Legal), ma trận đánh giá lựa chọn công nghệ.
- **Phần C – BRD (Business Requirement Document):** Yêu cầu nghiệp vụ của 5 vai trò người dùng.
- **Phần D – SRS (Software Requirement Specification):** Đặc tả use case chi tiết cho 30+ luồng tính năng.
- **Phần E – System Design:** BPMN tổng thể, DFD cấp 0, DFD cấp 1 cho 7 luồng nghiệp vụ, ERD với 21 thực thể.
- **Phần F – Deployment:** Màn hình giao diện prototype của tất cả các vai trò.
- **Phần G – Project Management:** WBS, Gantt Chart, PERT Chart, Quản lý rủi ro, Quản lý chi phí.

Đây là nền tảng phân tích nghiệp vụ **hoàn chỉnh và khoa học** mà nhóm tích hợp trực tiếp vào giai đoạn lập trình thực tế hiện tại.

### 1.9.2 Những gì Cap 2 đã thiết lập tốt

Từ báo cáo Cap 2, nhóm kế thừa các nền tảng quan trọng sau:

**a) Cấu trúc nghiệp vụ 5 vai trò rõ ràng:**

Hệ thống gồm 5 tác nhân chính: **Người mua (Buyer)**, **Người bán (Seller)**, **Shipper**, **Quản lý chợ (Market Manager)** và **Admin**. Mỗi vai trò có luồng nghiệp vụ độc lập và được ánh xạ thành màn hình giao diện và API endpoint riêng biệt trong giai đoạn lập trình.

**b) Mô hình dữ liệu 21 thực thể:**

Cap 2 đã thiết kế chi tiết ERD gồm 21 thực thể từ `User`, `Stall`, `Product`, `Order`, `OrderItem`, `OrderBatch` cho đến `TimeFrame` (khung giờ bán), `Review` (đánh giá), `MarketMap` (bản đồ chợ)... Tất cả được triển khai thực tế trong PostgreSQL ở giai đoạn lập trình hiện tại.

**c) Quy trình BPMN tổng thể:**

BPMN của Cap 2 mô tả toàn bộ quy trình mua bán từ Người mua → AI gợi ý → Giỏ hàng → Thanh toán → Tiểu thương xác nhận → Shipper gom hàng → Giao hàng. Quy trình này được lập trình lại chính xác thông qua các API endpoint và luồng trạng thái đơn hàng trong FastAPI.

**d) Phân tích lựa chọn công nghệ:**

Cap 2 đã thực hiện phân tích đa tiêu chí (Multi-criteria Analysis) để chọn Flutter và ExpressJS làm stack công nghệ. Ở giai đoạn thực hành, nhóm **nâng cấp Backend từ ExpressJS lên FastAPI (Python)** nhằm tận dụng khả năng tích hợp AI và xử lý async tốt hơn.

### 1.9.3 Những tồn tại của Cap 2 và cách thức cải tiến

Mặc dù Cap 2 là một báo cáo nghiên cứu xuất sắc, nhưng do giới hạn về thời gian (3 tháng, môn học), một số điểm chưa được giải quyết triệt để:

**Bảng 1.9.3: Bảng đối chiếu tồn tại Cap 2 và giải pháp giai đoạn thực hành**

| STT | Tồn tại từ Cap 2 | Giải pháp ở giai đoạn hiện tại |
|-----|-----------------|-------------------------------|
| 1 | Hệ thống thanh toán chỉ mô phỏng (COD là chủ yếu, ví điện tử chưa có backend thực tế) | **Triển khai Ví điện tử nội bộ (Payment Wallet)** với đầy đủ luồng nạp tiền, thanh toán, tự động đối soát sau giao hàng, rút tiền cho Seller |
| 2 | Shipper chỉ là vai trò mô tả trên giấy, chưa có App riêng | **Phát triển hoàn chỉnh `dngo_shipper_app`** với bản đồ OSRM, gom đơn đa sạp, cập nhật trạng thái theo thời gian thực |
| 3 | AI chỉ là Chatbot dùng API Gemini/OpenAI (phụ thuộc bên ngoài, tốn phí, rủi ro token) | **Self-host LLM (Ollama + Qwen2.5)** với kỹ thuật RAG và Vector Database, đảm bảo kiểm soát dữ liệu và không tốn phí API theo token |
| 4 | Không giải quyết bài toán gom đơn từ nhiều sạp cùng một chuyến giao | **Thuật toán tối ưu gom đơn đa điểm dừng (Multi-pickup Routing)** sử dụng OSRM, giúp Shipper đi một vòng lấy hàng ở nhiều sạp trước khi giao cho khách |
| 5 | Backend sử dụng Node.js/ExpressJS chưa tối ưu cho tích hợp AI nặng | **Chuyển sang FastAPI (Python)** để tận dụng hệ sinh thái Python phong phú cho AI/ML, xử lý bất đồng bộ (async/await) hiệu quả hơn |
| 6 | Không có rule kiểm soát thời gian đặt hàng phù hợp với giờ chợ | **Tích hợp Time-based Rule**: Hệ thống chặn đặt hàng sau 19:00 (giờ đóng cửa chợ), trả về HTTP 400 với thông báo rõ ràng cho người dùng |

### 1.9.4 Tính năng mới hoàn toàn – Ví điện tử nội bộ (Payment Wallet)

Đây là **điểm khác biệt lớn nhất** giữa giai đoạn Cap 2 (thiết kế) và giai đoạn hiện tại (thực thi). Hệ thống Ví điện tử nội bộ được xây dựng với các đặc tính:

**4.1 Nguyên tắc vận hành:**
- Mỗi người dùng (Buyer, Seller, Shipper) được **tự động cấp Ví** khi đăng ký tài khoản.
- Buyer nạp tiền vào Ví bằng cách chuyển khoản ngân hàng (Admin xác nhận thủ công hoặc sau khi tích hợp webhook ngân hàng).
- Khi Buyer đặt hàng bằng Ví, số tiền tương ứng sẽ **bị khóa (Reserved)** – không thể tiêu vào đâu khác cho đến khi đơn hàng hoàn tất hoặc bị hủy.
- Khi Shipper xác nhận giao hàng thành công, hệ thống **tự động mở khóa** và phân bổ tiền đến từng Ví Seller tương ứng với phần hàng của họ trong đơn.
- Seller có thể **yêu cầu rút tiền** từ Ví về tài khoản ngân hàng bất kỳ lúc nào, Admin xử lý rút tiền.

**4.2 Lợi ích của Ví so với cổng thanh toán bên ngoài:**

| Tiêu chí | Cổng thanh toán bên ngoài (MoMo/ZaloPay) | Ví điện tử nội bộ DNGo |
|---------|----------------------------------------|------------------------|
| Chi phí giao dịch | 0.5–2% / giao dịch | **Miễn phí** trong hệ sinh thái |
| Thời gian tiền về Seller | 2–7 ngày làm việc | **Tức thì** khi Shipper giao thành công |
| Kiểm soát dòng tiền | Phụ thuộc đối tác bên ngoài | **Toàn quyền kiểm soát** trong hệ thống |
| Minh bạch lịch sử | Cần truy cập tài khoản đối tác | **Sao kê ngay trong App** |
| Rủi ro hoàn tiền (Refund) | Phức tạp, nhiều bước | **Đơn giản** – cộng thẳng lại Ví Buyer |

---

*[Hết Chương 1 – Tiếp theo: Chương 2: Cơ sở lý thuyết và công nghệ áp dụng]*
