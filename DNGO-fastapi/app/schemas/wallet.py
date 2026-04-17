from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel


# ==================== CHI TIẾT TỪNG DÒNG ====================

class WalletDetailItem(BaseModel):
    loai: str
    # 'don_hang'     → buyer thanh toán / seller nhận / shipper nhận
    # 'hoan_hang'    → hoàn tiền
    # 'phi_gian_hang'→ phí gian hàng (chỉ platform)
    # 'tu_choi'      → buyer từ chối
    # 'huy_hang'     → buyer hủy
    huong: str          # 'vao' | 'ra'
    so_tien: int
    order_id: Optional[str] = None
    payment_id: Optional[str] = None
    fee_id: Optional[str] = None
    cancel_reason: Optional[str] = None
    detail_status: Optional[str] = None
    ngay: Optional[datetime] = None


# ==================== RESPONSE CHUNG ====================

class WalletBalanceResponse(BaseModel):
    wallet_id: str
    owner_id: str
    owner_type: str
    updated_wallet: Optional[datetime] = None
    tong_tien_vao: int
    tong_tien_ra: int
    so_du: int
    chi_tiet: list[WalletDetailItem]
    tien_dang_cho_rut: int = 0
    so_du_kha_dung: int = 0
    chi_tiet: list[WalletDetailItem]

class WithdrawRequestBody(BaseModel):
    amount: int
    bank_bin: str
    bank_account_no: str
    account_name: str
