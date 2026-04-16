# Thêm import ở đầu file
from app.routers import auth, buyer

# Thêm router auth (sau dòng app.include_router(buyer.router))
app.include_router(auth.router)
app.include_router(buyer.router)