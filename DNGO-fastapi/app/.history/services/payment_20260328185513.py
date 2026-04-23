# app/services/payment.py


import re
from datetime import datetime
from fastapi import HTTPException, Request
from sqlalchemy.orm import Session
from sqlalchemy import select, update


from app.models import (
    Order, Payment, OrderDetail, Goods,
    Buyer, User,
    PaymentStatus, OrderStatus, PaymentMethod,
)
from app.utils.vnpay import verify_signature, verify_signature_debug
from app.utils.shipping import (
    determine_shipping_address,
    format_shipping_address,
    parse_shipping_address,
)
from app.repositories.payment import build_vnpay_url




# =====================================================
# HELPER
# =====================================================


def _parse_vnp_date(s: str | None) -> datetime:
    """Chuyển chuỗi yyyyMMddHHmmss của VNPay thành datetime."""
    if not s or len(s) != 14:
        return datetime.utcnow()
    return datetime(
        int(s[0:4]), int(s[4:6]),  int(s[6:8]),
        int(s[8:10]), int(s[10:12]), int(s[12:14]),
    )




# =====================================================
# CHECKOUT
# =====================================================


def vnpay_checkout(
    db: Session,
    request: Request,
    user,
    payload: dict,
):
    order_id  = payload.get("order_id")
    bank_code = payload.get("bankCode")


    if not order_id:
        raise HTTPException(400, "order_id is required")


    # Lấy buyer từ user đang đăng nhập
    buyer = db.query(Buyer).filter(Buyer.user_id == user.user_id).first()
    if not buyer:
        raise HTTPException(403, "USER_NOT_BUYER")


    # Lấy đơn hàng
    order = db.query(Order).filter(Order.order_id == order_id).first()
    if not order:
        raise HTTPException(404, "ORDER_NOT_FOUND")


    # Kiểm tra quyền
    if str(order.buyer_id).strip() != str(buyer.buyer_id).strip():
        raise HTTPException(403, "FORBIDDEN_ORDER")


    # ===== Xử lý địa chỉ giao hàng =====
    saved_address = parse_shipping_address(order.delivery_address)
    user_profile  = None


    if not saved_address:
        buyer_obj = db.execute(
            select(Buyer).where(Buyer.buyer_id == order.buyer_id)
        ).scalar_one_or_none()


        if buyer_obj:
            user_obj = db.execute(
                select(User).where(User.user_id == buyer_obj.user_id)
            ).scalar_one_or_none()


            if user_obj:
                user_profile = {
                    "ten_nguoi_dung": user_obj.user_name,
                    "sdt":            user_obj.phone,
                    "dia_chi":        user_obj.address,
                }


    shipping_info = determine_shipping_address(
        saved_address=saved_address,
        user_profile=user_profile,
    )


    if not shipping_info["name"] or not shipping_info["phone"] or not shipping_info["address"]:
        raise HTTPException(400, "MISSING_SHIPPING_INFO")


    order.delivery_address = format_shipping_address(shipping_info)
    db.commit()


    # ===== Tạo URL VNPay =====
    client_ip = request.client.host if request.client else "127.0.0.1"


    try:
        pay_data = build_vnpay_url(
            db=db,
            order_id=order_id,
            client_ip=client_ip,
            bank_code=bank_code,
        )
    except Exception as e:
        msg = str(e)
        if msg == "ORDER_LOCKED":
            raise HTTPException(409, "Đơn đã xác nhận hoặc đã thanh toán.")
        if msg == "ORDER_AMOUNT_INVALID":
            raise HTTPException(400, "ORDER_AMOUNT_INVALID")
        raise HTTPException(400, msg)


    return {
        "success":    True,
        "redirect":   pay_data["payUrl"],
        "payment_id": pay_data["payment_id"],
        "amount":     pay_data["amount"],
    }




# =====================================================
# MARK PAID  (dùng chung cho return + IPN)
# =====================================================


