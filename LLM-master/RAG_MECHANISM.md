# Giải Thích Toàn Bộ Cơ Chế Chatbot RAG

Mục tiêu là trả lời 4 câu hỏi:

1. Khi app khởi động thì nó làm gì?
2. Khi gọi vào `/chat` thì request đi qua những bước nào?
3. Vector database được tạo ra và tìm kiếm ra sao?
4. Llama nhận cái gì để trả lời?

## 1. Nhìn tổng thể trong 10 giây

Hệ thống này có 4 khối chính:

1. `data_loader.py`: đọc CSV, ghép dữ liệu, tra cứu món ăn.
2. `intent_detector.py`: đoán người dùng đang muốn làm gì.
3. `vector_store.py`: biến nội dung món ăn thành vector và tìm món gần nghĩa nhất.
4. `llama_service.py`: gửi câu hỏi + dữ liệu món ăn sang Llama để viết câu trả lời.

File đụng tất cả mọi thứ lại với nhau là `main.py`.

Nếu muốn hình dung ngắn gọn, luồng chạy là:

`Người dùng hỏi -> API nhận câu -> đoán intent -> tìm món phù hợp -> đưa món tìm được cho Llama -> Llama viết câu trả lời -> API trả về JSON`

## 2. Hệ thống có những dữ liệu gì?

API đang dùng các file CSV ở thư mục gốc của workspace:

1. `dishes_202603071642.csv`: thông tin món ăn gốc.
2. `rag_menu_final.csv`: chứa `rag_context`, `health_goal`, calories dùng cho RAG.
3. `recipes_202603071648.csv`: nguyên liệu liên quan tới món ăn.
4. `ingredients_202603071646.csv`: bảng nguyên liệu.
5. `dish_group_202603071641.csv`: nhóm món ăn.

Nói dễ hiểu:

1. `dishes` là thân món ăn.
2. `recipes` là món đồ cần để nấu.
3. `rag_menu_final` là đoạn mô tả để hệ thống semantic search hiểu món đó nói về cái gì.

## 3. Lúc app vừa bật lên, nó làm gì?

Phần này nằm trong `lifespan()` của `main.py`.

Khi FastAPI khởi động, nó chạy 3 việc lớn:

1. Load toàn bộ CSV vào RAM bằng `dl.get_data()`.
2. Build hoặc load lại FAISS index bằng `vs.build_index(data["rag"])`.
3. Kiểm tra Ollama và model `llama3.2` có sẵn không.

### 3.1 Load data

`data_loader.py` đọc các file CSV và ghép lại.

Bước quan trọng nhất là:

1. Lấy `rag_menu_final.csv`.
2. Bỏ các dòng không có `dish_id` hoặc `rag_context`.
3. Chỉ giữ các `dish_id` bắt đầu bằng `M`.
4. Bỏ trùng theo `dish_id`.
5. Merge vào bảng `dishes` để sau này mỗi món có thêm `rag_context`, `health_goal`, `kcal`.

Ý nghĩa:

1. Một món ăn sẽ có dữ liệu để hiển thị ra app.
2. Đồng thời cũng có dữ liệu text để làm RAG.

### 3.2 Build vector database

Khi app chạy lần đầu, `vector_store.py` sẽ:

1. Lấy cột `rag_context` của từng món.
2. Dùng model embedding `paraphrase-multilingual-MiniLM-L12-v2` để đổi text thành vector số.
3. Normalize vector.
4. Đưa tất cả vector vào FAISS index `IndexFlatIP`.
5. Lưu index xuống ở `.vector_cache/faiss.index`.
6. Lưu mapping vị trí index -> `dish_id` vào `.vector_cache/meta.pkl`.

Nếu đã có cache rồi thì lần sau nó không build lại, mà load lên luôn.

Nói như người thường:

1. Mỗi món ăn có một đoạn văn bản mô tả.
2. Hệ thống đổi mỗi đoạn văn bản thành một toạ độ trong không gian vector.
3. Những món nào gần nghĩa sẽ nằm gần nhau.

### 3.3 Kiểm tra Llama

App gọi `ollama.list()` để xem:

1. Ollama có đang chạy không?
2. Model `llama3.2` có được pull về máy chưa?

