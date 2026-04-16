from sqlalchemy.orm import Session
from typing import Optional, Dict, Any
import random
import string

from app.models.models import User, Buyer, Shipper, Stall


def generate_user_id() -> str:
    """Tạo user_id ngẫu nhiên 6 ký tự: ND + 4 ký tự"""
    chars = string.ascii_uppercase + string.digits
    random_part = ''.join(random.choices(chars, k=4))
    return f"ND{random_part}"


def generate_buyer_id() -> str:
    """Tạo buyer_id ngẫu nhiên 8 ký tự: NM + 6 ký tự"""
    chars = string.ascii_uppercase + string.digits
    random_part = ''.join(random.choices(chars, k=6))
    return f"NM{random_part}"


def generate_shipper_id() -> str:
    """Tạo shipper_id ngẫu nhiên 8 ký tự: SP + 6 ký tự"""
    chars = string.ascii_uppercase + string.digits
    random_part = ''.join(random.choices(chars, k=6))
    return f"SP{random_part}"


def generate_stall_id() -> str:
    """Tạo stall_id ngẫu nhiên 8 ký tự: GH + 6 ký tự"""
    chars = string.ascii_uppercase + string.digits
    random_part = ''.join(random.choices(chars, k=6))
    return f"GH{random_part}"


def find_user_by_login_name(db: Session, login_name: str) -> Optional[User]:
    """Tìm user theo login_name"""
    return db.query(User).filter(User.login_name == login_name).first()


def find_user_by_id(db: Session, user_id: str) -> Optional[User]:
    """Tìm user theo user_id"""
    return db.query(User).filter(User.user_id == user_id).first()

def generate_manage_id() -> str:
    """Tạo manage_id ngẫu nhiên 8 ký tự: QL + 6 ký tự"""
    chars = string.ascii_uppercase + string.digits
    random_part = ''.join(random.choices(chars, k=6))
    return f"QL{random_part}"


def create_user_with_role(
    db: Session,
    login_name: str,
    password_hash: str,
    user_name: str,
    role: str,
    gender: str,
    phone: str,
    address: str,
    bank_account: Optional[str] = None,
    bank_name: Optional[str] = None,
    vehicle_plate: Optional[str] = None,
    vehicle_type: Optional[str] = None,
    stall_name: Optional[str] = None,
    market_id: Optional[str] = None,
    manager_id: Optional[str] = None,
    location: Optional[str] = None
) -> Dict[str, Any]:
    """Tạo user mới với role tương ứng"""
    
    user_id = generate_user_id()
    while find_user_by_id(db, user_id):
        user_id = generate_user_id()
    
    new_user = User(
        user_id=user_id,
        login_name=login_name,
        user_name=user_name,
        password=password_hash,
        role=role,
        gender=gender,
        phone=phone,
        address=address,
        bank_account=bank_account or "",
        bank_name=bank_name or "",
        approval_status=0
    )
    db.add(new_user)
    
    result_role = role
    
    if role == "nguoi_mua":
        buyer_id = generate_buyer_id()
        new_buyer = Buyer(
            buyer_id=buyer_id,
            user_id=user_id,
            weight=None,
            height=None
        )
        db.add(new_buyer)
        
    elif role == "shipper":
        shipper_id = generate_shipper_id()
        new_shipper = Shipper(
            shipper_id=shipper_id,
            user_id=user_id,
            vehicle_type=vehicle_type or "",
            vehicle_plate=vehicle_plate or ""
        )
        db.add(new_shipper)
        
    elif role == "nguoi_ban":
        if stall_name and market_id:
            from datetime import date
            stall_id = generate_stall_id()
            new_stall = Stall(
                stall_id=stall_id,
                stall_name=stall_name,
                market_id=market_id,
                user_id=user_id,
                manage_id=manager_id,
                stall_location=location or "",
                stall_image=None,
                avr_rating=None,
                signup_date=date.today(),
                grid_col=None,
                grid_row=None
            )
            db.add(new_stall)

    elif role == "quan_ly_cho":
        if market_id:
            from app.models.models import MarketManagement
            manage_id = generate_manage_id()
            new_manage = MarketManagement(
                manage_id=manage_id,
                market_id=market_id,
                user_id=user_id
            )
            db.add(new_manage)
    
    db.commit()
    db.refresh(new_user)
    
    return {
        "user_id": user_id,
        "login_name": login_name,
        "user_name": user_name,
        "role": result_role
    }

def update_user_profile(
    db: Session,
    user_id: str,
    update_data: Dict[str, Any]
) -> Optional[User]:
    """Cập nhật thông tin user"""
    
    user = find_user_by_id(db, user_id)
    if not user:
        return None
    
    allowed_fields = ["user_name", "gender", "phone", "address", "bank_account", "bank_name"]
    
    for field, value in update_data.items():
        if field in allowed_fields and value is not None:
            setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    
    return user


def get_user_profile(db: Session, user_id: str) -> Optional[Dict[str, Any]]:
    """Lấy thông tin đầy đủ của user"""
    
    user = find_user_by_id(db, user_id)
    if not user:
        return None
    
    result = {
        "user_id": user.user_id,
        "login_name": user.login_name,
        "user_name": user.user_name,
        "role": user.role,
        "gender": user.gender,
        "phone": user.phone,
        "address": user.address,
        "bank_account": user.bank_account,
        "bank_name": user.bank_name,
        "approval_status": user.approval_status
    }
    
    if user.role == "nguoi_mua":
        buyer = db.query(Buyer).filter(Buyer.user_id == user_id).first()
        if buyer:
            result["buyer_id"] = buyer.buyer_id
            result["weight"] = buyer.weight
            result["height"] = buyer.height
            
    elif user.role == "shipper":
        shipper = db.query(Shipper).filter(Shipper.user_id == user_id).first()
        if shipper:
            result["shipper_id"] = shipper.shipper_id
            result["vehicle_type"] = shipper.vehicle_type
            result["vehicle_plate"] = shipper.vehicle_plate
            
    elif user.role == "nguoi_ban":
        stall = db.query(Stall).filter(Stall.user_id == user_id).first()
        if stall:
            result["stall_id"] = stall.stall_id
            result["stall_name"] = stall.stall_name
            result["market_id"] = stall.market_id
    elif user.role == "quan_ly_cho":
        from app.models.models import MarketManagement
        manage = db.query(MarketManagement).filter(MarketManagement.user_id == user_id).first()
        if manage:
            result["manage_id"] = manage.manage_id
            result["market_id"] = manage.market_id
    
    return result
