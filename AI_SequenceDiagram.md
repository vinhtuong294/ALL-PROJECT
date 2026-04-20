# Sơ đồ Tuần tự – Luồng AI Chat (DNGo)

Hệ thống AI bao gồm **2 luồng xử lý tách biệt**, được phân nhánh tự động dựa trên Intent phát hiện được từ câu hỏi của Buyer.

---

## Luồng 1: Chat AI Gợi Ý Món Ăn & Thực Đơn

```mermaid
sequenceDiagram
    actor Buyer as 👤 Người Mua (Buyer)
    participant App as 📱 Flutter App
    participant API as ⚙️ FastAPI<br/>(main.py)
    participant NLU as 🧠 NLU Engine<br/>(query_understanding.py)
    participant IntentDet as 🔍 Intent Detector<br/>(intent_detector.py)
    participant FAISS as 🗄️ FAISS Vector Store<br/>(vector_store.py)
    participant DB as 🐘 PostgreSQL<br/>(data_loader.py)
    participant LLM as 🤖 Qwen2.5<br/>(Ollama)

    Buyer->>App: Nhập câu hỏi<br/>"Tôi có 100k, nấu cơm gia đình thì mua gì?"
    App->>API: POST /chat<br/>{ message, session_id, history[] }

    Note over API, NLU: Bước 1: Phân tích câu hỏi (NLU)
    API->>NLU: understand_query(message)
    NLU->>IntentDet: extract_entities(message)<br/>FlashText Rule-based
    IntentDet-->>NLU: NLUResult {intent, included[], excluded[], entities}
    NLU-->>API: QueryResult {intent="family_group",<br/>search_query="gia đình", entities}

    Note over API, DB: Bước 2: Chiến lược tìm kiếm món ăn
    API->>API: _get_dishes_for_message(message, qr)
    
    alt intent = family_group / health_advice / diet_type
        API->>DB: suggest_menu(health_goal_ids, note_ids)
        DB-->>API: dishes[] (theo nhóm đối tượng)
    else intent = search_ingredient (có nguyên liệu cụ thể)
        API->>DB: search_dishes(ingredient=...)
        DB-->>API: dishes[] (theo tên nguyên liệu)
        Note right of API: Fallback: RAG nếu DB không match
    else intent = search_general / search_dish
        API->>FAISS: semantic_search(query, k=8)
        Note right of FAISS: Encode query bằng<br/>paraphrase-multilingual-MiniLM-L12-v2<br/>Tìm top-K bằng cosine similarity
        FAISS-->>API: dish_ids[] (top-K phù hợp nhất)
        API->>DB: get_dish_by_id(dish_id) cho từng ID
        DB-->>API: dishes[] đầy đủ thông tin + recipe
    end

    Note over API: Bước 3: Lọc nguyên liệu dị ứng
    API->>API: _apply_exclude_terms(dishes, qr.exclude_terms)

    Note over API, LLM: Bước 4: Sinh ngôn ngữ tự nhiên (LLM)
    API->>LLM: ollama.chat(model="qwen2.5:14b")<br/>{ system_prompt, history[-6:], user_content + RAG context }
    Note right of LLM: Context = danh sách món ăn<br/>kèm calories, công thức, nguyên liệu<br/>System prompt ép trả lời Tiếng Việt
    LLM-->>API: reply (chuỗi văn bản gợi ý món ăn)

    Note over API: Bước 5: Đóng gói response
    API-->>App: JSON { session_id, intent,<br/>reply, dishes[], query_analysis }
    App-->>Buyer: Hiển thị:<br/>💬 Gợi ý của AI<br/>📋 Danh sách món ăn (cards)<br/>🛒 Nút "Xem gian hàng bán nguyên liệu"
```

---

## Luồng 2: Chat AI Tìm Gian Hàng

