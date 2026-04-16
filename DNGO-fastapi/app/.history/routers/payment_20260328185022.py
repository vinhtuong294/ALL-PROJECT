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
def vnp_return(request: Request, db: Session = Depends(get_db)):
    try:
        params = dict(request.query_params)
        print("VNPAY RETURN PARAMS:", params)

        return vnpay_return(db, params)

    except Exception as e:
        print("❌ VNPAY RETURN ERROR:", str(e))
        return {
            "status": "error",
            "message": str(e)
        }



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