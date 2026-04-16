from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from sqlalchemy.orm import Session
from typing import Optional, List
from app.config import settings
from app.database import get_db
from app.models.models import User

security = HTTPBearer()


class AuthUser:
    """Class chứa thông tin user đã xác thực"""
    def __init__(self, user_id: str, login_name: str, user_name: str, role: str):
        self.user_id = user_id
        self.login_name = login_name
        self.user_name = user_name
        self.role = role


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> AuthUser:
    """
    Middleware xác thực JWT token
    Tương đương với auth middleware trong Express
    """
    token = credentials.credentials
    
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token không hợp lệ hoặc đã hết hạn",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(
            token, 
            settings.JWT_SECRET, 
            algorithms=[settings.JWT_ALGORITHM]
        )
        user_id: str = payload.get("user_id") or payload.get("sub")
        
        if user_id is None:
            raise credentials_exception
            
    except JWTError:
        raise credentials_exception
    
    # Query user từ database
    user = db.query(User).filter(User.user_id == user_id).first()
    
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User không tồn tại"
        )
    
    return AuthUser(
        user_id=user.user_id,
        login_name=user.login_name,
        user_name=user.user_name,
        role=user.role
    )


def allow(*roles: str):
    """
    Decorator kiểm tra quyền truy cập
    Tương đương với allow middleware trong Express
    
    Usage:
        @router.get("/")
        async def endpoint(user: AuthUser = Depends(allow("nguoi_mua", "admin"))):
            ...
    """
    async def role_checker(
        current_user: AuthUser = Depends(get_current_user)
    ) -> AuthUser:
        if len(roles) == 0 or current_user.role in roles:
            return current_user
        
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Bạn không có quyền truy cập tài nguyên này"
        )
    
    return role_checker


# Shortcuts cho các role cụ thể
def buyer_required():
    return allow("nguoi_mua")

def seller_required():
    return allow("nguoi_ban")

def shipper_required():
    return allow("shipper")

def admin_required():
    return allow("admin")

def market_manager_required():
    return allow("quan_ly_cho")
