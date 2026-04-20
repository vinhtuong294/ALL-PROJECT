# CHƯƠNG 2: CƠ SỞ LÝ THUYẾT VÀ CÔNG NGHỆ ÁP DỤNG

---

## MỤC LỤC CHƯƠNG 2

- [2.1 Thương mại điện tử và xu hướng số hóa chợ truyền thống](#21-thương-mại-điện-tử-và-xu-hướng-số-hóa-chợ-truyền-thống)
- [2.2 Kiến trúc ứng dụng di động – Flutter và BLoC Pattern](#22-kiến-trúc-ứng-dụng-di-động--flutter-và-bloc-pattern)
- [2.3 Backend API – FastAPI và RESTful Architecture](#23-backend-api--fastapi-và-restful-architecture)
- [2.4 Trí tuệ nhân tạo – LLM, RAG và Vector Database](#24-trí-tuệ-nhân-tạo--llm-rag-và-vector-database)
- [2.5 Hệ thống định tuyến – OSRM và OpenStreetMap](#25-hệ-thống-định-tuyến--osrm-và-openstreetmap)
- [2.6 Xác thực và bảo mật – JWT Authentication](#26-xác-thực-và-bảo-mật--jwt-authentication)
- [2.7 So sánh lựa chọn công nghệ](#27-so-sánh-lựa-chọn-công-nghệ)

---

## 2.1 Thương mại điện tử và xu hướng số hóa chợ truyền thống

### 2.1.1 Tổng quan về Thương mại điện tử (TMĐT)

Thương mại điện tử (E-commerce) là hình thức kinh doanh thực hiện các hoạt động mua bán hàng hóa và dịch vụ thông qua mạng Internet và các phương tiện điện tử. Theo Luật Giao dịch Điện tử Việt Nam (2023), TMĐT bao gồm tất cả các hoạt động từ quảng cáo, tiếp thị, đàm phán, ký kết hợp đồng đến thanh toán và giao nhận hàng hóa dựa trên nền tảng công nghệ số.

Thị trường TMĐT Việt Nam đang phát triển với tốc độ nhanh chóng. Theo **Báo cáo e-Conomy SEA 2024** của Google – Temasek – Bain, Việt Nam là một trong ba quốc gia có tốc độ tăng trưởng TMĐT nhanh nhất Đông Nam Á với mức tăng trưởng GMV (Gross Merchandise Value) đạt ~22%/năm. Đặc biệt, phân khúc **thực phẩm tươi sống và hàng tiêu dùng nhanh (FMCG)** đang là lĩnh vực tăng trưởng mạnh nhất, với 44% người dùng đã từng mua thực phẩm qua kênh online.

### 2.1.2 Mô hình O2O (Online-to-Offline) trong lĩnh vực thực phẩm

Mô hình **O2O (Online-to-Offline)** là xu hướng nổi bật trong TMĐT thực phẩm, kết hợp sức mạnh của nền tảng số với mạng lưới kinh doanh vật lý sẵn có. Trong mô hình O2O:

- Người dùng đặt hàng, chọn sản phẩm **Online** (qua App) nhưng hàng hóa thực tế đến từ các **Offline Store** (tiểu thương trong chợ truyền thống).
- Vận chuyển được thực hiện bởi đội ngũ shipper, kết hợp giữa quản lý offline (chợ, tiểu thương) và theo dõi online (App Shipper, thông báo cho khách).
- Thanh toán có thể thực hiện cả hai chiều: Online (ví điện tử, banking) hoặc Offline (COD).

DNGo là một **ứng dụng O2O điển hình**, mang trải nghiệm số hóa đến từng gian hàng nhỏ lẻ tại chợ truyền thống mà không làm thay đổi cơ bản hoạt động kinh doanh của tiểu thương.

### 2.1.3 Thực trạng số hóa chợ truyền thống tại Việt Nam

Theo thống kê của **Sở Công Thương Đà Nẵng (2024)**:
- Đà Nẵng có 65 chợ truyền thống với ~9.000 hộ tiểu thương đang hoạt động.
- Doanh thu trung bình mỗi chợ loại 1: 30–50 tỷ đồng/năm.
- **100%** giao dịch vẫn bằng tiền mặt, gần như không có thanh toán điện tử.
- Chỉ **15%** tiểu thương có tài khoản mạng xã hội để bán hàng, trong đó phần lớn không có hệ thống quản lý đơn hàng.

Những số liệu này cho thấy **khoảng trống thị trường cực kỳ lớn** mà DNGo có thể khai thác khi kết hợp giữa dịch vụ số và cơ sở hạ tầng chợ truyền thống sẵn có.

---

## 2.2 Kiến trúc ứng dụng di động – Flutter và BLoC Pattern

### 2.2.1 Giới thiệu Flutter

**Flutter** là UI toolkit đa nền tảng (Cross-platform) do Google phát triển và phát hành lần đầu vào năm 2018. Flutter sử dụng ngôn ngữ lập trình **Dart** và có khả năng build ứng dụng cho **Android, iOS, Web, Desktop** từ một codebase duy nhất.

**Điểm khác biệt cơ bản:** Không giống React Native (sử dụng bridge để giao tiếp với Native), Flutter **tự vẽ (render) toàn bộ giao diện** bằng engine đồ họa riêng (Skia/Impeller). Điều này giúp giao diện đạt tốc độ **60 FPS đến 120 FPS**, đồng nhất trên mọi thiết bị, không phụ thuộc vào thư viện UI của hệ điều hành.

**Bảng 2.2.1: So sánh Flutter với các Framework đa nền tảng khác**

| Tiêu chí | Flutter (Dart) | React Native (JS) | Kotlin + Swift (Native) |
|---------|--------------|-----------------|------------------------|
| Ngôn ngữ lập trình | Dart | JavaScript | Kotlin + Swift (2 ngôn ngữ) |
| Đồng nhất UI đa nền tảng | Rất cao (tự render) | Trung bình (phụ thuộc Bridge) | Không (khác nhau mỗi nền tảng) |
| Hiệu năng render | Rất cao (60–120 FPS) | Tốt (đôi khi lag ở Bridge) | Tốt nhất (Native) |
| Thời gian phát triển | Nhanh (1 codebase) | Nhanh (1 codebase) | Chậm (2 codebase riêng biệt) |
| Chi phí nhân sự | Thấp | Thấp | Cao (cần 2 team riêng) |
| Hỗ trợ AI/streaming UI | Tốt (StreamBuilder) | Tốt | Tốt |
| Phù hợp dự án DNGo | **✅ Phù hợp nhất** | ✅ Phù hợp | ❌ Không phù hợp (giới hạn tài nguyên) |

### 2.2.2 BLoC Pattern – Kiến trúc quản lý trạng thái

**BLoC (Business Logic Component)** là kiến trúc quản lý trạng thái (State Management) được Google giới thiệu đặc biệt cho Flutter. BLoC tách biệt hoàn toàn lớp UI (Presentation Layer) khỏi lớp Logic kinh doanh (Business Logic Layer), đảm bảo code có khả năng **test, maintain, mở rộng** tốt nhất.

**Nguyên tắc hoạt động:**
1. **Event (Sự kiện):** Người dùng thực hiện thao tác trên UI (ví dụ: bấm nút "Đặt hàng") → Một Event được bắn ra.
2. **BLoC (Xử lý):** BLoC nhận Event → Gọi Repository (tầng dữ liệu) → Xử lý business logic (kiểm tra số dư ví, tạo đơn...).
3. **State (Trạng thái):** BLoC phát ra một State mới → UI tự động rebuild theo State đó.

```
[UI Widget] → emit Event → [BLoC] → process → emit State → [UI Widget rebuilds]
                                       ↕
                                 [Repository]
                                       ↕
                                   [API / DB]
```

**Ứng dụng trong DNGo:**
- `WalletBloc` quản lý trạng thái số dư ví, lịch sử giao dịch.
- `CartBloc` quản lý giỏ hàng đa sạp, tính toán tổng tiền.
- `OrderBloc` theo dõi trạng thái đơn hàng theo thời gian thực.
- `AuthBloc` xử lý đăng nhập, lưu token, kiểm tra phiên làm việc.

### 2.2.3 Cấu trúc thư mục Feature-first

Dự án tổ chức code theo **Feature-first Architecture**, mỗi tính năng (Feature) là một thư mục độc lập gồm 3 lớp:
- `presentation/` – Các Widget UI, Page, và BLoC/Cubit.
- `domain/` – Entities và Use Cases (định nghĩa nghiệp vụ thuần túy).
- `data/` – Repositories và DataSources (giao tiếp với API và local storage).

---

## 2.3 Backend API – FastAPI và RESTful Architecture

### 2.3.1 Giới thiệu FastAPI

**FastAPI** là web framework hiện đại, hiệu năng cao viết bằng ngôn ngữ Python. FastAPI được phát triển bởi Sebastián Ramírez và ra mắt lần đầu năm 2018. Hiện tại, FastAPI là một trong những framework Python phổ biến nhất, được sử dụng rộng rãi bởi các công ty lớn như Netflix, Uber, Microsoft.

**Ưu điểm nổi bật của FastAPI:**

| Đặc điểm | Mô tả |
|---------|-------|
| **Tốc độ** | Hiệu năng ngang bằng NodeJS và Go nhờ sử dụng Starlette (ASGI) và Pydantic |
| **Bất đồng bộ (Async)** | Hỗ trợ `async/await` native, xử lý nhiều request đồng thời không blocking |
| **Tự động tài liệu** | Tự động sinh ra Swagger UI và ReDoc từ code, không cần viết thêm |
| **Validation** | Sử dụng Pydantic để validate dữ liệu đầu vào một cách chặt chẽ, giảm lỗi runtime |
| **Tích hợp AI dễ dàng** | Python là ngôn ngữ số 1 cho AI/ML, FastAPI cho phép nhúng model AI trực tiếp vào API |
| **Type hints** | Hỗ trợ Python type hints đầy đủ, giúp IDE gợi ý và phát hiện lỗi sớm |

### 2.3.2 RESTful API và HTTP Methods

Hệ thống sử dụng kiến trúc **RESTful API** (Representational State Transfer) với các quy ước chuẩn:

**Bảng 2.3.2: HTTP Methods và ý nghĩa trong DNGo**

| HTTP Method | Chức năng | Ví dụ endpoint trong DNGo |
|-------------|----------|--------------------------|
| `GET` | Lấy dữ liệu | `GET /api/products/` – Lấy danh sách sản phẩm |
| `POST` | Tạo mới dữ liệu | `POST /api/orders/` – Tạo đơn hàng mới |
| `PUT` | Cập nhật toàn bộ | `PUT /api/products/{id}` – Cập nhật sản phẩm |
| `PATCH` | Cập nhật một phần | `PATCH /api/orders/{id}/status` – Cập nhật trạng thái đơn |
| `DELETE` | Xóa dữ liệu | `DELETE /api/products/{id}` – Xóa sản phẩm |

### 2.3.3 Cơ sở dữ liệu PostgreSQL

**PostgreSQL** là hệ quản trị cơ sở dữ liệu quan hệ (RDBMS) mã nguồn mở, mạnh mẽ với hơn 35 năm phát triển. DNGo chọn PostgreSQL vì:

- **ACID Compliance:** Đảm bảo tính toàn vẹn dữ liệu tuyệt đối trong các giao dịch tài chính (Ví điện tử) – không thể bị mất tiền giữa chừng do lỗi hệ thống.
- **PGCrypto:** Hỗ trợ mã hóa mật khẩu và dữ liệu nhạy cảm ngay tại tầng database.
- **JSONB:** Hỗ trợ lưu trữ dữ liệu JSON nhanh cho các trường linh hoạt (metadata sản phẩm, địa chỉ giao hàng).
- **Full-text Search:** Tính năng tìm kiếm văn bản tích hợp sẵn, hỗ trợ tìm kiếm sản phẩm không cần cài thêm công cụ.

---

## 2.4 Trí tuệ nhân tạo – LLM, RAG và Vector Database

### 2.4.1 Large Language Models (LLM)

**Large Language Model (LLM)** là các mô hình ngôn ngữ lớn được huấn luyện trên lượng dữ liệu văn bản khổng lồ, có khả năng hiểu và sinh ra ngôn ngữ tự nhiên giống con người. LLM là nền tảng công nghệ của các sản phẩm như ChatGPT (OpenAI), Gemini (Google), Claude (Anthropic).

Trong dự án DNGo, nhóm sử dụng mô hình **Qwen2.5** (phát triển bởi Alibaba Cloud) thông qua nền tảng **Ollama** – một công cụ cho phép chạy LLM tại server riêng (self-hosted) mà không cần phụ thuộc vào API trả phí của bên thứ ba.

**Bảng 2.4.1: So sánh chiến lược sử dụng AI**

| Tiêu chí | API ngoài (Gemini/OpenAI) | Self-hosted LLM (Ollama + Qwen2.5) |
|---------|--------------------------|-----------------------------------|
| Chi phí | Tính theo token (~$0.01–0.06/1K token) | **Miễn phí** (chi phí chỉ là server GPU) |
| Kiểm soát dữ liệu | Dữ liệu gửi lên server của bên thứ 3 | **Dữ liệu ở lại server nội bộ** |
| Tùy chỉnh | Hạn chế | **Tùy chỉnh prompt, fine-tune** |
| Phụ thuộc mạng | Cao (không có mạng = không dùng được) | Thấp hơn (chạy local) |
| Thời gian phản hồi | ~0.5–2 giây | 2–8 giây (phụ thuộc GPU) |
| Phù hợp DNGo | Phù hợp prototype nhanh | **Phù hợp sản phẩm thực tế** |

### 2.4.2 RAG – Retrieval-Augmented Generation

**RAG (Retrieval-Augmented Generation)** là kỹ thuật tăng cường khả năng của LLM bằng cách cung cấp **thông tin ngữ cảnh liên quan** được truy xuất từ kho dữ liệu nội bộ trước khi yêu cầu mô hình sinh ra câu trả lời.

**Tại sao cần RAG thay vì hỏi LLM trực tiếp?**

- LLM được huấn luyện đến một mốc thời gian nhất định – không biết dữ liệu sản phẩm thực tế đang có tại gian hàng trong chợ.
- LLM có thể "hallucinate" (bịa đặt) thông tin sản phẩm, giá cả không có thật.
- RAG đảm bảo câu trả lời **luôn dựa trên dữ liệu thực** trong hệ thống, giảm tỉ lệ hallucination xuống còn ~5–15%.

**Luồng xử lý RAG trong DNGo:**

```
Bước 1: [Offline – Indexing]
    Công thức món ăn → Embedding Model → Vectors → FAISS/ChromaDB (Vector DB)

Bước 2: [Online – Query]
    Câu hỏi người dùng → Embedding → Semantic Search (Vector DB)
                                           ↓
                                   Top-K công thức liên quan
                                           ↓
    Prompt = "Question: " + câu hỏi + "\n\nContext: " + {Top-K công thức}
                                           ↓
                               Qwen2.5 sinh câu trả lời dựa trên Context
                                           ↓
                               Trả về cho người dùng
```

### 2.4.3 Vector Database và Semantic Search

**Vector Database** là loại cơ sở dữ liệu chuyên biệt lưu trữ và tìm kiếm dữ liệu dưới dạng vector số học (embedding vectors). Thay vì tìm kiếm theo từ khóa chính xác (keyword-based), tìm kiếm ngữ nghĩa (*semantic search*) trong Vector DB tìm ra các kết quả **tương đồng về ý nghĩa**, kể cả khi từ ngữ khác nhau.

**Ví dụ:** Người dùng hỏi *"Tôi có thịt bò và cà chua thì nấu gì?"* → Semantic Search tìm ra công thức *"Bò sốt cà chua"*, *"Bò nhúng giấm"*, *"Tomato beef stir-fry"* mặc dù từ khoá không khớp chính xác.

Trong DNGo, nhóm sử dụng thư viện **FAISS** (Facebook AI Similarity Search) – một thư viện tìm kiếm vector tốc độ cao, mã nguồn mở, chạy in-memory phù hợp với quy mô demo và pilot.

### 2.4.4 Tính toán dinh dưỡng – BMR và TDEE

Để cá nhân hóa gợi ý thực đơn theo nhu cầu sức khỏe của người dùng, hệ thống tích hợp bộ tính toán **BMR** (Basal Metabolic Rate – Trao đổi chất nền) và **TDEE** (Total Daily Energy Expenditure – Tổng năng lượng cần mỗi ngày).

**Công thức Mifflin-St Jeor (chuẩn WHO khuyến nghị):**

- **Nam:** `BMR = 10 × Cân_nặng(kg) + 6.25 × Chiều_cao(cm) - 5 × Tuổi + 5`
- **Nữ:** `BMR = 10 × Cân_nặng(kg) + 6.25 × Chiều_cao(cm) - 5 × Tuổi - 161`

**Hệ số hoạt động (Activity Factor) để ra TDEE:**

| Mức độ hoạt động | Hệ số | Mô tả |
|-----------------|-------|-------|
| Ít vận động | × 1.2 | Công việc văn phòng, ít tập thể dục |
| Nhẹ nhàng | × 1.375 | Tập nhẹ 1–3 ngày/tuần |
| Vừa phải | × 1.55 | Tập vừa 3–5 ngày/tuần |
| Năng động | × 1.725 | Tập nặng 6–7 ngày/tuần |
| Rất năng động | × 1.9 | Vận động viên chuyên nghiệp |

Khi người dùng nhập thông tin cá nhân (tuổi, giới tính, cân nặng, chiều cao), hệ thống tính TDEE, sau đó AI sẽ ưu tiên gợi ý các công thức có tổng Calorie phù hợp với mục tiêu (giảm cân, tăng cơ, duy trì) của họ.

---

## 2.5 Hệ thống định tuyến – OSRM và OpenStreetMap

### 2.5.1 Giới thiệu OpenStreetMap (OSM)

**OpenStreetMap (OSM)** là dự án bản đồ thế giới mã nguồn mở, được xây dựng và duy trì bởi cộng đồng tình nguyện viên từ năm 2004. OSM cung cấp dữ liệu bản đồ miễn phí, cho phép các ứng dụng sử dụng và tùy chỉnh không giới hạn, không tính phí theo lượt gọi API như Google Maps.

### 2.5.2 OSRM – Open Source Routing Machine

**OSRM (Open Source Routing Machine)** là engine tính toán đường đi hiệu năng cao, sử dụng dữ liệu từ OpenStreetMap. OSRM giải quyết bài toán **Shortest Path** (đường đi ngắn nhất) và **Multi-point Routing** (lộ trình qua nhiều điểm) trong thời gian thực (~milliseconds).

**Ứng dụng trong DNGo Shipper App:**

Khi một Shipper nhận được Assignment (chuyến giao hàng), đơn hàng đó có thể bao gồm sản phẩm từ nhiều sạp khác nhau trong chợ. Bài toán cần giải quyết:

> *"Shipper cần đến bao nhiêu sạp, theo thứ tự nào, để lấy đủ hàng cho khách trong thời gian ngắn nhất?"*

Đây là bài toán **TSP (Travelling Salesman Problem)** đã được đơn giản hóa. OSRM cung cấp endpoint `trip` giải bài toán này với thời gian phản hồi < 100ms cho 10–20 điểm dừng.

**Lộ trình hoàn chỉnh của Shipper:**
```
Điểm xuất phát → Sạp A (lấy rau) → Sạp B (lấy thịt cá) → Sạp C (lấy gia vị) → Nhà khách (giao hàng) → Kết thúc
```

### 2.5.3 So sánh OSRM với Google Maps Directions API

| Tiêu chí | Google Maps Directions API | OSRM (Self-hosted) |
|---------|--------------------------|-------------------|
| Chi phí | $5/1000 requests (Directions), $8/1000 (Optimization) | **Miễn phí** |
| Giới hạn request | Có (cần Pay-as-you-go) | **Không giới hạn** |
| Tốc độ phản hồi | ~100–500ms | ~5–50ms (tốt hơn) |
| Độ chính xác bản đồ VN | Rất cao | Cao (phụ thuộc dữ liệu OSM cộng đồng Việt Nam) |
| Tùy chỉnh | Hạn chế | **Tùy chỉnh tự do** |
| Phù hợp DNGo | Không phù hợp (chi phí cao) | **✅ Phù hợp nhất** |

---

## 2.6 Xác thực và bảo mật – JWT Authentication

### 2.6.1 JWT – JSON Web Token

**JWT (JSON Web Token)** là tiêu chuẩn mã hóa mở (RFC 7519) cho phép truyền thông tin xác thực giữa các bên dưới dạng một chuỗi JSON được ký điện tử. JWT được sử dụng rộng rãi trong các ứng dụng RESTful API thay thế cho Session-based Authentication truyền thống.

**Cấu trúc JWT:**
```
Header.Payload.Signature

Ví dụ:
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.   ← Header (thuật toán mã hóa)
eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6Ik~   ← Payload (user_id, role, exp...)
SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQ~   ← Signature (chữ ký xác thực)
```

**Quy trình xác thực trong DNGo:**
1. User đăng nhập → Server kiểm tra email/password → Tạo JWT Token (có hạn 24 giờ).
2. Flutter App lưu Token vào Secure Storage (không phải SharedPreferences để tránh lộ).
3. Mọi request tiếp theo đều gắn `Authorization: Bearer {token}` vào HTTP Header.
4. FastAPI middleware kiểm tra Token → Decode → Xác định User ID và Role → Cho phép truy cập resource.

### 2.6.2 Role-based Access Control (RBAC)

Hệ thống phân quyền dựa trên **Role** của người dùng:

**Bảng 2.6.2: Phân quyền theo vai trò trong hệ thống DNGo**

| Resource | Buyer | Seller | Shipper | Market Manager | Admin |
|---------|-------|--------|---------|----------------|-------|
| Xem sản phẩm | ✅ | ✅ | ✅ | ✅ | ✅ |
| Đặt hàng | ✅ | ❌ | ❌ | ❌ | ❌ |
| Quản lý sản phẩm | ❌ | ✅ (sạp riêng) | ❌ | ❌ | ✅ |
| Nhận chuyến giao | ❌ | ❌ | ✅ | ❌ | ✅ |
| Duyệt gian hàng | ❌ | ❌ | ❌ | ✅ | ✅ |
| Quản lý Ví toàn hệ thống | ❌ | ❌ | ❌ | ❌ | ✅ |
| Xem Ví của mình | ✅ | ✅ | ✅ | ❌ | ✅ |

---

## 2.7 So sánh lựa chọn công nghệ

Trong quá trình phát triển, nhóm đã cân nhắc và lựa chọn công nghệ dựa trên nhiều tiêu chí:

**Bảng 2.7.1: Điểm đánh giá chọn công nghệ Backend (Phương pháp AHP)**

| Tiêu chí | Trọng số | FastAPI (Python) | ExpressJS (NodeJS) | Django (Python) |
|---------|---------|----------------|------------------|-----------------|
| Tích hợp AI/ML | 5 | **5 (25)** | 3 (15) | 4 (20) |
| Hiệu năng Async | 4 | **5 (20)** | 5 (20) | 3 (12) |
| Tự động tài liệu API | 3 | **5 (15)** | 2 (6) | 4 (12) |
| Dễ học với nhóm | 3 | 4 (12) | **5 (15)** | 3 (9) |
| Hỗ trợ pydantic validation | 4 | **5 (20)** | 2 (8) | 3 (12) |
| Hệ sinh thái thư viện AI | 5 | **5 (25)** | 2 (10) | 4 (20) |
| **Tổng điểm** | | **117** | 74 | 85 |
| **Xếp hạng** | | **1 (Chọn)** | 3 | 2 |

→ **Kết quả lựa chọn:** FastAPI (Python) + PostgreSQL cho Backend.

**Bảng 2.7.2: Điểm đánh giá chọn công nghệ Frontend**

| Tiêu chí | Trọng số | Flutter (Dart) | React Native (JS) | Native (Kotlin+Swift) |
|---------|---------|--------------|-----------------|----------------------|
| Đồng nhất UI đa nền tảng | 5 | **5 (25)** | 4 (20) | 5 (25) |
| Hiệu năng render | 4 | **5 (20)** | 4 (16) | 5 (20) |
| Tốc độ phát triển | 5 | **5 (25)** | 4 (20) | 2 (10) |
| Chi phí nhân sự | 5 | **5 (25)** | 4 (20) | 2 (10) |
| Hỗ trợ real-time UI | 4 | **5 (20)** | 4 (16) | 4 (16) |
| **Tổng điểm** | | **115** | 92 | 81 |
| **Xếp hạng** | | **1 (Chọn)** | 2 | 3 |

→ **Kết quả lựa chọn:** Flutter (Dart) + BLoC Pattern cho Frontend.

---

*[Hết Chương 2 – Tiếp theo: Chương 3: Phân tích và Thiết kế hệ thống]*
