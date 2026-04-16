from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from fastapi import APIRouter, Depends, Request, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import update
from fastapi.responses import JSONResponse
from app.repositories.payment import _mark_paid

from app.database import get_db
from app.models import Payment, PaymentStatus
from app.utils.vnpay import verify_signature, verify_signature_debug

from app.database import get_db
from app.schemas.payment import (
    VNPayCheckoutRequest,
    VNPayCheckoutResponse,
    VNPayReturnResponse,
    VNPayIPNResponse,
)
from app.middlewares.auth import get_current_user
from app.services.payment import (
    vnpay_checkout,
    vnpay_return,
    vnpay_ipn,
)


router = APIRouter()



@router.post("/vnpay/checkout", response_model=VNPayCheckoutResponse)
def checkout_vnpay(
    payload: VNPayCheckoutRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    return vnpay_checkout(
        db=db,
        request=request,
        user=current_user,
        payload=payload.model_dump(),
    )




@router.get("/vnpay/return", response_model=None)
def vnpay_return_route(request: Request, db: Session = Depends(get_db)):
    try:
        params = dict(request.query_params)
        print("VNPAY PARAMS:", params)  # 🔥 debug cực quan trọng

        dbg = verify_signature_debug(params)
        print("[VNPAY RETURN DEBUG]", dbg)  # 🔥 xem sign_data, expected, client hash

        # 1. Verify signature (KHÔNG raise)
        if not verify_signature(params):
            return JSONResponse({
                "success": False,
                "message": "Sai chữ ký"
            })

        payment_id = str(params.get("vnp_TxnRef", "")).strip()
        response_code = params.get("vnp_ResponseCode")

        if not payment_id:
            return JSONResponse({
                "success": False,
                "message": "Thiếu payment_id"
            })

        # 2. Thanh toán thành công
        if response_code == "00":
            try:
                order_id = _mark_paid(db, payment_id, params)
                db.commit()
            except Exception as e:
                print("MARK PAID ERROR:", e)
                db.rollback()
                return JSONResponse({
                    "success": False,
                    "message": f"Lỗi update DB: {e}"
                })

            return JSONResponse({
                "success": True,
                "message": "Thanh toán thành công",
                "order_id": order_id,
                "clear_cart": True
            })

        # 3. Thanh toán thất bại
        try:
            db.execute(
                update(Payment)
                .where(Payment.payment_id == payment_id)
                .values(payment_status=PaymentStatus.chua_thanh_toan.value)
            )
            db.commit()
        except Exception as e:
            print("UPDATE FAIL ERROR:", e)
            db.rollback()

        return JSONResponse({
            "success": False,
            "message": "Thanh toán thất bại",
            "code": response_code
        })

    except Exception as e:
        import traceback
        print("[VNPAY RETURN ERROR]", e)
        traceback.print_exc()

        # ❗ KHÔNG raise nữa
        return JSONResponse({
            "success": False,
            "message": f"Server error: {str(e)}"
        })

@router.get("/vnpay/ipn")
def vnp_ipn_get(request: Request, db: Session = Depends(get_db)):
    try:
        params = dict(request.query_params)
        print("VNPAY IPN:", params)

        return vnpay_ipn(db, params)

    except Exception as e:
        print("❌ VNPAY IPN ERROR:", str(e))
        return {"RspCode": "99", "Message": str(e)}



@router.post("/vnpay/ipn", response_model=VNPayIPNResponse)
def vnp_ipn_post(request: Request, db: Session = Depends(get_db)):
    return vnpay_ipn(db, dict(request.query_params))