from pydantic import BaseModel, field_validator
from typing import Optional

VALID_LOAI_HANG = {"TH", "RC", "HS", "GV", "KH"}

class MerchantCreate(BaseModel):
    ten_nguoi_dung: str
    dia_chi: str
    so_dien_thoai: str
    loai_hang_hoa: str          # TH / RC / HS / GV / KH
    tien_thue_mac_dinh: float
    ghi_chu: Optional[str] = None
    grid_col: Optional[int] = 0
    grid_row: Optional[int] = 0

    @field_validator("loai_hang_hoa")
    @classmethod
    def validate_loai_hang(cls, v):
        if v not in VALID_LOAI_HANG:
            raise ValueError(f"loai_hang_hoa không hợp lệ. Chọn: {sorted(VALID_LOAI_HANG)}")
        return v

    @field_validator("tien_thue_mac_dinh")
    @classmethod
    def validate_tien_thue(cls, v):
        if v <= 0:
            raise ValueError("tien_thue_mac_dinh phải lớn hơn 0")
        return v

    @field_validator("so_dien_thoai")
    @classmethod
    def validate_sdt(cls, v):
        digits = v.replace("+84", "0").replace(" ", "")
        if not digits.isdigit() or len(digits) not in (10, 11):
            raise ValueError("Số điện thoại không hợp lệ (10-11 chữ số)")
        return digits
