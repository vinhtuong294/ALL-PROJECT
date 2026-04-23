from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from pydantic import BaseModel
from app.database import get_db
from app.middlewares.auth import allow, AuthUser
from app.repositories import market_management as mm_repo
from app.schemas.dashboard import DashboardStats, MarketDashboardV2, UpdateStallStatusRequest
from app.schemas.merchant import MerchantCreate
from app.schemas.stall_fee import StallFeeListResponse, StallFeeDetailResponse, StallFeeConfirmRequest

router = APIRouter(prefix="/api/quan-ly-cho", tags=["Market Management"])


class RegisterStallRequest(BaseModel):
    ma_nguoi_dung: str
    ten_gian_hang: str
    stall_location: str
    grid_col: int
    grid_row: int
    grid_floor: Optional[int] = None


@router.get("/loai-hang-hoa")
def get_stall_location_options(
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    return {
        "success": True,
        "data": [
            {"ma": k, "ten": v}
            for k, v in mm_repo.STALL_LOCATION_OPTIONS.items()
        ]
    }


@router.get("/thu-thue")
def list_stall_fees(
    month: str = Query(None, description="Format: YYYY-MM, default is current month"),
    status: Optional[str] = Query(None, description="da_nop / chua_nop / tat_ca"),
    search: Optional[str] = Query(None, description="Search by stall name or merchant name"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    from datetime import datetime
    from app.models.models import Stall, MarketManagement
    if not month:
        month = datetime.now().strftime("%Y-%m")

    manage_id = mm_repo.get_manage_id_by_user(db, current_user.user_id)
    if not manage_id:
        # Fallback: get manage_id from any stall managed by this user
        manage_id = mm_repo.get_manage_id_fallback(db, current_user.user_id)
        if not manage_id:
            return {
                "success": True,
                "data": [],
                "total_collected": 0.0,
                "meta": {
                    "page": page, "limit": limit, "total": 0,
                    "total_pages": 1, "month": month
                }
            }

    return mm_repo.list_stall_fees(db, manage_id, month, status, search, page, limit)


@router.get("/thu-thue/{fee_id}", response_model=StallFeeDetailResponse)
def get_stall_fee_detail(
    fee_id: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    result = mm_repo.get_stall_fee_detail(db, fee_id)
    if not result:
        raise HTTPException(404, "Không tìm thấy thông tin thu thuế")
    return result


@router.post("/thu-thue/{fee_id}/xac-nhan")
def confirm_stall_fee_payment(
    fee_id: str,
    req: StallFeeConfirmRequest,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    # Map friendly names to internal enum-like strings if necessary
    # UI: Tiền mặt -> tien_mat, Chuyển khoản -> chuyen_khoan
    pm = "tien_mat"
    if "chuyen" in req.payment_method.lower():
        pm = "chuyen_khoan"
        
    result = mm_repo.confirm_stall_fee_payment(db, fee_id, pm, req.note, req.amount)
    if not result:
        raise HTTPException(404, "Không tìm thấy thông tin thu thuế")
    return result


@router.get("/tieu-thuong")
def list_tieu_thuong(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    manage_id = mm_repo.get_manage_id_by_user(db, current_user.user_id)
    if not manage_id:
        raise HTTPException(404, "Không tìm thấy thông tin quản lý chợ")

    return mm_repo.list_tieu_thuong(db, manage_id, page, limit, search, status)



@router.get("/tieu-thuong/{user_id}")
def get_tieu_thuong_detail(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    manage_id = mm_repo.get_manage_id_by_user(db, current_user.user_id)
    if not manage_id:
        raise HTTPException(404, "Không tìm thấy thông tin quản lý chợ")

    result = mm_repo.get_tieu_thuong_detail(db, user_id, manage_id)
    if not result:
        raise HTTPException(404, "Không tìm thấy tiểu thương")

    return {"success": True, "data": result}


@router.post("/dang-ky-gian-hang")
def register_stall(
    body: RegisterStallRequest,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    manage_id = mm_repo.get_manage_id_by_user(db, current_user.user_id)
    if not manage_id:
        raise HTTPException(404, "Không tìm thấy thông tin quản lý chợ")

    try:
        result = mm_repo.register_stall(
            db=db,
            manage_id=manage_id,
            user_id=body.ma_nguoi_dung,
            stall_name=body.ten_gian_hang,
            stall_location=body.stall_location,
            grid_col=body.grid_col,
            grid_row=body.grid_row,
            grid_floor=body.grid_floor
        )
        return {"success": True, "data": result}
    except ValueError as e:
        raise HTTPException(400, str(e))


@router.get("/dashboard", response_model=DashboardStats)
def get_dashboard(
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    manage_id = mm_repo.get_manage_id_by_user(db, current_user.user_id)
    if not manage_id:
        raise HTTPException(404, "Không tìm thấy thông tin quản lý chợ")

    result = mm_repo.get_dashboard_stats(db, manage_id)
    if not result:
        raise HTTPException(404, "Không tìm thấy dữ liệu dashboard")

    return result


@router.post("/tieu-thuong")
def create_new_tieu_thuong(
    body: MerchantCreate,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    manage_id = mm_repo.get_manage_id_by_user(db, current_user.user_id)
    if not manage_id:
        raise HTTPException(404, "Không tìm thấy thông tin quản lý chợ")

    try:
        result = mm_repo.create_tieu_thuong(db, manage_id, body)
        return result
    except ValueError as e:
        raise HTTPException(400, str(e))


@router.get("/dashboard-v2", response_model=MarketDashboardV2)
def get_dashboard_v2(
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    manage_id = mm_repo.get_manage_id_by_user(db, current_user.user_id)
    if not manage_id:
        manage_id = mm_repo.get_manage_id_fallback(db, current_user.user_id)
        if not manage_id:
            raise HTTPException(404, "Không tìm thấy thông tin quản lý chợ")

    return mm_repo.get_dashboard_v2(db, manage_id)


@router.get("/stalls/map")
def get_map_stalls(
    db: Session = Depends(get_db),
):
    try:
        data = mm_repo.get_map_stalls(db, manage_id=None)
        return {"success": True, "data": data}
    except Exception as e:
        raise HTTPException(500, str(e))


@router.post("/stalls/{stall_id}/status")
def update_stall_status(
    stall_id: str,
    body: UpdateStallStatusRequest,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    result = mm_repo.update_stall_status(db, stall_id, body.status, body.note)
    if not result:
        raise HTTPException(404, "Không tìm thấy gian hàng")
    return result

@router.get("/pending-sellers")
def list_pending_sellers(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    return mm_repo.list_pending_sellers(db, page, limit, search)


@router.patch("/approve-seller/{user_id}")
def approve_seller(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    """Duyệt tiểu thương (approval_status=1)"""
    result = mm_repo.approve_seller(db, user_id)
    if not result:
        raise HTTPException(404, "Không tìm thấy tiểu thương")
    return {"success": True, "message": "Duyệt người bán thành công"}
