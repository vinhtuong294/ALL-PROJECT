from fastapi import APIRouter, Depends, HTTPException, status, Request, Response, Cookie
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.user import User, RoleEnum
from app.schemas.auth import RegisterSchema, LoginSchema, UpdateProfileSchema, UserOutSchema, TokenSchema
from passlib.context import CryptContext
from jose import jwt, JWTError
import datetime

from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

router = APIRouter(tags=["Auth"])

# ====================
# Helpers
# ====================
def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def create_access_token(data: dict, expires_minutes: int = 30):
    to_encode = data.copy()
    expire = datetime.datetime.utcnow() + datetime.timedelta(minutes=expires_minutes)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: dict, expires_days: int = 7):
    to_encode = data.copy()
    expire = datetime.datetime.utcnow() + datetime.timedelta(days=expires_days)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt

def get_current_user(token: str = Depends(lambda request: request.headers.get("Authorization")), db: Session = Depends(get_db)):
    if not token or not token.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing token")
    token = token[7:]
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token invalid")
        user = db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
        return user
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token invalid or expired")
        
# ====================
# Routes
# ====================

@router.post("/register", response_model=TokenSchema)
def register(data: RegisterSchema, response: Response, db: Session = Depends(get_db)):
    # check username exists
    if db.query(User).filter(User.login_name == data.login_name).first():
        raise HTTPException(status_code=409, detail="login_name already exists")
    
    new_user = User(
        user_id=f"{datetime.datetime.utcnow().timestamp():.0f}"[:6],  # simple id gen
        login_name=data.login_name,
        password=hash_password(data.password),
        user_name=data.user_name,
        role=data.role,
        gender=data.gender,
        bank_account=data.bank_account,
        bank_name=data.bank_name,
        phone=data.phone,
        address=data.address
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    access_token = create_access_token({"sub": new_user.user_id, "role": new_user.role.value})
    refresh_token = create_refresh_token({"sub": new_user.user_id})
    response.set_cookie(key="rt", value=refresh_token, httponly=True)
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login", response_model=TokenSchema)
def login(data: LoginSchema, response: Response, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.login_name == data.login_name).first()
    if not user or not verify_password(data.password, user.password):
        raise HTTPException(status_code=401, detail="Incorrect login_name or password")
    
    access_token = create_access_token({"sub": user.user_id, "role": user.role.value})
    refresh_token = create_refresh_token({"sub": user.user_id})
    response.set_cookie(key="rt", value=refresh_token, httponly=True)
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserOutSchema)
def me(current_user: User = Depends(get_current_user)):
    return current_user

@router.patch("/me", response_model=UserOutSchema)
def update_profile(data: UpdateProfileSchema, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    for key, value in data.dict(exclude_unset=True).items():
        setattr(current_user, key, value)
    db.commit()
    db.refresh(current_user)
    return current_user

@router.post("/refresh", response_model=TokenSchema)
def refresh(rt: Optional[str] = Cookie(None), response: Response = None, db: Session = Depends(get_db)):
    if not rt:
        raise HTTPException(status_code=401, detail="Missing refresh token")
    try:
        payload = jwt.decode(rt, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        user = db.query(User).filter(User.user_id == payload.get("sub")).first()
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        new_access = create_access_token({"sub": user.user_id, "role": user.role.value})
        new_refresh = create_refresh_token({"sub": user.user_id})
        response.set_cookie(key="rt", value=new_refresh, httponly=True)
        return {"access_token": new_access, "token_type": "bearer"}
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

@router.post("/logout")
def logout(response: Response):
    response.delete_cookie("rt")
    return {"message": "Logged out"}
