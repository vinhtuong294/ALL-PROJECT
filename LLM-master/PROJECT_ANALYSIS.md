# 🍜 LLM-master Project Analysis — Chi Tiết Toàn Bộ

## 📋 TÓM TẮT CHUNG
Project là một **Chatbot Ẩm Thực AI** tích hợp:
- **Backend**: FastAPI (Python) + PostgreSQL
- **LLM**: Qwen2.5:14b (qua Ollama)
- **Tìm kiếm**: FAISS vector search (semantic search trên 2473 món ăn)
- **Frontend**: Web (HTML/JS) + tương lai hỗ trợ Flutter/Mobile
- **Chức năng chính**: Tư vấn món ăn, gợi ý thực đơn, tìm gian hàng, hướng dẫn nấu

---

## 📁 CẤU TRÚC THƯ MỤC & MỤC ĐÍCH FILE

### Core Backend Files
| File | Mục đích |
|------|---------|
| **main.py** | FastAPI server chính. Định nghĩa 10+ endpoints cho chat, menu, gian hàng |
| **data_loader.py** | Load dữ liệu từ PostgreSQL + CSV. Hàm `suggest_menu()` tạo thực đơn theo mục tiêu sức khỏe |
| **vector_store.py** | FAISS semantic search. Build index từ 2473 món ăn. Tìm món liên quan |
| **llama_service.py** | Wrapper cho Ollama. Gọi Qwen2.5 để tạo phản hồi tiếng Việt |
| **query_understanding.py** | Rule-based NLU dùng FlashText. Parse intent + entities từ câu hỏi |
| **intent_detector.py** | Detect 14+ intent từ thông điệp người dùng (greeting, diet_type, search_shop...) |
| **db_config.py** | Cấu hình kết nối PostgreSQL |

### Supporting Files
| File | Mục đích |
|------|---------|
| **nlu/rule_engine.py** | FlashText rule extraction. Tìm included/excluded/diets từ câu hỏi |
| **rag_context_builder.py** | Build rag_context cho mỗi món ăn (từ dish_name, nguyên liệu, mục tiêu) |
| **rag_menu_final.csv** | CSV chứa 2473 món ăn + rag_context + health_goal (nguồn index) |

### Frontend Files
| File | Mục đích |
|------|---------|
| **chatbot_web/index.html** | Web UI chính. 3 tab: Chat / Thực đơn / Gian hàng |
| **chatbot_web/js/app.js** | Client logic. Gửi request đến backend, render menu + chat |
| **chatbot_web/listing.html** | Trang gian hàng (chưa phát triển đầy đủ) |
| **chatbot_web/css/style.css** | Styling UI |

### Config Files
| File | Mục đích |
|------|---------|
| **requirements.txt** | Dependencies Python (fastapi, ollama, faiss, pandas...) |
| **start.sh / start.bat** | Script khởi động server |
| **.env** | Biến môi trường (DB connection, API URL) |

---

## 🔄 FLOW DỮ LIỆU: Frontend → Backend → Response

### **Flow 1: Chat Hỏi Món Ăn** (Intent: search_dish, search_ingredient, health_advice)
```
┌─────────────────────────────────────────────────────────────────┐
│ 1. FRONTEND (app.js)                                            │
│    User nhập: "Cá mồi nấu gì ngon?"                            │
│    → POST /chat với payload:                                    │
│      {                                                          │
│        "message": "Cá mồi nấu gì ngon?",                       │
│        "session_id": "uuid",                                    │
│        "history": [...]                                        │
│      }                                                          │
└────────────────────────────┬──────────────────────────────────┘
                             │
┌────────────────────────────▼──────────────────────────────────┐
│ 2. BACKEND: main.py → /chat endpoint                          │
│    a) understand_query(message)                               │
│       → query_understanding.py → FlashText NLU                │
│       → Trả QueryResult:                                      │
│         - intent: "search_ingredient"                         │
│         - search_query: "cá mồi"                              │
│         - exclude_terms: []                                   │
│         - entities: {"ingredient": "cá mồi"}                 │
│                                                               │
│    b) _get_dishes_for_message(message, qr)                    │
│       → main.py                                               │
│       → Tìm kiếm theo ingredient entity:                      │
│          - Search dishes với "cá mồi"                         │
│          - Áp dụng exclude_terms filter                       │
│       → Trả ~8 món liên quan                                  │
│                                                               │
│    c) chat_with_llama(user_msg, dishes, history)             │
│       → llama_service.py                                      │
│       → Build context block từ 8 món                         │
│       → Gọi Qwen2.5 qua Ollama                              │
│       → LLM tạo phản hồi: "Dưới đây là những cách nấu..." │
└────────────────────────────┬──────────────────────────────────┘
                             │
┌────────────────────────────▼──────────────────────────────────┐
│ 3. FRONTEND nhận Response                                      │
│    {                                                          │
│      "intent": "search_ingredient",                           │
│      "reply": "Cá mồi rất ngon...",                           │
│      "dishes": [                                              │
│        {                                                      │
│          "dish_id": "M001",                                   │
│          "dish_name": "Canh chua cá mồi",                    │
│          "image_url": "...",                                  │
│          "recipe": {                                          │
│            "ingredients": ["cá mồi", "me", "hành..."],      │
│            "steps": "..."                                     │
│          },                                                   │
│          "buy_action": {"label": "🛒 Mua ngay"}              │
│        },                                                     │
│        ...                                                    │
│      ],                                                       │
│      "shops": []                                              │
│    }                                                          │
│                                                               │
│    → Render danh sách món + công thức + nút "Mua ngay"      │
└─────────────────────────────────────────────────────────────────┘
```

