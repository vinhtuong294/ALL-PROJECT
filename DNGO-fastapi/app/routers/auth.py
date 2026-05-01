from fastapi import APIRouter, Depends, HTTPException, status, Response, Cookie
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.schemas.auth import (
    RegisterRequest, LoginRequest, UpdateProfileRequest, ChangePasswordRequest,
    TokenResponse, MessageResponse, LoginHistoryListResponse
)
from app.repositories import auth as auth_repo
from app.utils.password import hash_password, verify_password
from app.utils.jwt import create_access_token, create_refresh_token, verify_refresh_token
from app.middlewares.auth import get_current_user, AuthUser

router = APIRouter(
    prefix="/api/auth",
    tags=["Authentication"]
)


# ==================== REGISTER ====================
@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(
    request: RegisterRequest,
    response: Response,
    db: Session = Depends(get_db)
):
    """Đăng ký tài khoản mới"""
    
    existing_user = auth_repo.find_user_by_login_name(db, request.login_name)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Tên đăng nhập đã tồn tại"
        )
    
    hashed_password = hash_password(request.password)
    
    created_user = auth_repo.create_user_with_role(
        db=db,
        login_name=request.login_name,
        password_hash=hashed_password,
        user_name=request.user_name,
        role=request.role,
        gender=request.gender,
        phone=request.phone,
        address=request.address,
        bank_account=request.bank_account,
        bank_name=request.bank_name,
        vehicle_plate=request.vehicle_plate,
        vehicle_type=request.vehicle_type,
        stall_name=request.stall_name,
        market_id=request.market_id,
        manager_id=request.manager_id,
        location=request.location
    )
    
    token_data = {
        "sub": created_user["user_id"],
        "user_id": created_user["user_id"],
        "role": created_user["role"],
        "login_name": created_user["login_name"],
        "user_name": created_user["user_name"]
    }
    
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token({"sub": created_user["user_id"]})
    
    response.set_cookie(
        key="rt",
        value=refresh_token,
        httponly=True,
        secure=True,
        samesite="lax",
        max_age=7 * 24 * 60 * 60
    )
    
    return {
        "data": token_data,
        "token": access_token
    }


# ==================== LOGIN ====================
@router.post("/login", response_model=TokenResponse)
def login(
    request: LoginRequest,
    response: Response,
    db: Session = Depends(get_db)
):
    """Đăng nhập"""
    
    user = auth_repo.find_user_by_login_name(db, request.login_name)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sai thông tin đăng nhập"
        )
    
    if not verify_password(request.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sai thông tin đăng nhập"
        )
    
    token_data = {
        "sub": user.user_id,
        "user_id": user.user_id,
        "role": user.role,
        "login_name": user.login_name,
        "user_name": user.user_name
    }
    
    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token({"sub": user.user_id})
    
    response.set_cookie(
        key="rt",
        value=refresh_token,
        httponly=True,
        secure=True,
        samesite="lax",
        max_age=7 * 24 * 60 * 60
    )
    
    # Ghi lại lịch sử đăng nhập
    auth_repo.create_login_history(
        db=db,
        user_id=user.user_id,
        device_info="Chrome/Flutter", # Sẽ lấy từ header sau nếu cần
        os_info="Web/MacOS",
        location="Đà Nẵng, Việt Nam", # Mặc định cho demo
        ip_address="127.0.0.1",
        success=True
    )
    
    # Thêm wallet_id + role-specific ID vào response data
    response_data = {**token_data}
    
    if user.role == "shipper":
        from app.models.models import Shipper, Wallet
        shipper = db.query(Shipper).filter(Shipper.user_id == user.user_id).first()
        if shipper:
            response_data["shipper_id"] = shipper.shipper_id
            wallet = db.query(Wallet).filter(Wallet.owner_id == shipper.shipper_id).first()
            if not wallet:
                wallet = auth_repo.create_wallet(db, owner_id=shipper.shipper_id, owner_type="shipper")
                db.commit()
                db.refresh(wallet)
            response_data["wallet_id"] = wallet.wallet_id
    elif user.role == "nguoi_mua":
        from app.models.models import Buyer, Wallet
        buyer = db.query(Buyer).filter(Buyer.user_id == user.user_id).first()
        if buyer:
            response_data["buyer_id"] = buyer.buyer_id
            wallet = db.query(Wallet).filter(Wallet.owner_id == buyer.buyer_id).first()
            if not wallet:
                wallet = auth_repo.create_wallet(db, owner_id=buyer.buyer_id, owner_type="buyer")
                db.commit()
                db.refresh(wallet)
            response_data["wallet_id"] = wallet.wallet_id
    elif user.role == "nguoi_ban":
        from app.models.models import Stall, Wallet
        stall = db.query(Stall).filter(Stall.user_id == user.user_id).first()
        if stall:
            response_data["stall_id"] = stall.stall_id
            wallet = db.query(Wallet).filter(Wallet.owner_id == stall.stall_id).first()
            response_data["wallet_id"] = wallet.wallet_id if wallet else None
    
    return {
        "data": response_data,
        "token": access_token
    }


