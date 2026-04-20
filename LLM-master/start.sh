#!/bin/bash
# ─────────────────────────────────────────────────
#  start.sh – Khởi động Chatbot Ẩm Thực API
# ─────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo ""
echo "════════════════════════════════════════════"
echo "   🍜  Chatbot Ẩm Thực API – Khởi động"
echo "════════════════════════════════════════════"

# 1. Kiểm tra Python
if ! command -v python3 &>/dev/null; then
    echo "❌ Cần cài Python 3.10+"
    exit 1
fi
echo "✅ Python: $(python3 --version)"

# 2. Tạo virtualenv nếu chưa có
if [ ! -d "venv" ]; then
    echo "📦 Tạo virtual environment..."
    python3 -m venv venv
fi

# 3. Activate venv
source venv/bin/activate

# 4. Cài dependencies
echo "📥 Cài dependencies..."
pip install -q --upgrade pip
pip install -q -r requirements.txt

# 5. Kiểm tra Ollama
echo ""
echo "🦙 Kiểm tra Ollama..."
if ! command -v ollama &>/dev/null; then
    echo "⚠️  Ollama chưa được cài. Tải tại: https://ollama.ai"
    echo "   Sau khi cài xong, chạy: ollama pull llama3.2"
    echo "   API vẫn sẽ khởi động nhưng /chat cần Ollama để hoạt động."
else
    echo "✅ Ollama đã cài."
    # Kiểm tra model
    if ollama list 2>/dev/null | grep -q "qwen2.5:14b"; then
        echo "✅ Model qwen2.5:14b san sang."
    else
        echo "⬇️  Dang tai qwen2.5:14b (~9GB, vui long cho..."
        ollama pull qwen2.5:14b
    fi
fi

# 6. Khởi động FastAPI
echo ""
echo "🚀 Khoi dong API tai http://0.0.0.0:8001"
echo "📖 Swagger UI: http://0.0.0.0:8001/docs"
echo "════════════════════════════════════════════"
echo ""

export PYTHONIOENCODING=utf-8
uvicorn main:app --host 0.0.0.0 --port 8001 --workers 1
