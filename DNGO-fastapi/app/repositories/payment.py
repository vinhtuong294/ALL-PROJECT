# app/repositories/payment.py


import uuid
import hmac
import hashlib
from datetime import datetime, timedelta
from urllib.parse import quote_plus


from sqlalchemy.orm import Session
from sqlalchemy import select


from app.config import settings
from app.models import Order, Payment, PaymentStatus, PaymentMethod, OrderDetail, Goods, OrderStatus




# =====================================================
# HELPER
# =====================================================


def _vn_now() -> datetime:
    """Giờ hiện tại theo múi giờ Việt Nam (UTC+7)."""
    return datetime.utcnow() + timedelta(hours=7)




def _fmt_date(dt: datetime) -> str:
    return dt.strftime("%Y%m%d%H%M%S")




def _add_minutes(base: str, minutes: int) -> str:
    dt = datetime.strptime(base, "%Y%m%d%H%M%S") + timedelta(minutes=minutes)
    return dt.strftime("%Y%m%d%H%M%S")




def _gen_txn_ref(length: int = 10) -> str:
    """Tạo mã giao dịch dạng TT + random hex, ví dụ: TTD4109CED."""
    if length <= 2:
        return uuid.uuid4().hex[:max(4, length)].upper()
    return "TT" + uuid.uuid4().hex[: length - 2].upper()




def _enc_plus(v) -> str:
    """Encode URL giống encodeURIComponent + thay %20 bằng +."""
    return quote_plus(str(v).strip())



def _make_sign_data(params: dict) -> str:
    """
    Tạo chuỗi ký: sort key, join RAW value (KHÔNG encode).
    Đây là chuẩn VNPay — ký trên chuỗi raw.
    """
    data = {
        k: v for k, v in params.items()
        if k not in ("vnp_SecureHash", "vnp_SecureHashType")
    }
    return "&".join(
        f"{k}={quote_plus(str(data[k]).strip())}"
        for k in sorted(data.keys())
    )



def _make_query_string(params: dict) -> str:
    """
    Tạo query string cho URL: sort key, encode value.
    Encode khi gắn vào URL, KHÔNG dùng để ký.
    """
    return "&".join(
        f"{k}={_enc_plus(params[k])}"
        for k in sorted(params.keys())
    )




