# 🍜 Chatbot Ẩm Thực API — LLM-master

FastAPI backend tích hợp **Qwen2.5:14b** (qua Ollama) + **RAG FAISS** để tư vấn món ăn, tạo thực đơn cá nhân hoá và gợi ý gian hàng mua nguyên liệu.

---

## 🏗️ Kiến trúc hệ thống

```
Flutter App
    │  HTTP/WebSocket
    ▼
FastAPI (main.py : 8001)
    ├── RAG Search       ← vector_store.py (FAISS + sentence-transformers)
    ├── DB Query         ← data_loader.py  (PostgreSQL + SQLAlchemy)
    ├── LLM Response     ← llama_service.py (Ollama → Qwen2.5:14b)
    ├── Intent Detection ← intent_detector.py
    └── Query Parse      ← query_understanding.py (flashtext)
```

---

## ⚙️ Yêu cầu hệ thống

| Thành phần | Tối thiểu | Khuyến nghị |
|-----------|-----------|-------------|
| Python | 3.10+ | 3.11+ |
| GPU VRAM | 8 GB | **24 GB (RTX 3090)** |
| RAM | 16 GB | 32 GB+ |
| Disk | 20 GB | 50 GB |
| OS | Ubuntu 20.04 / Windows 10 | Ubuntu 22.04 |

---

## 🐧 Cài đặt trên Linux (RunPod / Ubuntu)

### 1. Clone repo

```bash
git clone <your-repo-url> LLM-master
cd LLM-master
```

### 2. Cài Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh

# Khởi động Ollama service
ollama serve &

# Pull model Qwen2.5:14b (~9GB)
ollama pull qwen2.5:14b

# Xác nhận model đã có
ollama list
```

### 3. Tạo virtualenv & cài dependencies

```bash
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Cấu hình biến môi trường

Tạo file `.env` trong thư mục gốc:

```bash
cat > .env << 'EOF'
# Database PostgreSQL
DB_HOST=207.180.233.84
DB_PORT=5432
DB_NAME=dngo
DB_USER=dtrinh
DB_PASSWORD=DNgodue

# URL public của API này (Flutter app dùng để tạo link ảnh)
CHATBOT_PUBLIC_API_BASE_URL=http://<YOUR_SERVER_IP>:8001

# (Tuỳ chọn) Nếu Ollama chạy ở host khác
# OLLAMA_HOST=http://localhost:11434
EOF
```

> ⚠️ **Không commit file `.env`** — thêm vào `.gitignore`

### 5. Khởi động server

```bash
# Cách 1: Dùng script có sẵn (khuyến nghị)
chmod +x start.sh
./start.sh

# Cách 2: Thủ công
source venv/bin/activate
export PYTHONIOENCODING=utf-8
uvicorn main:app --host 0.0.0.0 --port 8001 --workers 1
```

### 6. Kiểm tra hoạt động

```bash
# Health check
curl http://localhost:8001/health

# Test tạo menu
curl -X POST http://localhost:8001/menu/generate \
  -H "Content-Type: application/json" \
  -d '{
    "days": 3,
    "meals_per_day": 3,
    "health_goal": "Giảm cân",
    "notes": ["Dị ứng: tôm, gà"]
  }'
```

---

## 🪟 Cài đặt trên Windows

### 1. Cài Python 3.11

Tải từ https://python.org → đánh dấu **Add to PATH**

### 2. Cài Ollama

Tải installer tại https://ollama.com/download/windows

```powershell
# Mở PowerShell (Run as Administrator), pull model
ollama pull qwen2.5:14b
```

### 3. Tạo virtualenv & cài dependencies