### **Flow 2: Tạo Thực Đơn & Xử Lý Allergen** (POST /menu/generate)
```
┌────────────────────────────────────────────────────────────────┐
│ 1. FRONTEND (generateMenu function)                            │
│    User chọn:                                                  │
│    - Mục tiêu: "Giảm cân"                                      │
│    - Số ngày: 3                                                │
│    - Bữa/ngày: 3                                               │
│    - Lưu ý: ["Món chay"]                                      │
│    - ALLERGEN_INGREDIENTS: "tôm, cua, tôm hùm"  ← (trường mới) │
│                                                               │
│    Nhập từ textarea:                                          │
│      allergyText = "tôm, cua"                                │
│      → allergies = ["tôm", "cua"]  (split + trim)            │
│                                                               │
│    → POST /menu/generate:                                    │
│      {                                                        │
│        "days": 3,                                             │
│        "meals_per_day": 3,                                    │
│        "health_goal": "Giảm cân",                             │
│        "notes": ["Món chay"],                                │
│        "allergen_ingredients": ["tôm", "cua"]  ← Gửi từ FE  │
│      }                                                        │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│ 2. BACKEND: main.py → /menu/generate endpoint                │
│                                                              │
│    a) Parse MenuGenerateRequest:                            │
│       - health_goal: "Giảm cân"                              │
│       - allergen_ingredients: ["tôm", "cua"]               │
│                                                              │
│    b) Map health_goal → dish_group_ids:                     │
│       HEALTH_GROUPS = {                                     │
│         "Giảm cân": ["DM16", "DM52"]                       │
│       }                                                      │
│       health_goal_ids = ["DM16", "DM52"]                   │
│                                                              │
│    c) Xử lý allergen_ingredients:                          │
│       allergy_exclude_terms = ["tôm", "cua"]              │
│       (CHƯA từ notes, đây là TOÀN BỘ dữ liệu dị ứng)      │
│                                                              │
│    d) Gọi data_loader.suggest_menu():                       │
│       suggest_menu(                                         │
│         days=3,                                             │
│         health_goal_ids=["DM16", "DM52"],                  │
│         note_ids=[],                                        │
│         meals_per_day=3,                                    │
│         exclude_terms=["tôm", "cua"]  ← KEY PARAM          │
│       )                                                      │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│ 3. BACKEND: data_loader.suggest_menu() ← HỌ LỌC DỊ ỨNG      │
│                                                              │
│    a) Xử lý exclude_terms = ["tôm", "cua"]:               │
│       lower_excl = ["tôm", "cua"]  (lowercase)             │
│                                                              │
│    b) BƯỚC 1: Lọc THEO TÊN MÓN                             │
│       Tìm tất cả dish WHERE dish_name chứa "tôm" hoặc "cua" │
│       VD: "Mực nướng", "Tôm hấp", "Cua rang"               │
│       → allergy_banned_ids = {"M245", "M890", ...}          │
│                                                              │
│    b) BƯỚC 2: Lọc THEO NGUYÊN LIỆU CHÍNH                  │
│       Tìm all recipes WHERE ingredient_name chứa "tôm"/"cua" │
│       VD: recipes.ingredient_name = "Tôm sú"                │
│       → Tìm dish_id của các công thức → allergy_banned_ids │
│       (Bỏ qua seasoning/flavor: "hạt nêm", "bột canh", "gia vị") │
│                                                              │
│    c) Query thực đơn:                                       │
│       SELECT dishes từ meal groups (sáng/trưa/tối)          │
│       + filter health_goal_ids (DM16, DM52)                 │
│       + EXCLUDE allergy_banned_ids                          │
│       + EXCLUDE used_dish_ids (không repeat)               │
│       + Filter vegetarian nếu cần                           │
│                                                              │
│    d) Trả về menu:                                          │
│       [                                                      │
│         {                                                    │
│           "day": 1,                                          │
│           "meals": [                                         │
│             {                                                │
│               "meal": "🌅 Sáng",                             │
│               "dish": {                                      │
│                 "dish_id": "M123",                          │
│                 "dish_name": "Canh rau cải",                │
│                 ...NOT contain: tôm, cua, mực              │
│               }                                              │
│             },                                               │
│             ...                                              │
│           ]                                                  │
│         },                                                    │
│         ...                                                   │
│       ]                                                      │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│ 4. BACKEND: main.py trả response                             │
│    {                                                         │
│      "health_goal": "Giảm cân",                              │
│      "days": 3,                                              │
│      "meals_per_day": 3,                                     │
│      "allergy_excluded": ["tôm", "cua"],                    │
│      "menu": [...]  ← thực đơn đã lọc                      │
│    }                                                         │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│ 5. FRONTEND: Render thực đơn                                 │
│    → 3 ngày, mỗi ngày 3 bữa                                 │
│    → Tất cả món KHÔNG chứa tôm, cua                         │
│    → Nút "🛒 Mua ngay" cho mỗi bữa                          │
└─────────────────────────────────────────────────────────────────┘
```

