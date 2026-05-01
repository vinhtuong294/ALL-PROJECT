import time
from app.database import SessionLocal
from app.models.models import OrderDetail, Order


def auto_confirm_order(order_id: str):
    db = SessionLocal()

    try:
        # ⏱️ đợi 2 phút trước khi tự xác nhận
        time.sleep(120)

        order = db.query(Order).filter(Order.order_id == order_id).first()

        # Nếu đã được xử lý rồi (seller confirm sớm, hoặc đã hủy), bỏ qua
        if not order or order.order_status != "chua_xac_nhan":
            return

        details = db.query(OrderDetail).filter(
            OrderDetail.order_id == order_id
        ).all()

        # Tự approve các item chưa được seller xử lý
        for d in details:
            if d.detail_status == "cho_duyet":
                d.detail_status = "da_duyet"

        # Luôn chuyển sang da_xac_nhan sau 2 phút (kể cả khi không có gì thay đổi)
        order.order_status = "da_xac_nhan"
        db.commit()

    except Exception as e:
        db.rollback()
        print("AUTO CONFIRM ERROR:", e)

    finally:
        db.close()
