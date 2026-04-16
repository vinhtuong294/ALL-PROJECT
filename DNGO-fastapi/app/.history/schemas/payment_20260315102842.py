# app/schemas/payment.py


from pydantic import BaseModel, Field
from typing import Optional




# =====================================================
# REQUEST SCHEMAS
# =====================================================


class VNPayCheckoutRequest(BaseModel):
    order_id: str
    bankCode: Optional[str] = None
# =====================================================
# RESPONSE SCHEMAS
# =====================================================


class VNPayCheckoutResponse(BaseModel):
    success: bool
    redirect: str
    payment_id: str
    amount: float




class VNPayReturnResponse(BaseModel):
    success: bool
    message: str
    order_id: Optional[str] = None
    clear_cart: Optional[bool] = None
    code: Optional[str] = None




class VNPayIPNResponse(BaseModel):
    RspCode: str
    Message: str