### **Flow 3: Hỏi Gian Hàng** (Intent: search_shop)
```
┌────────────────────────────────────────────┐
│ User: "Gian hàng bán hải sản tươi uy tín?" │
└────────────────────────────┬───────────────┘
                             │
        ┌────────────────────▼──────────────────────┐
        │ /chat endpoint → intent = "search_shop"  │
        │ → _get_shops_for_message()               │
        │ → dl.search_stalls(keyword="hải sản")    │
        │ → Tìm 5 gian hàng                        │
        │ → llama_service.build_shop_context_block │
        │ → LLM tạo giới thiệu gian hàng           │
        └────────────────────┬─────────────────────┘
                             │
        ┌────────────────────▼──────────────────────┐
        │ Response:                                 │
        │ {                                         │
        │   "shops": [                              │
        │     {                                     │
        │       "stall_name": "Chợ Hàng Mạc",      │
        │       "stall_location": "HN",            │
        │       "avr_rating": 4.8,                 │
        │       "goods": [                         │
        │         {"ingredient_name": "Tôm hùm",  │
        │          "price": 250000}                │
        │       ]                                   │
        │     }                                     │
        │   ],                                      │
        │   "reply": "Gian hàng uy tín..."         │
        │ }                                         │
        └──────────────────────────────────────────┘
```

---

## 🎯 CÁC HÀM CHÍNH TRONG BACKEND

