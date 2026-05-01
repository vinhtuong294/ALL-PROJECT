from dotenv import load_dotenv
import pathlib as _pathlib
# Load .env from the project root (DNGO-fastapi/) regardless of CWD — needed when uvicorn --reload respawns the server process
_env_path = _pathlib.Path(__file__).resolve().parent.parent / ".env"
load_dotenv(dotenv_path=_env_path)

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from app.utils.scheduler import start_scheduler, auto_create_monthly_fees
from contextlib import asynccontextmanager
import time
import logging
import os
import random, string

from app.config import settings

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

    # Scheduler
    start_scheduler()
    auto_create_monthly_fees()

    # Firebase
    try:
        from app.firebase_client import init_firebase
        init_firebase()
        logger.info("✅ Firebase initialized")
    except Exception as e:
        logger.warning(f"⚠️ Firebase init failed: {e}")

    # Create new tables if not exist
    try:
        from app.database import engine, Base
        from app.models.models import DeliveryProof, FailedDeliveryReport, WithdrawalRequest, Notification
        Base.metadata.create_all(bind=engine, tables=[
            DeliveryProof.__table__,
            FailedDeliveryReport.__table__,
            WithdrawalRequest.__table__,
            Notification.__table__,
        ], checkfirst=True)
        logger.info("✅ Tables checked/created")
    except Exception as e:
        logger.warning(f"⚠️ Create table failed: {e}")

    # Create platform wallet
    from app.database import SessionLocal
    from app.models.models import Wallet, TimeSlot
    from datetime import time as dtime

    db = SessionLocal()
    try:
        existing = db.query(Wallet).filter(
            Wallet.owner_id == "PLATFORM",
            Wallet.owner_type == "platform"
        ).first()
        if not existing:
            wallet_id = "WL" + ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))
            db.add(Wallet(
                wallet_id=wallet_id,
                owner_id="PLATFORM",
                owner_type="platform"
            ))
            db.commit()
            logger.info(f"✅ Created platform wallet: {wallet_id}")
        else:
            logger.info(f"✅ Platform wallet exists: {existing.wallet_id}")
    finally:
        db.close()

    # Seed time slots KG01–KG21
    _TIME_SLOTS = [
        ("KG01", dtime(6, 30),  dtime(7, 0)),
        ("KG02", dtime(7, 0),   dtime(7, 30)),
        ("KG03", dtime(7, 30),  dtime(8, 0)),
        ("KG04", dtime(8, 0),   dtime(8, 30)),
        ("KG05", dtime(8, 30),  dtime(9, 0)),
        ("KG06", dtime(9, 0),   dtime(9, 30)),
        ("KG07", dtime(9, 30),  dtime(10, 0)),
        ("KG08", dtime(10, 0),  dtime(10, 30)),
        ("KG09", dtime(10, 30), dtime(11, 0)),
        ("KG10", dtime(11, 0),  dtime(11, 30)),
        ("KG11", dtime(11, 30), dtime(12, 0)),
        ("KG12", dtime(12, 0),  dtime(12, 30)),
        ("KG13", dtime(14, 30), dtime(15, 0)),
        ("KG14", dtime(15, 0),  dtime(15, 30)),
        ("KG15", dtime(15, 30), dtime(16, 0)),
        ("KG16", dtime(16, 0),  dtime(16, 30)),
        ("KG17", dtime(16, 30), dtime(17, 0)),
        ("KG18", dtime(17, 0),  dtime(17, 30)),
        ("KG19", dtime(17, 30), dtime(18, 0)),
        ("KG20", dtime(18, 0),  dtime(18, 30)),
        ("KG21", dtime(18, 30), dtime(19, 0)),
    ]
    db = SessionLocal()
    try:
        existing_ids = {ts.time_slot_id for ts in db.query(TimeSlot.time_slot_id).all()}
        added = 0
        for slot_id, start, end in _TIME_SLOTS:
            if slot_id not in existing_ids:
                db.add(TimeSlot(time_slot_id=slot_id, start_time=start, end_time=end))
                added += 1
        if added:
            db.commit()
            logger.info(f"✅ Seeded {added} time slots")
        else:
            logger.info("✅ Time slots already seeded")
    except Exception as e:
        logger.warning(f"⚠️ Time slot seed failed: {e}")
    finally:
        db.close()

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
    return {
        "status": "ok",
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "version": "2.0.0"
    }

# Database ping
@app.get("/db/ping", tags=["Health"])
async def db_ping():
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

# Routers (GIỮ CẢ chat_ws)
from app.routers import auth, buyer, cart, order, review, search, seller, payment, shipper, upload, market_management, wallet, chat, chat_ws

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
app.include_router(wallet.router)
app.include_router(chat.router)
app.include_router(chat_ws.router)

# Static files
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