def _mark_paid(db: Session, payment_id: str, vnp_data: dict) -> str:
    """
    Đánh dấu thanh toán thành công:
    - Cập nhật Payment → da_thanh_toan
    - Cập nhật Order   → da_xac_nhan + tong_tien
    - Trừ tồn kho Goods
    Trả về order_id.
    """
    # Tìm order_id từ payment hoặc từ vnp_OrderInfo
    order_id_from_info = None
    info = str(vnp_data.get("vnp_OrderInfo", "")).strip()
    m = re.search(r"don\s+([A-Z0-9_-]+)", info, re.I)
    if m:
        order_id_from_info = m.group(1)


    payment = db.execute(
        select(Payment).where(Payment.payment_id == payment_id)
    ).scalar_one_or_none()


    order_id = None
    if payment and payment.orders:
        order_id = payment.orders[0].order_id
    if not order_id and order_id_from_info:
        order_id = order_id_from_info
    if not order_id:
        raise Exception("ORDER_ID_NOT_FOUND")


    # Idempotent: đã thanh toán rồi thì bỏ qua
    if payment and payment.payment_status == PaymentStatus.da_thanh_toan.value:
        return order_id


    # Tạo tag lưu thông tin ngân hàng
    tx_no    = str(vnp_data.get("vnp_TransactionNo", ""))
    bank_no  = str(vnp_data.get("vnp_BankTranNo", ""))
    bank_code = str(vnp_data.get("vnp_BankCode", ""))
    tag = "#".join(
        x for x in [
            bank_code,
            f"TXN={tx_no}"  if tx_no   else "",
            f"BANK={bank_no}" if bank_no else "",
        ] if x
    )[:64]


    pay_time = _parse_vnp_date(vnp_data.get("vnp_PayDate"))


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
        payment.payment_time    = pay_time
        payment.payment_status  = PaymentStatus.da_thanh_toan.value
    # ✅ Lấy order trước
    order = db.execute(
        select(Order).where(Order.order_id == order_id)
    ).scalar_one()

    # Tính tổng tiền + trừ kho
    items = db.execute(
        select(OrderDetail).where(OrderDetail.order_id == order_id)
    ).scalars().all()


    total = 0
    for it in items:
        unit_price = float(it.final_price or 0)
        qty        = int(it.quantity_order or 0)
        total     += unit_price * qty


        goods = db.execute(
            select(Goods).where(
                Goods.ingredient_id == it.ingredient_id,
                Goods.stall_id      == it.stall_id,
            )
        ).scalar_one_or_none()


        if goods:
            order_date = order.order_time or datetime.utcnow()
            if goods.update_date and order_date >= goods.update_date:
                goods.inventory -= qty


    # Cập nhật Order
    order = db.execute(
        select(Order).where(Order.order_id == order_id)
    ).scalar_one()


    order.order_status = OrderStatus.da_xac_nhan.value
    order.total_amount = total
    order.payment_id   = payment_id


    return order_id




# =====================================================
# RETURN  (VNPay redirect trình duyệt về đây)
# =====================================================


def vnpay_return(db: Session, params: dict):
    if not verify_signature(params):
        raise HTTPException(400, "INVALID_SIGNATURE")


    payment_id = str(params.get("vnp_TxnRef", "")).strip()
    response   = params.get("vnp_ResponseCode")


    if not payment_id:
        raise HTTPException(400, "MISSING_TXN_REF")


    if response == "00":
        order_id = _mark_paid(db, payment_id, params)
        db.commit()
        return {
            "success":    True,
            "message":    "Thanh toán thành công",
            "order_id":   order_id,
            "clear_cart": True,
        }


    # Thanh toán thất bại
    db.execute(
        update(Payment)
        .where(Payment.payment_id == payment_id)
        .values(payment_status=PaymentStatus.chua_thanh_toan.value)
    )
    db.commit()


    return {
        "success": False,
        "message": "Thanh toán thất bại",
        "code":    response,
    }




# =====================================================
# IPN  (VNPay gọi ngầm phía server)
# =====================================================


def vnpay_ipn(db: Session, params: dict):
    if not verify_signature(params):
        dbg = verify_signature_debug(params)
        print("[IPN VERIFY FAIL]", dbg)
        return {"RspCode": "97", "Message": "Invalid signature"}


    payment_id = str(params.get("vnp_TxnRef", "")).strip()
    response   = params.get("vnp_ResponseCode")


    if not payment_id:
        return {"RspCode": "01", "Message": "Missing TxnRef"}


    try:
        if response == "00":
            _mark_paid(db, payment_id, params)
            db.commit()
            return {"RspCode": "00", "Message": "Confirm Success"}


        # Thanh toán thất bại
        db.execute(
            update(Payment)
            .where(Payment.payment_id == payment_id)
            .values(payment_status=PaymentStatus.chua_thanh_toan.value)
        )
        db.commit()
        # ✅ Trả "00" để báo VNPay đã nhận, nhưng message rõ là Fail
        return {"RspCode": "00", "Message": "Confirm Fail"}


    except Exception as e:
        print("[IPN ERROR]", e)
        return {"RspCode": "99", "Message": "Unknown error"}




