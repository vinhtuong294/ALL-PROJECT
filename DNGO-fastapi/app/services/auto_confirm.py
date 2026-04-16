import time
from app.database import SessionLocal
from app.models.models import OrderDetail, Order


def auto_confirm_order(order_id: str):
    db = SessionLocal()

    try:
        # ⏱️ đợi 2 phút
        time.sleep(120)

        details = db.query(OrderDetail).filter(
            OrderDetail.order_id == order_id
        ).all()

        updated = False

        for d in details:
            if d.detail_status == "cho_duyet":
                d.detail_status = "da_duyet"
                updated = True

        if updated:
            order = db.query(Order).filter(
                Order.order_id == order_id
            ).first()

            if order:
                order.order_status = "da_xac_nhan"

        db.commit()

    except Exception as e:
        print("AUTO CONFIRM ERROR:", e)

    finally:
        db.close()