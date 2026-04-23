from sqlalchemy import Column, String, Integer, Enum
from app.database import Base
import enum

# ================================
# BẢNG: users  <- tên bảng trong DB
# CÁC CỘT: theo tên tiếng Anh đã đổi
# ================================

class RoleEnum(str, enum.Enum):
    buyer = "nguoi_mua"
    seller = "nguoi_ban"
    shipper = "shipper"
    market_manager = "quan_ly_cho"
    admin = "admin"

class GenderEnum(str, enum.Enum):
    M = "M"
    F = "F"

class User(Base):
    __tablename__ = "users"  # tên bảng

    user_id = Column(String(6), primary_key=True, index=True)  # user_id
    login_name = Column(String(255), unique=True, nullable=False)  # login_name
    user_name = Column(String(255), nullable=False)  # user_name
    password = Column(String(255), nullable=False)  # password
    role = Column(Enum(RoleEnum), nullable=False)  # role
    gender = Column(Enum(GenderEnum), nullable=True)  # gender
    bank_account = Column(String(255), nullable=True)  # bank_account
    phone = Column(String(10), nullable=True)  # phone
    bank_name = Column(String(255), nullable=True)  # bank_name
    address = Column(String(255), nullable=True)  # address
    approval_status = Column(Integer, default=1, server_default='1')  # approval_status
