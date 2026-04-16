from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime


# ==================== REQUEST SCHEMAS ====================

class RegisterRequest(BaseModel):
    login_name: str = Field(..., min_length=3, max_length=255, alias="ten_dang_nhap")
    password: str = Field(..., min_length=6, max_length=255, alias="mat_khau")
    user_name: str = Field(..., min_length=1, max_length=255, alias="ten_nguoi_dung")
    role: str = Field(..., pattern="^(nguoi_mua|nguoi_ban|shipper|quan_ly_cho|admin)$")
    gender: str = Field(..., max_length=1, alias="gioi_tinh")
    phone: str = Field(..., min_length=10, max_length=10, alias="sdt")
    address: str = Field(..., max_length=255, alias="dia_chi")
    bank_account: Optional[str] = Field(None, max_length=255, alias="so_tai_khoan")
    bank_name: Optional[str] = Field(None, max_length=255, alias="ngan_hang")
    
    # Cho shipper
    vehicle_plate: Optional[str] = Field(None, alias="bien_so_xe")
    vehicle_type: Optional[str] = Field(None, alias="phuong_tien")
    
    # Cho người bán (gian hàng)
    stall_name: Optional[str] = Field(None, alias="ten_gian_hang")
    market_id: Optional[str] = Field(None, alias="ma_cho")
    manager_id: Optional[str] = Field(None, alias="ma_quan_ly")
    location: Optional[str] = Field(None, alias="vi_tri")
    
    class Config:
        populate_by_name = True

class LoginRequest(BaseModel):
    login_name: str = Field(..., alias="ten_dang_nhap")
    password: str = Field(..., alias="mat_khau")

    class Config:
        populate_by_name = True


class UpdateProfileRequest(BaseModel):
    user_name: Optional[str] = Field(None, max_length=255, alias="ten_nguoi_dung")
    gender: Optional[str] = Field(None, max_length=1, alias="gioi_tinh")
    phone: Optional[str] = Field(None, max_length=10, alias="sdt")
    address: Optional[str] = Field(None, max_length=255, alias="dia_chi")
    bank_account: Optional[str] = Field(None, max_length=255, alias="so_tai_khoan")
    bank_name: Optional[str] = Field(None, max_length=255, alias="ngan_hang")
    
    class Config:
        populate_by_name = True


class ChangePasswordRequest(BaseModel):
    old_password: str = Field(..., alias="mat_khau_cu")
    new_password: str = Field(..., min_length=6, alias="mat_khau_moi")

    class Config:
        populate_by_name = True


# ==================== RESPONSE SCHEMAS ====================

class UserResponse(BaseModel):
    user_id: str = Field(..., alias="ma_nguoi_dung")
    login_name: str = Field(..., alias="ten_dang_nhap")
    user_name: str = Field(..., alias="ten_nguoi_dung")
    role: str = Field(..., alias="vai_tro")
    gender: str = Field(..., alias="gioi_tinh")
    phone: str = Field(..., alias="sdt")
    address: str = Field(..., alias="dia_chi")
    bank_account: Optional[str] = Field(None, alias="so_tai_khoan")
    bank_name: Optional[str] = Field(None, alias="ngan_hang")
    market_name: Optional[str] = Field(None, alias="ten_cho")
    approval_status: int = Field(0, alias="tinh_trang")
    
    class Config:
        populate_by_name = True
        from_attributes = True


class TokenResponse(BaseModel):
    data: dict
    token: str


class MessageResponse(BaseModel):
    message: str


class LoginHistoryResponse(BaseModel):
    id: int
    user_id: str = Field(..., alias="ma_nguoi_dung")
    device_info: Optional[str] = Field(None, alias="thiet_bi")
    os_info: Optional[str] = Field(None, alias="he_dieu_hanh")
    location: Optional[str] = Field(None, alias="vi_tri")
    ip_address: Optional[str] = Field(None, alias="dia_chi_ip")
    login_time: datetime = Field(..., alias="thoi_gian")
    success: bool = Field(True, alias="thanh_cong")

    class Config:
        populate_by_name = True
        from_attributes = True


class LoginHistoryListResponse(BaseModel):
    status: str
    data: list[LoginHistoryResponse]