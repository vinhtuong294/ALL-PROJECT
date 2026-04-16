from passlib.context import CryptContext

# Cấu hình bcrypt để hash password
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Hash password với bcrypt"""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """So sánh password với hash"""
    return pwd_context.verify(plain_password, hashed_password)