Nếu chưa có, `/chat` vẫn có thể bị lỗi lúc gọi sinh câu trả lời.

## 4. Khi gọi vào `/chat`, request chạy như thế nào?

Đây là endpoint chính của hệ thống.

Body request có dạng:

```json
{
  "message": "Cho tôi xem các món cá hồi",
  "session_id": "abc-123",
  "history": [
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."}
  ]
}
```

Sau khi vào `/chat`, code làm đúng theo thứ tự sau.

### Bước 1: Tạo `session_id`

Nếu client không gửi `session_id`, server tự tạo một UUID mới.

Mục đích:

1. Đánh dấu phiên chat.
2. Trả lại cho client dùng tiếp.

Lưu ý: trong code hiện tại, `session_id` chỉ được trả về, chưa thấy có bộ nhớ server-side lưu hội thoại theo session.

### Bước 2: Đoán intent

API gọi `detect_intent(req.message)`.

File `intent_detector.py` đang đoán intent bằng rule-based, tức là:

1. Đưa câu hỏi về chữ thường.
2. Duyệt từng nhóm từ khoá.
3. Gặp từ khoá nào trùng thì trả về intent đó ngay.

Ví dụ:

1. Có `xin chào` -> `greeting`
2. Có `tăng cân`, `giảm cân` -> `health_advice`
3. Có `15 phút`, `nấu nhanh` -> `filter_quick`
4. Có `chay`, `vegan` -> `diet_type`
5. Có `thịt bò`, `cá hồi` -> `search_ingredient`
6. Không khớp thì fallback thành `search_general`

Điều quan trọng:

Intent detector này không dùng AI, không dùng model classifier. Nó chỉ là so khớp chuỗi đơn giản.

### Bước 3: Chọn cách tìm món

Sau khi có intent, API gọi `_get_dishes_for_message(message, intent)`.

Đây là cái nút rẽ nhánh của cả hệ thống.

#### Trường hợp A: `health_advice`

Code không vào FAISS ngay.

Nó sẽ:

1. Gọi `extract_health_goal(message)`.
2. Biến câu hỏi thành 1 trong 3 nhãn:
   - `Tăng cân / Năng lượng cao`
   - `Giảm cân / Ăn nhẹ`
   - `Dinh dưỡng cân bằng`
3. Gọi `dl.get_dishes_by_health_goal(...)`.

Tức là lúc này hệ thống đang filter dữ liệu theo cột `health_goal`, không phải semantic search.

#### Trường hợp B: `filter_quick`

Hệ thống:

1. Tách giới hạn thời gian, ví dụ `20 phút`.
2. Rút gọn keyword bằng `extract_keywords()`.
3. Gọi `dl.search_dishes(query=keywords, max_time=max_time, limit=8)`.

Tức là vẫn là search theo text + lọc theo thời gian nấu.

#### Trường hợp C: `diet_type`

Hệ thống làm mẹo đơn giản:

1. Thêm chữ `chay` vào query.
2. Gọi `search_dishes()`.

Ví dụ: user hỏi `món vegan dễ làm` -> query thành `chay vegan dễ làm`.

#### Trường hợp D: `greeting`

Không tìm món nào cả. Danh sách `dishes` sẽ rỗng.

#### Trường hợp E: Còn lại

Đây mới là nhánh RAG chính.

Hệ thống sẽ:

1. Gọi `_rag_dishes(message)`.
2. Trong đó gọi `vs.semantic_search(message, k=8)`.
3. Nhận về danh sách `dish_id`.
4. Đổi từng `dish_id` thành object món ăn đầy đủ bằng `dl.get_dish_by_id(...)`.

Nếu RAG không ra được món nào thì fallback sang keyword search:

1. Gọi `extract_keywords(message)`.
2. Gọi `_keyword_dishes(keywords)`.
3. Tức là `dl.search_dishes(query=keywords, limit=8)`.

## 5. Vector database tìm kiếm cụ thể ra sao?

Đây là phần quan trọng nhất nếu muốn hiểu RAG.

### 5.1 RAG ở đây không phức tạp như nhiều hệ thống lớn

Nó không có:

1. chunking tài liệu phức tạp
2. reranking
3. hybrid search BM25 + vector
4. metadata filtering nâng cao trong FAISS

