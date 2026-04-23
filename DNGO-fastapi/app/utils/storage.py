import os
import shutil
from pathlib import Path
from datetime import datetime

# Lấy đường dẫn tuyệt đối từ vị trí file này
BASE_DIR = Path(__file__).resolve().parent.parent.parent
UPLOAD_BASE_DIR = BASE_DIR / "uploads"
BASE_URL = os.getenv("PUBLIC_BASE_URL") or os.getenv("BASE_URL", "http://127.0.0.1:8000")
BASE_URL = BASE_URL.rstrip("/")
if BASE_URL.endswith("/api"):
    BASE_URL = BASE_URL[:-4]

def save_file(file_buffer: bytes, original_name: str, folder: str = "uploads") -> str:
    timestamp = int(datetime.now().timestamp() * 1000)
    ext = Path(original_name).suffix
    base_name = Path(original_name).stem
    file_name = f"{base_name}-{timestamp}{ext}"
    
    folder_path = Path(UPLOAD_BASE_DIR) / folder
    folder_path.mkdir(parents=True, exist_ok=True)
    
    file_path = folder_path / file_name
    with open(file_path, "wb") as f:
        f.write(file_buffer)
    
    public_url = f"{BASE_URL}/uploads/{folder}/{file_name}"
    return public_url

def delete_file(file_url: str) -> bool:
    try:
        path = file_url.replace(f"{BASE_URL}/uploads/", "")
        file_path = Path(UPLOAD_BASE_DIR) / path
        if file_path.exists():
            file_path.unlink()
        return True
    except Exception:
        return False