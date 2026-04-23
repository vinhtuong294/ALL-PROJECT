from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from app.utils.scheduler import start_scheduler, auto_create_monthly_fees
from contextlib import asynccontextmanager
import time
import logging




from app.config import settings


from dotenv import load_dotenv
load_dotenv()


# Setup logging
logging.basicConfig(
    level=logging.DEBUG if settings.DEBUG else logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)








@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup và shutdown events"""
    logger.info("🚀 Starting DNGO API Server...")
    logger.info(f"🔐 CORS Origins: {settings.cors_origins_list}")
    yield
    logger.info("👋 Shutting down DNGO API Server...")








# Khởi tạo FastAPI app
app = FastAPI(
    title="DNGO API - Đi Chợ Online",
    description="API cho hệ thống đi chợ online",
    version="2.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)




# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)








# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
   
    logger.info({
        "method": request.method,
        "url": str(request.url.path),
        "status": response.status_code,
        "duration": f"{process_time * 1000:.2f}ms"
    })
   
    return response








# Health check
@app.get("/health", tags=["Health"])
async def health_check():
    """Kiểm tra server hoạt động"""
    return {
        "status": "ok",
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "version": "2.0.0"
    }








# Database ping
@app.get("/db/ping", tags=["Health"])
async def db_ping():
    """Kiểm tra kết nối database"""
    from app.database import SessionLocal
    from sqlalchemy import text
    try:
        db = SessionLocal()
        result = db.execute(text("SELECT 1")).fetchone()
        db.close()
        return {
            "status": "ok",
            "database": "PostgreSQL",
            "connected": True
        }
    except Exception as e:
        return {
            "status": "error",
            "database": "PostgreSQL",
            "connected": False,
            "error": str(e)
        }








# Import và include routers
from app.routers import auth, buyer, cart, order, review, search, seller,payment, shipper, upload, market_management


app.include_router(auth.router)
app.include_router(buyer.router)
app.include_router(cart.router)
app.include_router(order.router)
app.include_router(review.router)
app.include_router(search.router)
app.include_router(seller.router)
app.include_router(payment.router)
app.include_router(shipper.router)
app.include_router(upload.router)
app.include_router(market_management.router)

# Mount folder uploads để truy cập ảnh qua URL
import os
uploads_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "uploads")
if not os.path.exists(uploads_dir):
    os.makedirs(uploads_dir)
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")


# 404 handler
@app.api_route("/{path_name:path}", methods=["GET", "POST", "PUT", "DELETE", "PATCH"], include_in_schema=False)
async def catch_all(path_name: str):
    return JSONResponse(
        status_code=404,
        content={"success": False, "message": "Endpoint not found"}
    )








if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=settings.DEBUG
    )


# Trong hàm startup
@app.on_event("startup")
async def startup_event():
    start_scheduler()
    # Tự động sinh phí ngay khi khởi động nếu chưa có tháng này
    auto_create_monthly_fees()