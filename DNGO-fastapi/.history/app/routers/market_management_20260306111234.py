from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from pydantic import BaseModel
from app.database import get_db
from app.middlewares.auth import allow, AuthUser
from app.repositories import market_management as mm_repo

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


@router.get("/tieu-thuong")
def list_tieu_thuong(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("quan_ly_cho"))
):
    manage_id = mm_repo.get_manage_id_by_user(db, current_user.user_id)
    if not manage_id:
        raise HTTPException(404, "Không tìm thấy thông tin quản lý chợ")

    return mm_repo.list_tieu_thuong(db, manage_id, page, limit)


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