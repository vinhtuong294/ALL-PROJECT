# app/services/payment.py


import re
from datetime import datetime
from fastapi import HTTPException, Request
from sqlalchemy.orm import Session
from sqlalchemy import select, update
from app.utils.distance import calculate_distance
from sqlalchemy import select
from app.models import Market


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
from app.repositories.payment import _mark_paid



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

def vnpay_return(db: Session, params: dict):
    try:
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
                "success": True,
                "message": "Thanh toán thành công",
                "order_id": order_id,
                "clear_cart": True,
            }

        db.execute(
            update(Payment)
            .where(Payment.payment_id == payment_id)
            .values(payment_status=PaymentStatus.chua_thanh_toan.value)
        )
        db.commit()
        return {"success": False, "message": "Thanh toán thất bại", "code": response}

    except Exception as e:
        import traceback
        print("[VNPAY RETURN ERROR]", e)
        traceback.print_exc()
        raise HTTPException(500, f"Server error: {e}")

