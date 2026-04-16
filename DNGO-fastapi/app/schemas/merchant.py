from pydantic import BaseModel
from typing import Optional

class MerchantCreate(BaseModel):
    ten_nguoi_dung: str
    dia_chi: str
    so_dien_thoai: str
    ma_gian_hang: str
    loai_hang_hoa: str
    tien_thue_mac_dinh: float
    ghi_chu: Optional[str] = None
    grid_col: Optional[int] = 0
    grid_row: Optional[int] = 0
