from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session


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


router = APIRouter(prefix="/api/payment", tags=["Payment"])




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


@router.get("/vnpay/return", response_model=VNPayReturnResponse)
def vnpay_return(db: Session, params: dict):
    try:
        from fastapi import HTTPException
        if not verify_signature(params):
            raise HTTPException(400, "INVALID_SIGNATURE")

        payment_id = str(params.get("vnp_TxnRef", "")).strip()
        response = params.get("vnp_ResponseCode")

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

        # Thanh toán thất bại
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