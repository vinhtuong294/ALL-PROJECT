# 🍜 Chatbot Ẩm Thực API

REST API chatbot tư vấn ăn uống cho Flutter app.  
Dùng **Llama 3.2** (Ollama) + **FAISS RAG** trên 7473 món ăn.

## Tai lieu chi tiet

- Xem giai thich toan bo co che va luong `/chat`: [RAG_MECHANISM.md](RAG_MECHANISM.md)

---

## ⚡ Chạy nhanh

```bash
# 1. Vào thư mục
cd chatbot_api

# 2. Chạy script (tự động cài đặt và khởi động)
bash start.sh
```

API sẽ chạy tại: `http://207.180.233.84:8000`  
Swagger UI: `http://207.180.233.84:8000/docs`

---

## 🦙 Cài Ollama (bắt buộc cho /chat)

1. Tải tại: https://ollama.ai
2. Sau khi cài: `ollama pull llama3.2`
  ```
  docker pull ollama/ollama
  docker exec -it ollama ollama pull llama3.2 
  ```

3. Nếu máy yếu: `ollama pull llama3.2:1b`

---

## 📡 Các Endpoint

| Method | URL | Mô tả |
|--------|-----|-------|
| GET | `/health` | Kiểm tra trạng thái |
| POST | `/chat` | Chat với trợ lý (Llama + RAG) |
| GET | `/dishes/search` | Tìm kiếm món ăn + công thức |
| GET | `/dishes/{dish_id}` | Chi tiết 1 món |
| POST | `/menu/suggest` | Gợi ý thực đơn N ngày |
| GET | `/health-goals` | Danh sách mục tiêu sức khoẻ |

---

## 📱 Tích hợp Flutter

### 1. Chat request
```dart
final response = await http.post(
  Uri.parse('http://207.180.233.84:8000/chat'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'message': 'Cho tôi xem các món cá',
    'session_id': 'user_123',
    'history': [],   // list {role, content} – lịch sử hội thoại
  }),
);
final data = jsonDecode(response.body);
// data['reply']    → chuỗi phản hồi của chatbot
// data['dishes']   → list món ăn (có recipe + buy_action)
// data['intent']   → intent được nhận diện
```

### 2. Dish object (trong `dishes[]`)
```json
{
  "dish_id": "M0002",
  "dish_name": "Cá hồi chiên xốt xoài",
  "image_url": "https://...",
  "calories": 310.0,
  "health_goal": "Dinh dưỡng cân bằng",
  "cooking_time": "20 phút",
  "level": "Dễ",
  "servings": "2 người",
  "recipe": {
    "ingredients": ["Cá hồi phi lê", "Xoài", "Dầu ăn", "..."],
    "preparation": "Cá hồi cắt con chì, ướp chanh...",
    "steps": "Chiên cá: lăn qua bột...",
    "serving_tips": "Xếp cá ra dĩa cùng salad..."
  },
  "buy_action": {
    "dish_id": "M0002",
    "label": "🛒 Mua ngay"
  }
}
```

### 3. Tìm kiếm
```dart
final res = await http.get(Uri.parse(
  'http://207.180.233.84:8000/dishes/search?q=thịt bò&level=Dễ&limit=10'
));
```

### 4. Gợi ý thực đơn
```dart
final res = await http.post(
  Uri.parse('http://207.180.233.84:8000/menu/suggest'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'health_goal': 'Tăng cân / Năng lượng cao',
    'days': 7,
    'meals_per_day': 3,
  }),
);
```

---

## 🔧 Cấu hình

Mở `llama_service.py` → đổi biến `MODEL`:
- `"llama3.2"` — chất lượng tốt (~4GB RAM)
- `"llama3.2:1b"` — nhanh hơn (~1.3GB RAM)

---

## ❓ Troubleshooting

| Lỗi | Cách sửa |
|-----|----------|
| `Connection refused` at /chat | Kiểm tra Ollama đang chạy: `ollama serve` |
| `model not found` | Chạy: `ollama pull llama3.2` |
| FAISS build chậm | Chỉ xảy ra lần đầu, sau đó cache |
| CORS error | Đã enable `*`, nếu vẫn lỗi thêm domain vào `allow_origins` trong `main.py` |
