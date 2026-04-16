from apscheduler.schedulers.background import BackgroundScheduler
from datetime import datetime
import random, string
from app.database import SessionLocal
from app.models.models import Stall, StallFee, Payment

def generate_id(prefix, length=8):
    return prefix + ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))

def auto_create_monthly_fees():
    db = SessionLocal()
    try:
        current_month = datetime.now().date().replace(day=1)
        stalls = db.query(Stall).all()
        
        for stall in stalls:
            # Kiểm tra đã có phí tháng này chưa
            existing = db.query(StallFee).filter(
                StallFee.stall_id == stall.stall_id,
                StallFee.month == current_month
            ).first()
            
            if not existing:
                payment_id = generate_id("PM")
                new_payment = Payment(
                    payment_id=payment_id,
                    payment_method="tien_mat",
                    payment_account="ACCOUNT_SYSTEM",
                    payment_time=datetime.now(),
                    payment_status="chua_thanh_toan"
                )
                db.add(new_payment)
                db.flush()

                fee_id = generate_id("FE")
                new_fee = StallFee(
                    fee_id=fee_id,
                    stall_id=stall.stall_id,
                    fee=stall.stall_fee or 50000,
                    fee_status="chua_nop",
                    month=current_month,
                    payment_id=payment_id
                )
                db.add(new_fee)
        
        db.commit()
        print(f"[OK] Da tao phi thang {current_month} thanh cong")
    except Exception as e:
        db.rollback()
        print(f"[ERROR] Loi tao phi: {e}")
    finally:
        db.close()

def start_scheduler():
    scheduler = BackgroundScheduler()
    # Chạy lúc 00:00 ngày 1 mỗi tháng
    scheduler.add_job(auto_create_monthly_fees, 'cron', day=1, hour=0, minute=0)
    scheduler.start()
    return scheduler