Nó đang là một pipeline ngắn gọn:

1. Lấy 1 đoạn text `rag_context` cho mỗi món.
2. Embedding thành vector.
3. Đưa vào FAISS.
4. Embedding câu hỏi người dùng.
5. Tìm top `k` vector gần nhất.
6. Lấy `dish_id` ứng với vector đó.

### 5.2 `rag_context` là gì?

Có thể hiểu `rag_context` là phần mô tả tổng hợp của món ăn.

Nó là thứ để semantic search đọc và hiểu.

Thay vì tìm bằng đúng từ `cá hồi`, vector search có thể hiểu cả những câu kiểu:

1. `món nhiều đạm để tập gym`
2. `món ăn nhẹ cho bữa tối`
3. `món hợp cho người muốn tăng năng lượng`

Nếu `rag_context` được viết tốt, retrieval sẽ tốt hơn.

### 5.3 FAISS đang lưu cái gì?

FAISS index không lưu full JSON món ăn.

Nó chỉ lưu:

1. vector của mỗi `rag_context`
2. vị trí của vector trong index

Còn file `meta.pkl` lưu:

1. danh sách `dish_id`
2. thứ tự trùng với thứ tự vector trong index

Ví dụ để dễ hiểu:

1. vector thứ 0 -> `M0001`
2. vector thứ 1 -> `M0002`
3. vector thứ 2 -> `M0003`

Khi search, FAISS trả về vị trí, sau đó hệ thống mới đổi vị trí thành `dish_id`.

### 5.4 Tại sao dùng `IndexFlatIP`?

Code dùng `IndexFlatIP(dim)` và gọi `normalize_L2()` cho cả vector dữ liệu lẫn vector query.

Mục đích là để:

1. biến inner product thành gần giống cosine similarity
2. tìm những vector gần nghĩa nhất

Nói cho dễ hiểu:

1. Hai câu càng giống ý nhau thì vector càng hướng về cùng một phía.
2. FAISS sẽ ưu tiên những món có hướng vector gần với query.

### 5.5 Lúc user gửi 1 câu hỏi, retrieval làm gì?

Ví dụ user hỏi:

`Cho tôi xem các món cá hồi để nấu bữa tối`

Hệ thống làm như sau:

1. Dùng model embedding đổi cả câu hỏi thành 1 vector.
2. Normalize vector query.
3. Bảo FAISS tìm top 8 vector gần nhất trong index.
4. Nhận lại mảng vị trí `I`.
5. Map vị trí đó sang `dish_id` từ `_meta`.
6. Lấy từng món đầy đủ bằng `get_dish_by_id()`.

Kết quả cuối cùng là list `dishes` để đưa cho Llama và cũng trả về cho frontend.

## 6. `get_dish_by_id()` làm gì sau khi có kết quả vector?

Đây là bước "rút món thật" từ kết quả semantic search.

FAISS chỉ biết vector và vị trí. Để trả JSON cho app, hệ thống cần quay lại bảng dữ liệu.

`get_dish_by_id()` sẽ:

1. Tìm dòng có `dish_id` từ bảng `dishes` đã merge.
2. Gọi `build_dish_response(row)`.
3. Gắn thêm:
   - `dish_name`
   - `image_url`
   - `calories`
   - `health_goal`
   - `cooking_time`
   - `level`
   - `servings`
   - `recipe.ingredients`
   - `recipe.preparation`
   - `recipe.steps`
   - `recipe.serving_tips`
   - `buy_action`

Nói ngắn gọn:

1. FAISS tìm ra manh mối.
2. Data loader biến manh mối đó thành món ăn hoàn chỉnh.

## 7. Sau khi tìm được món, Llama được gọi như thế nào?

Lúc này API đã có `dishes`.

Nó gọi `llm.chat_with_llama(user_message, context_dishes, history)`.

Hàm này làm 3 việc:

1. Tạo `context_block` từ danh sách món.
2. Ghép `system prompt` + `history` + câu hỏi hiện tại.
3. Gọi `ollama.chat(model=MODEL, messages=messages)`.

### 7.1 `context_block` gồm gì?

Nó không đưa toàn bộ JSON món ăn vào Llama.

