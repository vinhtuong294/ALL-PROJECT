from pydantic import BaseModel, Field, constr
from typing import Optional
from enum import Enum

class RoleEnum(str, Enum):
    buyer = "nguoi_mua"
    seller = "nguoi_ban"
    shipper = "shipper"
    market_manager = "quan_ly_cho"
    admin = "admin"

class GenderEnum(str, Enum):
    M = "M"
    F = "F"

# Input schemas
class RegisterSchema(BaseModel):
    login_name: str = Field(..., min_length=3, max_length=50)
    password: constr(min_length=8)  # simple validation, you can add regex
    user_name: str = Field(..., min_length=1, max_length=100)
    role: RoleEnum
    gender: Optional[GenderEnum]
    bank_account: Optional[str]
    bank_name: Optional[str]
    phone: Optional[str]
    address: Optional[str]

class LoginSchema(BaseModel):
    login_name: str
    password: str

class UpdateProfileSchema(BaseModel):
    user_name: Optional[str]
    gender: Optional[GenderEnum]
    bank_account: Optional[str]
    bank_name: Optional[str]
    phone: Optional[str]
    address: Optional[str]

# Output schemas
class TokenSchema(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UserOutSchema(BaseModel):
    user_id: str
    login_name: str
    user_name: str
    role: RoleEnum
