from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from app.database import get_db
from app.middlewares.auth import allow, AuthUser
from app.repositories import order as order_repo

router = APIRouter(prefix="/api/orders", tags=["orders"])


@router.get("/{ma_don_hang}/shipper-status")
def check_shipper_status(
    ma_don_hang: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua", "nguoi_ban"))
):
    result = order_repo.check_shipper_status(db=db, order_id=ma_don_hang)
    return {
        "success": True,
        "has_shipper": result is not None,
        "shipper_info": result,
    }


@router.get("/")
def list_orders(
    page: int = Query(1, ge=1),
    limit: int = Query(12, ge=1, le=100),
    tinh_trang_don_hang: Optional[str] = None,
    sort: str = "delivery_time",
    order: str = "desc",
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua"))
):
    try:
        result = order_repo.list_orders(
            db=db,
            user_id=current_user.user_id,
            page=page, limit=limit,
            order_status=tinh_trang_don_hang,
            sort=sort, order=order
        )
        return {"success": True, **result}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/{ma_don_hang}")
def get_order_detail(
    ma_don_hang: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua"))
):
    result = order_repo.get_order_detail(
        db=db,
        order_id=ma_don_hang,
        user_id=current_user.user_id
    )
    if not result:
        raise HTTPException(status_code=404, detail="Đơn hàng không tồn tại hoặc bạn không có quyền truy cập")
    return {"success": True, "data": result}


@router.delete("/{ma_don_hang}")
def cancel_order(
    ma_don_hang: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua"))
):
    try:
        result = order_repo.cancel_order(
            db=db,
            order_id=ma_don_hang,
            user_id=current_user.user_id
        )
        return {"success": True, **result}
    except Exception as e:
        msg = str(e)
        if "không tồn tại" in msg:
            raise HTTPException(status_code=404, detail=msg)
        if "Không thể hủy" in msg:
            raise HTTPException(status_code=400, detail=msg)
        raise HTTPException(status_code=500, detail=msg)