```mermaid
sequenceDiagram
    actor Buyer as 👤 Người Mua (Buyer)
    participant App as 📱 Flutter App
    participant API as ⚙️ FastAPI<br/>(main.py)
    participant NLU as 🧠 NLU Engine<br/>(query_understanding.py)
    participant IntentDet as 🔍 Intent Detector<br/>(intent_detector.py)
    participant DB as 🐘 PostgreSQL<br/>(data_loader.py)
    participant LLM as 🤖 Qwen2.5<br/>(Ollama)

    Buyer->>App: Nhập câu hỏi<br/>"Gian hàng nào bán thịt bò tươi uy tín?"
    App->>API: POST /chat<br/>{ message, session_id, history[] }

    Note over API, NLU: Bước 1: Phân tích câu hỏi (NLU)
    API->>NLU: understand_query(message)
    NLU->>IntentDet: detect_intent(message)<br/>Ưu tiên kiểm tra SHOP_KEYWORDS trước
    Note right of IntentDet: "gian hàng" → intent = "search_shop"
    IntentDet-->>NLU: intent = "search_shop"
    NLU-->>API: QueryResult {intent="search_shop",<br/>entities={ingredient="thịt bò"}}

    Note over API, DB: Bước 2: Tách nhánh sang luồng Gian hàng
    API->>IntentDet: extract_shop_filters(message)
    Note right of IntentDet: Phát hiện "uy tín" → min_rating=4.0<br/>Mặc định price_sort="asc"
    IntentDet-->>API: filters {min_rating: 4.0, price_sort: "asc"}

    API->>DB: search_stalls(keyword="thịt bò",<br/>min_rating=4.0, price_sort="asc", limit=5)
    DB-->>API: shops[] (raw, chưa lọc)

    API->>API: _filter_shops_by_keyword(shops, "thịt bò")<br/>Exact match → Normalized match

    alt Không tìm thấy kết quả
        API->>DB: search_stalls(keyword=token đơn)
        DB-->>API: shops[] (kết quả fallback)
        alt Vẫn không tìm thấy
            API->>DB: get_stalls_by_ingredient_name("thịt bò")
            DB-->>API: shops[] từ bảng recipes
        end
    end

    Note over API, LLM: Bước 3: Sinh ngôn ngữ tự nhiên (LLM)
    API->>LLM: ollama.chat(model="qwen2.5:14b")<br/>{ system_prompt, user_content + shop context }
    Note right of LLM: Context = danh sách gian hàng<br/>kèm rating, địa điểm, hàng đang bán
    LLM-->>API: reply (giới thiệu gian hàng bằng TV)

    Note over API: Bước 4: Đóng gói response
    API-->>App: JSON { session_id, intent="search_shop",<br/>reply, shops[], dishes=[] }
    App-->>Buyer: Hiển thị:<br/>💬 Gợi ý của AI<br/>🏪 Danh sách gian hàng (cards: tên, rating, vị trí, hàng bán)
```

---

## Luồng 3: Buyer Chọn Món → Xem Gian Hàng Bán Nguyên Liệu

```mermaid
sequenceDiagram
    actor Buyer as 👤 Người Mua (Buyer)
    participant App as 📱 Flutter App
    participant API as ⚙️ FastAPI<br/>(main.py)
    participant DB as 🐘 PostgreSQL<br/>(data_loader.py)

    Note over Buyer, App: Buyer đã xem gợi ý món từ Luồng 1
    Buyer->>App: Bấm vào món ăn cụ thể<br/>(ví dụ: "Bò kho cà rốt")
    App->>API: GET /dishes/{dish_id}/stalls

    API->>DB: get_stalls_for_dish(dish_id)
    Note right of DB: JOIN dishes → recipes → stall_products<br/>Tìm gian hàng bán từng nguyên liệu
    DB-->>API: stalls[] { stall_name, rating,<br/>location, ingredients_available[] }

    API-->>App: JSON { dish_id, total_stalls, stalls[] }
    App-->>Buyer: Hiển thị danh sách gian hàng<br/>bán nguyên liệu của món vừa chọn
    Buyer->>App: Bấm "Thêm vào giỏ hàng"
    App->>App: Điều hướng sang luồng<br/>Đặt hàng thông thường
```

---

## Luồng 4: Tạo Thực Đơn Theo Mục Tiêu Sức Khoẻ (/menu/generate)

```mermaid
sequenceDiagram
    actor Buyer as 👤 Người Mua (Buyer)
    participant App as 📱 Flutter App
    participant API as ⚙️ FastAPI<br/>(main.py)
    participant DB as 🐘 PostgreSQL<br/>(data_loader.py)

    Buyer->>App: Chọn: Mục tiêu sức khoẻ="Giảm cân"<br/>Số ngày=3, Bữa/ngày=3<br/>Ghi chú: "Dị ứng: tôm"
    App->>API: POST /menu/generate<br/>{ days=3, meals_per_day=3,<br/>health_goal="Giảm cân", notes=["Dị ứng: tôm"] }

    Note over API: Bước 1: Xử lý dị ứng
    API->>API: Parse "Dị ứng: tôm" → exclude_terms=["tôm"]
    API->>API: Map health_goal → health_goal_ids=["DM16","DM52"]

    Note over API, DB: Bước 2: Gợi ý thực đơn
    API->>DB: suggest_menu(days=3, health_goal_ids,<br/>meals_per_day=3, exclude_terms=["tôm"])
    Note right of DB: Chọn món theo nhóm mục tiêu<br/>Lọc ngẫu nhiên đủ số bữa<br/>Bỏ các món chứa "tôm"
    DB-->>API: menu { day1: [bữa], day2: [bữa], day3: [bữa] }

    API-->>App: JSON { health_goal, days, meals_per_day,<br/>menu[], allergy_excluded=["tôm"] }
    App-->>Buyer: Hiển thị thực đơn 3 ngày<br/>theo bữa sáng/trưa/tối<br/>với thông tin calo, nguyên liệu mỗi món
```
