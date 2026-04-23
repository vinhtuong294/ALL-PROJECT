from pydantic import BaseModel, Field, constr, validator
from typing import Optional
from app.models.user import RoleEnum, GenderEnum

strong_password = constr(min_length=8, max_length=128, regex=r'^(?=.*[A-Za-z])(?=.*\d).+$')

# REGISTER
class RegisterSchema(BaseModel):
    username: constr(min_length=3, max_length=50)
    password: strong_password
    full_name: constr(min_length=1, max_length=255)
    role: RoleEnum
    gender: Optional[GenderEnum]
    account_number: Optional[str]
    bank_name: Optional[str]
    phone: Optional[str]
    address: Optional[str]

# LOGIN
class LoginSchema(BaseModel):
    username: str
    password: str

# UPDATE PROFILE
class UpdateProfileSchema(BaseModel):
    full_name: Optional[str]
    gender: Optional[GenderEnum]
    phone: Optional[str]
    address: Optional[str]
    account_number: Optional[str]
    bank_name: Optional[str]

    @validator('*')
    def not_empty(cls, v):
        if v is not None and v == "":
            raise ValueError("Cannot be empty string")
        return v