Nó chỉ đưa tối đa 6 món đầu, mỗi món gồm:

1. tên món
2. calories
3. cooking time
4. level
5. tối đa 8 nguyên liệu đầu
6. health goal

Lý do:

1. cho prompt gọn hơn
2. tránh quá dài
3. chỉ đưa các thông tin cần để viết câu trả lời

### 7.2 History được dùng ra sao?

Nếu client gửi `history`, hệ thống chỉ lấy tối đa 6 message gần nhất.

Tức là Llama có một chút bối cảnh hội thoại, nhưng không có memory dài hạn server-side.

### 7.3 System prompt ép Llama làm gì?

Prompt đặt Llama vào vai:

1. Trợ lý ẩm thực
2. Tư vấn món ăn
3. Gợi ý thực đơn
4. Hướng dẫn cách nấu
5. Khuyến khích mua hàng qua app

Và có luật:

1. trả lời bằng tiếng Việt
2. không được bịa đặt ngoài context
3. không có context phù hợp thì phải nói thật
4. trả lời gọn trong 150-250 từ

Nói thẳng ra:

1. Retrieval tìm sự thật.
2. Llama chỉ có nhiệm vụ diễn đạt sự thật đó cho dễ đọc.

## 8. JSON trả về từ `/chat` có gì?

Server trả lại:

```json
{
  "session_id": "...",
  "intent": "search_general",
  "reply": "...",
  "dishes": [...],
  "total_found": 8
}
```

Ý nghĩa:

1. `reply`: câu văn do Llama viết.
2. `dishes`: dữ liệu thật của món ăn để frontend hiện card, nút mua, công thức.
3. `intent`: cho biết request này đã đi vào nhánh nào.
4. `total_found`: số món tìm được.

Frontend không cần bóc tách câu văn của Llama để lấy thông tin món. Danh sách món đã có sẵn trong `dishes`.

## 9. Toàn bộ luồng `/chat` viết theo kiểu siêu dễ hiểu

Có thể đọc như sau:

1. User nhập câu hỏi.
2. API đọc câu hỏi.
3. API đoán xem user đang chào hỏi, muốn ăn nhanh, muốn giảm cân, hay đang tìm món tổng quát.
4. Nếu là bài toán đặc biệt thì lọc data trực tiếp.
5. Nếu là bài toán tìm món tổng quát thì đưa câu hỏi vào vector search.
6. Vector search tìm ra các món có nghĩa gần nhất.
7. Hệ thống lấy thông tin đầy đủ của các món đó.
8. Hệ thống đưa danh sách món cho Llama xem.
9. Llama viết một đoạn tư vấn dễ đọc, dễ dùng.
10. API trả về cả đoạn tư vấn lẫn danh sách món.

## 10. Sơ đồ luồng chạy

```text
Người dùng
   |
   v
POST /chat
   |
   v
detect_intent(message)
   |
   +--> greeting ------------> dishes = []
   |
   +--> health_advice -------> filter theo health_goal
   |
   +--> filter_quick --------> keyword search + lọc thời gian
   |
   +--> diet_type -----------> keyword search với từ "chay"
   |
   +--> mặc định -----------> semantic_search(message)
                                  |
                                  v
                              top dish_id
                                  |
                                  v
                          get_dish_by_id(dish_id)
                                  |
                                  v
                              dishes[] đầy đủ
                                  |
                                  v
                chat_with_llama(message, dishes, history)
                                  |
                                  v
                     reply + dishes + intent + total_found
```

## 11. Ví dụ thực tế để dễ nắm

### Ví dụ 1: `Cho tôi món ăn giảm cân`

Luồng chạy:

1. Intent detector thấy `giảm cân`.
2. Intent = `health_advice`.
3. API map sang `Giảm cân / Ăn nhẹ`.
4. API lọc các món có `health_goal` này.
5. Đưa các món lọc được cho Llama.
6. Llama viết lời tư vấn.

Ở đây không cần FAISS.

### Ví dụ 2: `Cho tôi xem các món cá thu để nấu tối nay`

Luồng chạy:

