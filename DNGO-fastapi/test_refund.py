import sys
import os

sys.path.append(os.getcwd())

from app.database import SessionLocal
from app.models.models import Order, OrderDetail
from app.repositories.buyer import refund_order_details

db = SessionLocal()

try:
    # Tìm một order detail có thể hoàn
    detail = db.query(OrderDetail).filter(
        OrderDetail.detail_status.in_(["da_duyet", "tu_choi", "da_lay_hang"])
    ).first()

    if detail:
        print(f"Found order detail: Order {detail.order_id}, Item {detail.ingredient_id}, Stall {detail.stall_id}, Status {detail.detail_status}")
        order = db.query(Order).filter(Order.order_id == detail.order_id).first()
        print(f"Buyer ID: {order.buyer_id}")
        
        # Test dry-run refund logic
        print("Testing refund logic...")
        try:
            res = refund_order_details(
                db=db,
                buyer_id=order.buyer_id,
                order_id=detail.order_id,
                items=[{
                    "ingredient_id": detail.ingredient_id,
                    "stall_id": detail.stall_id,
                    "reason": "Chất lượng sản phẩm kém" # Must be in VALID_CANCEL_REASONS
                }]
            )
            print("Refund response:", res)
            # Rollback to avoid modifying data
            db.rollback()
            print("Rollback successful. Logic is working!")
        except Exception as e:
            print("Refund logic failed:", e)
    else:
        print("No eligible order detail found to test refund.")

finally:
    db.close()