def _compute_hash(sign_data: str, secret: str, hash_type: str) -> str:
    ht = (hash_type or "").upper()


    if ht == "HMACSHA256":
        return hmac.new(
            secret.encode("utf-8"),
            sign_data.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest().upper()


    if ht == "SHA256":
        return hashlib.sha256(
            (secret + sign_data).encode("utf-8")
        ).hexdigest().upper()


    # default: HMACSHA512
    return hmac.new(
        secret.encode("utf-8"),
        sign_data.encode("utf-8"),
        hashlib.sha512,
    ).hexdigest().upper()




# =====================================================
# ENSURE PENDING PAYMENT
# =====================================================


def ensure_pending_payment(order_id: str, db: Session):
    """
    Lấy hoặc tạo Payment cho đơn hàng.
    - Nếu chưa có payment → tạo mới
    - Nếu đã có nhưng chưa thanh toán → đổi mã txn mới (tránh trùng)
    - Nếu đã thanh toán hoặc đơn đã xác nhận → raise ORDER_LOCKED
    """
    order = db.execute(
        select(Order).where(Order.order_id == order_id)
    ).scalar_one_or_none()


    if not order:
        raise Exception("ORDER_NOT_FOUND")


    # Kiểm tra đơn đã khóa chưa
    already_paid = (
        order.payment and
        order.payment.payment_status == PaymentStatus.da_thanh_toan.value
    )

    # Bỏ check order_status, chỉ check payment_status
    if already_paid:
        raise Exception("ORDER_LOCKED")
    payment = order.payment


    if not payment:
        # Tạo payment mới
        txn_ref = _gen_txn_ref(10)
        payment = Payment(
            payment_id=txn_ref,
            payment_method=PaymentMethod.chuyen_khoan.value,
            payment_account="",
            payment_status=PaymentStatus.chua_thanh_toan.value,
            payment_time=_vn_now(),
        )
        db.add(payment)
        db.flush()
        order.payment_id = txn_ref


    elif payment.payment_status == PaymentStatus.chua_thanh_toan.value:
        # Đổi mã txn mới để tránh VNPay báo trùng
        current_len = len(payment.payment_id or "") or 10
        new_txn = _gen_txn_ref(current_len)
        payment.payment_id = new_txn
        db.flush()


    return order, payment




# =====================================================
# BUILD VNPAY URL
# =====================================================


def build_vnpay_url(
    db: Session,
    order_id: str,
    client_ip: str,
    bank_code: str | None = None,
) -> dict:


    # Kiểm tra env
    if not all([
        settings.VNP_TMN_CODE,
        settings.VNP_HASH_SECRET,
        settings.VNP_URL,
        settings.VNP_RETURN_URL,
    ]):
        raise Exception("VNPAY_ENV_MISSING")


    order, payment = ensure_pending_payment(order_id, db)


    amount = float(order.total_amount or 0)
    if amount <= 0:
        raise Exception("ORDER_AMOUNT_INVALID")


    create_date = _fmt_date(_vn_now())
    expire_date = _add_minutes(create_date, 15)


    # Tham số gửi VNPay
    params = {
        "vnp_Version":   "2.1.0",
        "vnp_Command":   "pay",
        "vnp_TmnCode":   settings.VNP_TMN_CODE,
        "vnp_Locale":    "vn",
        "vnp_CurrCode":  "VND",
        "vnp_TxnRef":    payment.payment_id,
        "vnp_OrderInfo": f"Thanh toan don {order_id}",
        "vnp_OrderType": "other",
        "vnp_Amount": int(round(amount * 100)),  # số nguyên
        "vnp_ReturnUrl": settings.VNP_RETURN_URL,
        "vnp_IpAddr":    (client_ip or "127.0.0.1").split(",")[0].strip(),
        "vnp_CreateDate": create_date,
        "vnp_ExpireDate": expire_date,
    }


    if bank_code:
        params["vnp_BankCode"] = bank_code


    # ===== Tạo chữ ký trên chuỗi RAW (không encode) =====
    sign_data = _make_sign_data(params)
    secure_hash = _compute_hash(
        sign_data,
        settings.VNP_HASH_SECRET,
        settings.VNP_SECURE_HASH_TYPE,
    )


    print(f"[VNP SIGNTYPE] {settings.VNP_SECURE_HASH_TYPE}")
    print(f"[VNP SIGNDATA] {sign_data}")
    print(f"[VNP HASH    ] {secure_hash}")


    # ===== Tạo URL với encode =====
    query_params = {
        **params,
        "vnp_SecureHashType": settings.VNP_SECURE_HASH_TYPE,
        "vnp_SecureHash":     secure_hash,
    }
    pay_url = f"{settings.VNP_URL}?{_make_query_string(query_params)}"


    print(f"[VNP URL     ] {pay_url}")


    db.commit()


    return {
        "payUrl":     pay_url,
        "payment_id": payment.payment_id,
        "amount":     int(round(amount)),  # Số tiền VND thực tế (không x100)
    }

def _mark_paid(db: Session, payment_id: str, vnp_data: dict) -> str:
    """
    Đánh dấu thanh toán thành công, cập nhật payment + order + trừ tồn kho.
    Trả về order_id.
    """
    import re
    from datetime import datetime

    # Lấy order_id từ vnp_OrderInfo nếu có
    order_id = None
    info = str(vnp_data.get("vnp_OrderInfo", "")).strip()
    m = re.search(r"don\s+([A-Z0-9_-]+)", info, re.I)
    if m:
        order_id = m.group(1)

    payment = db.execute(
        select(Payment).where(Payment.payment_id == payment_id)
    ).scalar_one_or_none()

    if payment and payment.orders:
        order_id = payment.orders[0].order_id

    if not order_id:
        raise Exception(f"ORDER_ID_NOT_FOUND for payment {payment_id}")

    # Idempotent
    if payment and payment.payment_status == PaymentStatus.da_thanh_toan.value:
        return order_id

    # Lưu thông tin ngân hàng
    tx_no = str(vnp_data.get("vnp_TransactionNo", ""))
    bank_no = str(vnp_data.get("vnp_BankTranNo", ""))
    bank_code = str(vnp_data.get("vnp_BankCode", ""))
    tag = "#".join(x for x in [bank_code, f"TXN={tx_no}" if tx_no else "", f"BANK={bank_no}" if bank_no else ""] if x)[:64]

    pay_time = datetime.utcnow()
    vnp_pay_date = vnp_data.get("vnp_PayDate")
    if vnp_pay_date and len(vnp_pay_date) == 14:
        pay_time = datetime(
            int(vnp_pay_date[0:4]), int(vnp_pay_date[4:6]), int(vnp_pay_date[6:8]),
            int(vnp_pay_date[8:10]), int(vnp_pay_date[10:12]), int(vnp_pay_date[12:14])
        )

    if not payment:
        payment = Payment(
            payment_id=payment_id,
            payment_method=PaymentMethod.chuyen_khoan.value,
            payment_account=tag,
            payment_time=pay_time,
            payment_status=PaymentStatus.da_thanh_toan.value,
        )
        db.add(payment)
    else:
        payment.payment_account = tag
        payment.payment_time = pay_time
        payment.payment_status = PaymentStatus.da_thanh_toan.value

    # Lấy order
    order = db.execute(
        select(Order).where(Order.order_id == order_id)
    ).scalar_one()

    # Tính tổng tiền + trừ kho
    items = db.execute(
        select(OrderDetail).where(OrderDetail.order_id == order_id)
    ).scalars().all()

    total = 0
    for it in items:
        try:
            unit_price = float(it.final_price or 0)
            qty = int(it.quantity_order or 0)
            total += unit_price * qty

            goods = db.execute(
                select(Goods).where(
                    Goods.ingredient_id == it.ingredient_id,
                    Goods.stall_id == it.stall_id,
                )
            ).scalar_one_or_none()

            if goods and goods.update_date:
                order_date = order.order_time or datetime.utcnow()
                if order_date >= goods.update_date:
                    goods.inventory = max((goods.inventory or 0) - qty, 0)
        except Exception as e:
            print("[MARK_PAID ITEM ERROR]", e)

    # Cập nhật order
    order.order_status = OrderStatus.da_xac_nhan.value
    order.total_amount = total
    order.payment_id = payment_id

    return order_id

