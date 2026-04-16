import firebase_admin
from firebase_admin import credentials, db
import logging
import os
from app.config import settings

logger = logging.getLogger(__name__)

def init_firebase():
    """Khởi tạo kết nối đến Firebase nếu chưa có"""
    try:
        # Kiểm tra xem app đã khởi tạo chưa
        firebase_admin.get_app()
        logger.info("Firebase app already initialized.")
    except ValueError:
        # Lấy đường dẫn file serviceAccountKey.json từ thư mục gốc
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        cert_path = os.path.join(base_dir, "serviceAccountKey.json")
        
        if not os.path.exists(cert_path):
            logger.error(f"⚠️ KHÔNG TÌM THẤY serviceAccountKey.json tại: {cert_path}")
            return
        
        try:
            cred = credentials.Certificate(cert_path)
            firebase_admin.initialize_app(cred, {
                'databaseURL': settings.FIREBASE_DATABASE_URL
            })
            logger.info("✅ Đã khởi tạo Firebase Admin SDK thành công.")
        except Exception as e:
            logger.error(f"❌ Lỗi khi khởi tạo Firebase: {str(e)}")

def get_db_ref(path: str):
    """
    Trả về Realtime Database reference
    Ví dụ: get_db_ref('tracking/ORD_123')
    """
    # Khởi tạo phòng trường hợp chưa khởi tạo
    init_firebase()
    return db.reference(path)
