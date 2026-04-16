from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class StallFeeItem(BaseModel):
    stall_id: str
    stall_name: str
    user_name: str
    fee: float
    fee_status: str  # da_nop / chua_nop
    fee_id: Optional[str] = None
    payment_time: Optional[datetime] = None

class StallFeeListMeta(BaseModel):
    page: int
    limit: int
    total: int
    total_pages: int
    month: str

class StallFeeListResponse(BaseModel):
    success: bool
    data: List[StallFeeItem]
    total_collected: float
    meta: StallFeeListMeta

class StallFeeDetail(BaseModel):
    fee_id: str
    stall_id: str
    stall_name: str
    user_name: str
    address: str
    fee: float
    fee_status: str
    month: str

class StallFeeDetailResponse(BaseModel):
    success: bool
    data: StallFeeDetail

class StallFeeConfirmRequest(BaseModel):
    payment_method: str # tien_mat, chuyen_khoan
    note: Optional[str] = None
    amount: float