1. Intent detector có thể ra `search_ingredient`.
2. Trong `_get_dishes_for_message()`, intent này không có nhánh riêng.
3. Hệ thống rơi vào nhánh mặc định.
4. FAISS semantic search chạy trên cả câu hỏi.
5. Lấy top 8 món gần nghĩa nhất.
6. Llama dựa trên danh sách đó để trả lời.

Ở đây FAISS có tham gia.

### Ví dụ 3: `Món nào nấu trong 15 phút?`

Luồng chạy:

1. Intent = `filter_quick`.
2. `extract_time_limit()` rút ra `15`.
3. `search_dishes(..., max_time=15)` được gọi.
4. DataFrame bị lọc theo thời gian nấu.
5. Llama tổng hợp và trả lời.

Ở đây cũng không cần FAISS.

## 12. Điểm mạnh của thiết kế hiện tại

1. Đơn giản, dễ hiểu, dễ debug.
2. Khởi động xong là search nhanh vì đã có cache FAISS.
3. Tách rõ retrieval và generation.
4. Frontend nhận dữ liệu món ăn có cấu trúc rõ ràng, không phải mổ xẻ từ text của Llama.
5. Model embedding đa ngữ, phù hợp query tiếng Việt.

## 13. Giới hạn của hệ thống hiện tại

Phần này quan trọng, vì nó cho thấy vì sao đôi khi chatbot trả lời chưa thật sự thông minh.

### 13.1 Intent detector rất đơn giản

Nó chỉ so chuỗi keyword.

Hệ quả:

1. Câu nói vòng vo có thể bị đoán sai.
2. Nếu một câu có nhiều ý, nó sẽ trúng intent đầu tiên nó gặp.
3. Không có độ tự tin.

### 13.2 Không phải mọi request đều đi qua RAG

Nhiều nhánh đang dùng filter DataFrame trực tiếp.

Nghĩa là tên gọi `chatbot RAG` đúng, nhưng thực tế là hybrid:

1. một phần là rules + filter
2. một phần mới là vector retrieval

### 13.3 Chưa có reranking

FAISS trả top 8 là lấy thẳng.

Không có bước kiểm tra lại xem top nào hợp nhất theo từ khoá, metadata, hoặc model cross-encoder.

### 13.4 Context đưa vào Llama còn hạn chế

Mỗi món chỉ đưa tên, calories, thời gian, level, vài nguyên liệu.

Nếu user hỏi rất sâu về cách nấu, có thể Llama không có đủ context chi tiết, dù dữ liệu gốc trong DB có tồn tại.

### 13.5 Search keyword fallback còn thô

`search_dishes()` dùng `.str.contains()` trên `dish_name` và `rag_context`.

Nó không:

1. bỏ dấu tiếng Việt
2. chuẩn hoá từ đồng nghĩa
3. có scoring tốt

## 14. Hiểu đúng bản chất của hệ thống này

Nếu phải nói 1 câu cực ngắn gọn thì:

Đây là một chatbot tư vấn món ăn, trong đó Python chịu trách nhiệm tìm dữ liệu đúng, còn Llama chịu trách nhiệm nói lại cho dễ nghe.

Hãy tách vai trò ra cho rõ:

1. `data_loader.py`: người thủ kho dữ liệu
2. `intent_detector.py`: người đoán ý khách đang muốn gì
3. `vector_store.py`: người tìm món bằng ý nghĩa
4. `llama_service.py`: người nói chuyện đẹp và tự nhiên
5. `main.py`: người điều phối tất cả

## 15. Nếu một người mới vào repo, cần đọc file nào theo thứ tự?

Nên đọc theo thứ tự này:

1. `main.py`: để thấy đường đi của request
2. `intent_detector.py`: để thấy logic rẽ nhánh
3. `vector_store.py`: để hiểu semantic search
4. `data_loader.py`: để biết món ăn được ghép và trả về ra sao
5. `llama_service.py`: để biết Llama được feed cái gì

## 16. Chốt lại bằng 1 câu thật dễ hiểu

Hệ thống này không phải kiểu "hỏi LLM rồi nó tự nghĩ ra tất cả".

Nó làm đúng thứ tự sau:

1. tìm dữ liệu trước
2. chọn món trước
3. rồi mới cho LLM viết câu trả lời

Tức là:

`RAG này là: tìm trước, nói sau.`