### **1. `data_loader.suggest_menu()`**
**Vị trí**: [data_loader.py](data_loader.py#L481-L650)

**Mục đích**: Gợi ý thực đơn N ngày theo:
- Mục tiêu sức khỏe (health_goal_ids)
- Lưu ý bổ sung (note_ids) → "Món chay", "Miền Bắc"...
- **QUAN TRỌNG**: Loại bỏ nguyên liệu dị ứng (exclude_terms)

**Quy trình**:
```python
def suggest_menu(
    days: int = 1,
    health_goal_ids: list = None,        # VD: ["DM16", "DM52"] cho "Giảm cân"
    note_ids: list = None,               # VD: ["DM30"] cho "Món chay"
    meals_per_day: int = 3,              # Bữa/ngày
    exclude_terms: list = None,          # 🔴 ALLERGEN: ["tôm", "cua"]
) -> dict:
    # Bước 1: Xử lý vegetarian filter
    if "DM30" in note_ids:
        vegetarian_ids = set(dishes[is_vegetarian==True].dish_id)
    
    # Bước 2: XẬY DỰNG DANH SÁCH ALLERGEN BỊ LỌC 🔴
    allergy_banned_ids = set()
    for term in exclude_terms:
        # 2a. Lọc theo TÊN MÓN (word-boundary)
        #     VD: "Tôm hấp" → loại bỏ
        dish_q = "SELECT dish_id FROM dishes WHERE dish_name ~ '\\m{term}\\M'"
        allergy_banned_ids.update(results)
        
        # 2b. Lọc theo NGUYÊN LIỆU CHÍNH (recipes table)
        #     VD: ingredient_name = "Tôm sú" → loại bỏ
        ing_q = """
            SELECT DISTINCT dish_id FROM recipes
            WHERE ingredient_name ~ '\\m{term}\\M'
            AND NOT flavor_prefix  -- Skip "hạt nêm", "bột canh"
        """
        allergy_banned_ids.update(results)
    
    # Bước 3: Xây dựng thực đơn
    menu = []
    for day in range(1, days+1):
        meals = []
        for meal_label, meal_group_id in MEALS:
            # Query: SELECT dishes từ meal_group_id + health_goal_ids
            df = query(meal_group_id, health_goal_ids)
            # FILTER OUT allergy_banned_ids ← HỌ CHÍNH
            df = df[~df['dish_id'].isin(allergy_banned_ids)]
            # FILTER vegetarian
            if vegetarian_ids:
                df = df[df['dish_id'].isin(vegetarian_ids)]
            # FILTER used
            df = df[~df['dish_id'].isin(used_dish_ids)]
            
            # Pick một món
            dish = df.iloc[0]
            meals.append({"meal": meal_label, "dish": dish})
            used_dish_ids.add(dish['dish_id'])
        menu.append({"day": day, "meals": meals})
    
    return {"menu": menu, "allergy_excluded": exclude_terms}
```

**Chi tiết xử lý allergen**:
- **Tầng 1**: Lọc theo **tên món** (word-boundary regex)
  - Ví dụ: "Tôm hấp", "Cua rang" bị loại ngay nếu user chọn "tôm"
- **Tầng 2**: Lọc theo **nguyên liệu chính** trong recipes
  - Ví dụ: "Cơm tôm" → recipes.ingredient_name = "Tôm sú" → bị loại
- **Bước bỏ qua**: Không lọc **gia vị/phụ** (seasoning)
  - VD: "hạt nêm", "bột canh", "gia vị" KHÔNG loại dù user chọn "nêm"

---

### **2. `data_loader.search_dishes()`**
**Vị trí**: [data_loader.py](data_loader.py#L104-L180)

**Mục đích**: Tìm kiếm món theo nhiều tiêu chí

**Tham số**:
```python
def search_dishes(
    query: str = "",                    # Từ khóa (tên món, nguyên liệu)
    exclude_terms: Optional[List[str]] = None,  # 🔴 Allergen
    is_vegetarian: Optional[bool] = None,
    health_goal: str = "",
    max_calories: float = 0,
    min_calories: float = 0,
    level: str = "",
    max_time: int = 0,
    limit: int = 10,
) -> List[dict]:
```

**Xử lý exclude_terms**:
```python
for term in (exclude_terms or []):
    if term.strip():
        # Lọc ra các món TÊN chứa term
        df = df[~df['dish_name'].str.lower().str.contains(term.lower(), na=False)]
```
Đơn giản hơn `suggest_menu()` — chỉ lọc theo tên, không lọc nguyên liệu.

---

### **3. `main.generate_menu()` (Endpoint POST /menu/generate)**
**Vị trí**: [main.py](main.py#L730-L785)

**Mục đích**: API endpoint tiếp nhận allergen_ingredients từ frontend, sau đó gọi suggest_menu

**Request body**:
```python
class MenuGenerateRequest(BaseModel):
    days: int = 1
    meals_per_day: int = 2
    health_goal: str = "Cân bằng"
    notes: list = []
    allergen_ingredients: list = []  # 🔴 TRƯỜNG MỚI: ["tôm", "cua"]
```

**Logic xử lý allergen**:
```python
@app.post("/menu/generate")
def generate_menu(req: MenuGenerateRequest):
    # Bước 1: Map health_goal → group_ids
    health_goal_ids = HEALTH_GROUPS.get(req.health_goal, [])
    
    # Bước 2: Xử lý notes (VD: "Dị ứng: tôm, cá" → extract)
    allergy_exclude_terms = []
    for note in req.notes:
        if note.startswith("Dị ứng:"):
            raw_allergy = note[len("Dị ứng:"):].strip()
            terms = re.split(r"[,、;]", raw_allergy)
            allergy_exclude_terms.extend([t.strip() for t in terms])
    
    # Bước 3: THÊM allergen_ingredients từ request 🔴
    if hasattr(req, 'allergen_ingredients') and req.allergen_ingredients:
        allergen_items = [item.strip() for item in req.allergen_ingredients]
        allergy_exclude_terms.extend(allergen_items)
    
    # Bước 4: Gọi suggest_menu với đầy đủ allergen
    result = dl.suggest_menu(
        days=req.days,
        health_goal_ids=health_goal_ids,
        note_ids=note_ids,
        meals_per_day=req.meals_per_day,
        exclude_terms=allergy_exclude_terms,  # ← Toàn bộ dữ liệu allergen
    )
    
    return {
        "menu": result["menu"],
        "allergy_excluded": allergy_exclude_terms,
        ...
    }
```

---

### **4. `query_understanding.understand_query()`**
**Vị trí**: [query_understanding.py](query_understanding.py#L125-L160)

**Mục đích**: Parse câu hỏi bằng FlashText rule-based NLU

**Trả về**: QueryResult với:
- `intent`: "search_ingredient", "search_shop", "diet_type"...
- `search_query`: "cá mồi", "hải sản"...
- `exclude_terms`: Danh sách keyword bị loại (từ chat context, không phải allergen)
- `entities`: {"ingredient": "cá mồi", "diet": "chay"...}

**Flow**:
```python
def understand_query(message: str) -> QueryResult:
    # 1. NLU: extract entities bằng FlashText
    nlu = extract_entities(message)  # từ nlu/rule_engine.py
    
    # 2. Sanitize include/exclude
    clean_include, clean_exclude = sanitize_include_exclude(
        nlu.included, nlu.excluded
    )
    
    # 3. Build search_query
    search_query = build_search_query(intent, clean_include, entities)
    
    # 4. Trả QueryResult
    return QueryResult(
        intent=intent,
        search_query=search_query,
        exclude_terms=clean_exclude,  # ← Keyword exclusion từ chat
        entities=entities,
    )
```

---

### **5. `main._get_dishes_for_message()`**
**Vị trí**: [main.py](main.py#L245-L285)

**Mục đích**: Chọn strategy tìm kiếm món ăn phù hợp với intent

**Strategies**:
1. **search_ingredient**: Tìm theo nguyên liệu cụ thể
   - VD: "Cá mồi nấu gì" → tìm món có "cá mồi"
2. **search_shop**: Tìm gian hàng (trả shops, không dishes)
3. **diet_type**: Lọc vegetarian
4. **family_group**: "Món cho trẻ em" → gợi ý từ group DM47
5. **health_advice**: Lọc theo mục tiêu sức khỏe
6. **filter_quick**: Lọc theo thời gian nấu
7. **RAG fallback**: FAISS semantic search

**Xử lý exclude_terms từ chat context**:
```python
def _get_dishes_for_message(message: str, qr: qu.QueryResult) -> list[dict]:
    dishes = _raw_dishes_for_message(message, qr)
    print(f"[MAIN] raw: {len(dishes)} dishes  exclude_terms: {qr.exclude_terms}")
    
    # POST-FILTER: Loại bỏ món chứa exclude_terms
    filtered = _apply_exclude_terms(dishes, qr.exclude_terms)
    if len(filtered) != len(dishes):
        print(f"[MAIN] after exclude filter: {len(filtered)} dishes")
    return filtered
```

```python
def _apply_exclude_terms(dishes: list[dict], exclude_terms: list[str]) -> list[dict]:
    """Post-filter: loại bỏ món chứa bất kỳ term nào trong exclude_terms."""
    if not exclude_terms:
        return dishes
    lower_terms = [t.lower() for t in exclude_terms if t.strip()]
    return [
        d for d in dishes
        if not any(t in _build_dish_text_blob(d) for t in lower_terms)
    ]
```

---

### **6. `llama_service.chat_with_llama()`**
**Vị trí**: [llama_service.py](llama_service.py#L97-L150)

**Mục đích**: Gọi Qwen2.5 tạo phản hồi tiếng Việt

```python
def chat_with_llama(
    user_message: str,
    context_dishes: list[dict],
    context_shops: Optional[list[dict]] = None,
    history: Optional[list[dict]] = None,
    exclude_terms: Optional[list[str]] = None,
) -> str:
    # Build context blocks từ dishes/shops
    dish_context = build_context_block(context_dishes)
    shop_context = build_shop_context_block(context_shops) if context_shops else ""
    
    # Build system prompt
    system = SYSTEM_PROMPT
    
    # Nếu có exclude_terms, thêm note cho LLM
    if exclude_terms:
        banned = ", ".join(t for t in exclude_terms if t)
        system += f"\n⚠️ Loại bỏ: {banned}"
    
    # Call Ollama
    response = ollama.chat(
        model=MODEL,
        messages=[
            {"role": "system", "content": system},
            {"role": "user", "content": f"{user_message}\n\n{dish_context}\n{shop_context}"}
        ],
        stream=False,
    )
    
    return response.message.content
```

---

## 🔴 CÁCH ALLERGEN_INGREDIENTS ĐƯỢC GỬI & XỬ LÝ

### **Truyền dữ liệu: Frontend → Backend**

#### Frontend (app.js - [app.js#L111-L133](chatbot_web/js/app.js#L111-L133))
```javascript
async function generateMenu() {
  const goal = document.getElementById('menuGoal').value;  // "Giảm cân"
  const meals = parseInt(document.getElementById('menuMeals').value);  // 3
  const allergyText = document.getElementById('allergyInput').value.trim();  // "tôm, cua"
  
  // 🔴 Parse allergen từ textarea (comma-separated)
  const allergies = allergyText
    ? allergyText.split(',').map(a => a.trim()).filter(a => a)
    : [];
  // allergies = ["tôm", "cua"]
  
  const res = await fetch(`${API}/menu/generate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
      days: selectedDays,  // 1-7
      meals_per_day: meals,  // 2-3
      health_goal: goal,  // "Giảm cân"
      notes: selectedNotes,  // ["Món chay", ...]
      allergen_ingredients: allergies  // 🔴 ["tôm", "cua"]
    }),
  });
  const data = await res.json();
  renderMenu(data);
}
```

#### Frontend HTML (index.html - [index.html#L116-L119](chatbot_web/index.html#L116-L119))
```html
<label class="form-label">🚫 Dị ứng (ngăn cách bằng dấu phẩy)</label>
<textarea 
  class="form-textarea" 
  id="allergyInput" 
  placeholder="Ví dụ: tôm, cua, mực, hạt dẻ..."
  rows="2"
></textarea>
```

---

#### Backend (main.py - /menu/generate endpoint)

**Step 1: Request Model**
```python
class MenuGenerateRequest(BaseModel):
    days: int = 1
    meals_per_day: int = 2
    health_goal: str = "Cân bằng"
    notes: list = []
    allergen_ingredients: list = []  # 🔴 Nhận từ frontend
```

**Step 2: Xử lý allergen_ingredients**
```python
@app.post("/menu/generate")
def generate_menu(req: MenuGenerateRequest):
    # ...
    # Xây dựng danh sách exclude từ notes
    allergy_exclude_terms = []
    for note in req.notes:
        if note.startswith("Dị ứng:"):
            # Extract từ format note
            raw_allergy = note[len("Dị ứng:"):].strip()
            terms = re.split(r"[,、;]", raw_allergy)
            allergy_exclude_terms.extend([t.strip() for t in terms if t.strip()])
    
    # 🔴 THÊM allergen_ingredients từ request
    if hasattr(req, 'allergen_ingredients') and req.allergen_ingredients:
        allergen_items = [item.strip() for item in req.allergen_ingredients if item.strip()]
        allergy_exclude_terms.extend(allergen_items)
    
    print(f"[menu/generate] 🚫 Lọc dị ứng: {allergy_exclude_terms}")
    
    # Gọi suggest_menu với toàn bộ exclude_terms
    result = dl.suggest_menu(
        days=req.days,
        health_goal_ids=health_goal_ids,
        note_ids=note_ids,
        meals_per_day=req.meals_per_day,
        exclude_terms=allergy_exclude_terms,  # 🔴 Ở đây
    )
    
    return {
        "health_goal": req.health_goal,
        "days": req.days,
        "meals_per_day": req.meals_per_day,
        "menu": result["menu"],
        "allergy_excluded": allergy_exclude_terms,  # 🔴 Trả về cho frontend
    }
```

**Step 3: data_loader.suggest_menu() xử lý (chi tiết ở section trên)**

---

## 📊 FLOW TÓNG CỤC CHO ALLERGEN

```
[Frontend]
User input: "tôm, cua"
     ↓
allergyInput.value → split(',') → ["tôm", "cua"]
     ↓
POST /menu/generate với allergen_ingredients: ["tôm", "cua"]
     │
     ├─────────────────────────────────────────────────┐
     │                                                 │
[Backend main.py]                                      │
req.allergen_ingredients = ["tôm", "cua"]             │
     ↓                                                 │
allergy_exclude_terms.extend(allergen_ingredients)     │
     ↓                                                 │
Gọi dl.suggest_menu(exclude_terms=["tôm", "cua"])     │
     │                                                 │
[Backend data_loader.py]                              │
suggest_menu():                                        │
  - Loop qua exclude_terms                             │
  - Bước 1: Lọc dish_name ~ "tôm" hoặc ~ "cua"      │
  - Bước 2: Lọc recipes.ingredient_name ~ "tôm"/"cua" │
  - Kết quả: allergy_banned_ids = {M23, M45, ...}     │
     ↓                                                 │
  - Query dishes từ health_goal_ids                    │
  - EXCLUDE: allergy_banned_ids                        │
  - EXCLUDE: used_dish_ids                             │
  - EXCLUDE: vegetarian_ids nếu cần                    │
  - Chọn 1 món cho mỗi bữa                            │
     ↓                                                 │
  - Return menu đã lọc ✓ (không có tôm, cua)          │
     └─────────────────────────────────────────────────┘
     ↓
[Response to Frontend]
{
  "menu": [...],  // 0 tôm, 0 cua
  "allergy_excluded": ["tôm", "cua"],
  "message": "✅ Thực đơn không chứa tôm, cua"
}
     ↓
renderMenu(data)
  → Hiển thị 3 ngày, mỗi ngày 3 bữa
  → Tất cả món an toàn cho người dị ứng
```

---

## ✅ CHỈ SỬA & CẦN HOÀN THIỆN

### **❌ Vấn đề hiện tại**

| Vấn đề | Chi tiết | Ảnh hưởng |
|--------|---------|----------|
| **1. Allergen filter chưa hoàn hảo** | Chỉ lọc level-1 (tên) + level-2 (nguyên liệu chính). Không lọc allergen trong gia vị, nước xốt, hay ingredients phụ | Người dị ứng "tôm" vẫn có thể ăn "Cơm tôm" nếu tôm chỉ là gia vị nhỏ |
| **2. suggest_menu có logic "Tầng 2" (recipes) khá phức tạp** | Dùng regex `\m...\M` (word-boundary), fallback LIKE, bỏ qua flavor prefixes. Có thể miss một số cases | Rủi ro false negative (không lọc được một số nguyên liệu) |
| **3. Không xử lý "allergen gián tiếp"** | VD: User dị ứng "tôm", nhưng "Mực nướng với tương tôm" không bị loại | Người dị ứng có thể bị sốc (nếu tương tôm chứa xương tôm) |
| **4. Frontend UI chưa hoàn thiện** | Textarea dị ứng chỉ hỗ trợ input tự do, chưa có danh sách dropdown pre-defined | UX khó sử dụng |
| **5. Chat endpoint xử lý exclude_terms từ query_understanding** | exclude_terms từ chat context (VD: "không chứa tôm" → exclude="tôm") không được dùng với /chat → /dishes trực tiếp | Chat không lọc allergen từ conversation |
| **6. Không có caching allergen profile** | Mỗi request phải re-parse allergen_ingredients | Chậm nếu user tạo thực đơn nhiều lần |

---

### **✅ Cần sửa/hoàn thiện**

#### **Priority 1: Cần sửa ngay**

1. **Chat endpoint xử lý exclude_terms từ query_understanding**
   - Hiện tại: `/chat` tìm dishes nhưng KHÔNG áp dụng `qr.exclude_terms` từ query understanding
   - Cần sửa: Trong `_get_dishes_for_message()`, luôn gọi `_apply_exclude_terms(dishes, qr.exclude_terms)` ← đã có!
   - **Status**: ✅ Đã implement (xem dòng 245)

2. **Frontend: Thêm trường allergen_ingredients vào HTML**
   - Hiện tại: index.html có textarea `id="allergyInput"`
   - Cần xác nhận: Textarea này được send lên API không?
   - **Status**: ✅ Đã implement trong app.js (dòng 118-121)

3. **Xác minh endpoint /menu/generate nhận allergen_ingredients**
   - Hiện tại: main.py có `MenuGenerateRequest.allergen_ingredients`
   - Cần xác nhận: Endpoint xử lý nó đúng không?
   - **Status**: ✅ Đã implement (dòng 765-770)

---

#### **Priority 2: Cải thiện UX/Logic**

1. **Frontend: Dropdown pre-defined allergens**
   - Thay vì textarea tự do, thêm checkboxes cho allergen thường gặp
   - VD: ☑️ Tôm ☑️ Cua ☑️ Mực ☑️ Sữa ☑️ Trứng ☑️ Đậu phộng
   - Code: Thêm `<div id="allergenChips">` tương tự `noteChips`

2. **Backend: Cải thiện allergen filter**
   - Thêm stage 3: Check gia vị + nước xốt dành riêng (tuỳ chọn)
   - VD: Nếu user chọn "Tôm", cũng loại "Tương tôm", "Xốt tôm"
   - Code: Thêm keyword mapping trong `suggest_menu()`

3. **API: Endpoint `/allergen/common`**
   - Trả danh sách allergen phổ biến
   - Để frontend load lên UI
   ```python
   @app.get("/allergen/common")
   def get_common_allergens():
       return {
           "allergens": [
               "Tôm", "Cua", "Mực", "Cá", "Sữa", "Trứng",
               "Đậu phộng", "Hạt dẻ", "Gluten", "Khoai tây"
           ]
       }
   ```

4. **Session storage: Lưu allergen profile**
   - Sau khi user tạo thực đơn lần 1, lưu allergen_ingredients vào session
   - Lần sau tạo thực đơn, gợi ý pre-fill allergen cũ

---

#### **Priority 3: Optional improvements**

1. **Allergen interaction checker**
   - Check interactions giữa allergen và mục tiêu sức khỏe
   - VD: "Dị ứng tôm + mục tiêu tăng cân" → tìm protein thay thế

2. **Allergen severity levels**
   - "Dị ứng nặng" vs "Không ưa"
   - Nặng: Loại hoàn toàn; Không ưa: Có thể recommend nhưng cảnh báo

3. **Allergy notes in response**
   - Thêm note vào mỗi bữa: "✓ An toàn: Không chứa tôm, cua"

4. **Backend validation**
   - Validate allergen_ingredients có phải nguyên liệu hợp lệ không
   - Normalize: "TÔM" → "tôm", "tôm hùm" → "tôm"...

---

## 📈 CÁCH CẢI THIỆN FLOW

### Improvement 1: Allergen Dropdown (Priority 1)
```html
<!-- index.html -->
<label class="form-label">🚫 Dị ứng (chọn hoặc nhập)</label>
<div class="allergen-chips" id="allergenChips">
  <button class="allergen-chip" onclick="toggleAllergen(this, 'Tôm')">🦐 Tôm</button>
  <button class="allergen-chip" onclick="toggleAllergen(this, 'Cua')">🦀 Cua</button>
  <button class="allergen-chip" onclick="toggleAllergen(this, 'Mực')">🦑 Mực</button>
  <button class="allergen-chip" onclick="toggleAllergen(this, 'Sữa')">🥛 Sữa</button>
  <button class="allergen-chip" onclick="toggleAllergen(this, 'Trứng')">🥚 Trứng</button>
</div>
<textarea class="form-textarea" id="allergyInput" 
          placeholder="Hoặc nhập thêm..."></textarea>
```

```javascript
// app.js
let selectedAllergens = [];

function toggleAllergen(btn, allergen) {
  btn.classList.toggle('selected');
  if (btn.classList.contains('selected')) {
    if (!selectedAllergens.includes(allergen)) selectedAllergens.push(allergen);
  } else {
    selectedAllergens = selectedAllergens.filter(a => a !== allergen);
  }
}

async function generateMenu() {
  // ...
  // Combine allergens từ chips + textarea
  const customAllergies = document.getElementById('allergyInput').value.trim()
    ? document.getElementById('allergyInput').value.split(',').map(a => a.trim())
    : [];
  const allAllergens = [...selectedAllergens, ...customAllergies];
  
  const res = await fetch(`${API}/menu/generate`, {
    method: 'POST',
    body: JSON.stringify({
      // ...
      allergen_ingredients: allAllergens  // ["Tôm", "Cua", "sữa"]
    })
  });
}
```

---

### Improvement 2: Endpoint /allergen/common (Priority 2)
```python
# main.py
@app.get("/allergen/common", summary="Danh sách allergen phổ biến")
def get_common_allergens():
    """Trả allergen phổ biến để frontend hiển thị dropdown."""
    return {
        "allergens": [
            "Tôm", "Cua", "Mực", "Cá", "Hàu",
            "Sữa", "Trứng", "Lúa mạch", "Đậu phộng",
            "Hạt dẻ", "Hạt điều", "Khoai tây",
        ],
        "note": "Chọn hoặc nhập allergen tùy chỉnh"
    }
```

---

## 🎓 TÓM TẮT KIẾN TRÚC VẬN HÀNH

```
┌──────────────────────────────────────────────────────────────────┐
│                      CHATBOT SYSTEM ARCHITECTURE                 │
└──────────────────────────────────────────────────────────────────┘

┌─────────────────────────────┐
│      FRONTEND (Web/App)     │
│  ▪ Chat tab                 │
│  ▪ Menu builder (+ allergen)│
│  ▪ Stall finder             │
└─────────────┬───────────────┘
              │ HTTP/JSON
              ▼
┌──────────────────────────────────────────────────────────────────┐
│                    FASTAPI BACKEND (main.py)                    │
├─────────────────┬──────────────────────┬─────────────────────┤
│  POST /chat     │  POST /menu/generate │  GET /dishes/search │
│  ▪ intent       │  ▪ allergen_ingr.    │  ▪ q, goal, cals... │
│  ▪ exclude_t.   │  ▪ health_goal       │                     │
└────────┬────────┴──────┬───────────────┴────────────┬──────────┘
         │               │                           │
         ▼               ▼                           ▼
    ┌────────────────────────────────────────────────────────┐
    │  DATA PROCESSING LAYER                                 │
    │  ┌──────────────────────────────────────────────────┐ │
    │  │ 1. query_understanding.understand_query()        │ │
    │  │    → intent, search_query, exclude_terms         │ │
    │  │                                                   │ │
    │  │ 2. main._get_dishes_for_message()                │ │
    │  │    → RAG/keyword search + exclude filter         │ │
    │  │                                                   │ │
    │  │ 3. data_loader.suggest_menu()                    │ │
    │  │    → Query dishes from groups                     │ │
    │  │    → Filter allergen_banned_ids                  │ │
    │  │    → Build menu                                  │ │
    │  │                                                   │ │
    │  │ 4. llama_service.chat_with_llama()               │ │
    │  │    → Format context, call Qwen2.5                │ │
    │  └──────────────────────────────────────────────────┘ │
    └────────┬──────────────────────────────────────────────┘
             │
    ┌────────▼──────────────────────────────────────┐
    │  DATA SOURCES                                  │
    │  ┌──────────────────────────────────────────┐ │
    │  │ PostgreSQL:                              │ │
    │  │  ▪ dishes (2473 mon)                     │ │
    │  │  ▪ recipes (ingredients)                 │ │
    │  │  ▪ dish_classification (groups)          │ │
    │  │  ▪ ingredients                           │ │
    │  │  ▪ stalls (gian hang)                    │ │
    │  │  ▪ goods (hang hoa)                      │ │
    │  └──────────────────────────────────────────┘ │
    │  ┌──────────────────────────────────────────┐ │
    │  │ CSV:                                     │ │
    │  │  ▪ rag_menu_final.csv (RAG context)      │ │
    │  └──────────────────────────────────────────┘ │
    │  ┌──────────────────────────────────────────┐ │
    │  │ In-memory:                               │ │
    │  │  ▪ FAISS index (.vector_cache/)          │ │
    │  │  ▪ LLM embeddings                        │ │
    │  └──────────────────────────────────────────┘ │
    └──────────────────────────────────────────────┘
             │
             ▼
    ┌──────────────────────────────┐
    │   EXTERNAL SERVICES          │
    │  ┌────────────────────────┐  │
    │  │ Ollama (Qwen2.5:14b)   │  │
    │  │ localhost:11434        │  │
    │  └────────────────────────┘  │
    └──────────────────────────────┘
```

---

## ✅ CHECKLIST XÁC MINH

- [x] Cấu trúc file + mục đích mỗi file
- [x] Flow dữ liệu frontend → backend
- [x] Cách allergen_ingredients được gửi từ frontend (textarea app.js)
- [x] Cách nó được nhận trong /menu/generate endpoint
- [x] Cách nó được xử lý trong suggest_menu() (2 tầng: tên + nguyên liệu)
- [x] Các hàm chính: suggest_menu, search_dishes, understand_query, chat_with_llama
- [x] Điểm cần sửa + cải thiện

