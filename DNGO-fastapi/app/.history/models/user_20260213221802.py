from sqlalchemy import Column, String, Enum, Integer, SmallInteger
from app.database import Base
import enum

# ================================
# BẢNG: users
# CÁC CỘT: tiếng Anh
# ================================

class RoleEnum(str, enum.Enum):
    buyer = "nguoi_mua"
    seller = "nguoi_ban"
    shipper = "shipper"
    manager = "quan_ly_cho"
    admin = "admin"

class GenderEnum(str, enum.Enum):
    M = "M"
    F = "F"

class User(Base):
    __tablename__ = "users"

    user_id = Column(String(6), primary_key=True, index=True)        # user_id
    username = Column(String(255), unique=True, nullable=False)      # login_name
    full_name = Column(String(255), nullable=False)                  # user_name
    password = Column(String(255), nullable=False)                   # password
    role = Column(Enum(RoleEnum), nullable=False)                    # role
    gender = Column(Enum(GenderEnum), nullable=False)                # gender
    account_number = Column(String(255), nullable=False)             # bank_account
    bank_name = Column(String(255), nullable=False)                  # bank_name
    phone = Column(String(10), nullable=False)                       # phone
    address = Column(String(255), nullable=False)                    # address
    approval_status = Column(SmallInteger, default=0)                # approval_status