```powershell
cd "c:\market_app 1\LLM-master"
python -m venv venv
.\venv\Scripts\activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Cấu hình biến môi trường

Tạo file `.env`:

```
DB_HOST=207.180.233.84
DB_PORT=5432
DB_NAME=dngo
DB_USER=dtrinh
DB_PASSWORD=DNgodue
CHATBOT_PUBLIC_API_BASE_URL=http://localhost:8001
```

### 5. Khởi động server

```powershell
.\venv\Scripts\activate
$env:PYTHONIOENCODING="utf-8"
uvicorn main:app --host 0.0.0.0 --port 8001 --workers 1
```

Truy cập Swagger UI: http://localhost:8001/docs

---

## 📡 API Endpoints chính

| Method | Endpoint | Mô tả |
|--------|----------|-------|
| `GET` | `/health` | Kiểm tra trạng thái server |
| `POST` | `/chat` | Chat tư vấn món ăn với LLM |
| `POST` | `/menu/generate` | Tạo thực đơn cá nhân hoá |
| `GET` | `/dishes/search` | Tìm kiếm món ăn |
| `GET` | `/dishes/{id}` | Chi tiết món ăn + công thức |
| `GET` | `/dishes/{id}/stalls` | Gian hàng bán nguyên liệu |
| `GET` | `/stalls/search` | Tìm gian hàng |

### Ví dụ: Tạo menu với lọc dị ứng

```json
POST /menu/generate
{
  "days": 7,
  "meals_per_day": 3,
  "health_goal": "Giảm cân",
  "notes": [
    "Dị ứng: tôm, gà, đậu phộng",
    "Miền Nam"
  ]
}
```

**Giải thích `notes`:**
- `"Dị ứng: X, Y"` → tự động lọc bỏ món chứa X hoặc Y
- Các ghi chú khác: `"Món chay"`, `"Ăn kiêng"`, `"Miền Bắc"`, `"Miền Trung"`, `"Miền Nam"`, `"Người lớn tuổi"`, `"Trẻ em"`

---

## 🤖 Cấu hình LLM Model

File `llama_service.py` — dòng 9:

```python
MODEL = "qwen2.5:14b"   # Đang dùng (khuyến nghị cho RTX 3090)
```

| Model | VRAM | Chất lượng TV | Ghi chú |
|-------|------|---------------|---------|
| `qwen2.5:7b` | ~5 GB | ⭐⭐⭐⭐ | Dùng khi VRAM ít |
| **`qwen2.5:14b`** | ~9 GB | ⭐⭐⭐⭐⭐ | **Khuyến nghị** |
| `qwen2.5:32b-instruct-q4_K_M` | ~20 GB | ⭐⭐⭐⭐⭐+ | Tốt nhất cho RTX 3090 |
| `gemma3:27b` | ~18 GB | ⭐⭐⭐⭐⭐ | Thay thế tốt |

Đổi model: sửa `MODEL = "qwen2.5:32b-instruct-q4_K_M"` rồi `ollama pull qwen2.5:32b-instruct-q4_K_M`

---

## 🗂️ Cấu trúc thư mục

```
LLM-master/
├── main.py                  # FastAPI app + tất cả endpoints
├── data_loader.py           # Load DB, suggest_menu, search_dishes
├── llama_service.py         # Ollama wrapper (Qwen2.5)
├── vector_store.py          # FAISS semantic search
├── db_config.py             # Kết nối PostgreSQL (đọc từ .env)
├── intent_detector.py       # Phân loại ý định chat
├── query_understanding.py   # Xử lý câu hỏi NLU
├── rag_menu_final.csv       # Dữ liệu RAG tĩnh
├── requirements.txt         # Dependencies Python
├── start.sh                 # Script khởi động Linux
├── .env                     # Biến môi trường (KHÔNG commit)
└── .vector_cache/           # Cache FAISS index (tự tạo lần đầu)
```

---

## 🔧 Debug thường gặp

### ❌ `No module named 'psycopg2'`
```bash
pip install psycopg2-binary
```

### ❌ `No module named 'flashtext'`
```bash
pip install flashtext
```

### ❌ `OSError: DLL initialization failed` (Windows)
```powershell
# Cài lại torch phù hợp với CUDA
pip install torch --index-url https://download.pytorch.org/whl/cu121
```

### ❌ `UnicodeEncodeError: charmap codec` (Windows)
```powershell
$env:PYTHONIOENCODING="utf-8"
# Hoặc thêm vào System Environment Variables
```

### ❌ Ollama không nhận được request
```bash
# Kiểm tra Ollama đang chạy
ollama list
# Nếu không → khởi động
ollama serve
```

### ❌ FAISS index lỗi lần đầu chạy
```bash
# Xoá cache rồi chạy lại — sẽ tự build lại (~1-2 phút)
rm -rf .vector_cache/
python -c "import data_loader as dl; import vector_store as vs; d=dl.get_data(); vs.build_index(d['rag'])"
```

---

## 📊 Test sau khi deploy

```bash
# 1. Test DB connection
python -c "from db_config import get_engine; e=get_engine(); print('DB OK')"

# 2. Test bộ lọc dị ứng
python test_allergy_filter.py

# 3. Test full pipeline (không cần LLM)
python test_pipeline_no_llm.py

# 4. Test LLM chat + menu (cần Ollama)
python test_llm_full.py
```

---

## 📝 Ghi chú phát triển

- **Allergy filter** dùng `unaccent()` + `word-boundary regex \m...\M` của PostgreSQL để tránh loại nhầm (`gạo tấm` ≠ `gà`)
- **FAISS cache** lưu tại `.vector_cache/` — lần đầu mất ~1-2 phút, sau đó load nhanh
- **Model** mặc định `qwen2.5:14b` — tối ưu cho RTX 3090 24GB VRAM
- **Encoding** luôn set `PYTHONIOENCODING=utf-8` khi chạy trên Windows