# ==================== LOGIN HISTORY ====================
@router.get("/login-history", response_model=LoginHistoryListResponse)
def get_login_history(
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user)
):
    """Lấy lịch sử đăng nhập"""
    history = auth_repo.get_login_history(db, current_user.user_id)
    return {
        "status": "success",
        "data": history
    }


# ==================== ME ====================
@router.get("/me")
def get_me(
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user)
):
    """Lấy thông tin user hiện tại"""
    
    user_profile = auth_repo.get_user_profile(db, current_user.user_id)
    
    if not user_profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy người dùng"
        )
    
    return {"data": user_profile}


# ==================== UPDATE PROFILE ====================
@router.put("/profile")
def update_profile(
    request: UpdateProfileRequest,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user)
):
    """Cập nhật thông tin cá nhân"""
    
    update_data = request.model_dump(exclude_unset=True, by_alias=False)
    
    updated_user = auth_repo.update_user_profile(
        db=db,
        user_id=current_user.user_id,
        update_data=update_data
    )
    
    if not updated_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy người dùng"
        )
    
    return {"data": updated_user}


# ==================== CHANGE PASSWORD ====================
@router.post("/change-password", response_model=MessageResponse)
def change_password(
    request: ChangePasswordRequest,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user)
):
    """Thay đổi mật khẩu"""
    
    user = auth_repo.find_user_by_id(db, current_user.user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Không tìm thấy người dùng"
        )
    
    if not verify_password(request.old_password, user.password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mật khẩu cũ không chính xác"
        )
    
    hashed_password = hash_password(request.new_password)
    user.password = hashed_password
    db.commit()
    
    return {"message": "Thay đổi mật khẩu thành công"}


# ==================== REFRESH TOKEN ====================
@router.post("/refresh")
def refresh_token(
    response: Response,
    rt: Optional[str] = Cookie(None),
    db: Session = Depends(get_db)
):
    """Làm mới access token"""
    
    if not rt:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing refresh token"
        )
    
    payload = verify_refresh_token(rt)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token"
        )
    
    user_id = payload.get("sub")
    user = auth_repo.find_user_by_id(db, user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    token_data = {
        "sub": user.user_id,
        "user_id": user.user_id,
        "role": user.role,
        "login_name": user.login_name,
        "user_name": user.user_name
    }
    
    new_access_token = create_access_token(token_data)
    new_refresh_token = create_refresh_token({"sub": user.user_id})
    
    response.set_cookie(
        key="rt",
        value=new_refresh_token,
        httponly=True,
        secure=True,
        samesite="lax",
        max_age=7 * 24 * 60 * 60
    )
    
    return {"token": new_access_token}


# ==================== LOGOUT ====================
@router.post("/logout", response_model=MessageResponse)
def logout(response: Response):
    """Đăng xuất"""
    
    response.delete_cookie(key="rt")
    
    return {"message": "Đã đăng xuất"}