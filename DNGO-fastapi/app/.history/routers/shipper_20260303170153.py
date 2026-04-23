from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from pydantic import BaseModel
from app.database import get_db
from app.middlewares.auth import allow, AuthUser
from app.repositories import shipper as shipper_repo

router = APIRouter(prefix="/api/shipper", tags=["shipper"])


class AcceptOrderBody(BaseModel):
    ma_don_hang: str


class UpdateStatusBody(BaseModel):
    tinh_trang_don_hang: str


def get_shipper_or_404(db, user_id):
    shipper = shipper_repo.get_shipper_by_user_id(db, user_id)
    if not shipper:
        raise HTTPException(404, "Shipper profile not found")
    return shipper


@router.get("/me")
def get_my_info(
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    shipper = get_shipper_or_404(db, current_user.user_id)
    return {
        "success": True,
        "shipper": {
            "ma_shipper": shipper.shipper_id,
            "phuong_tien": shipper.vehicle_type,
            "bien_so_xe": shipper.vehicle_plate,
            "nguoi_dung": {
                "ten_nguoi_dung": shipper.user.user_name if shipper.user else None,
                "sdt": shipper.user.phone if shipper.user else None,
            }
        }
    }


@router.get("/orders/available")
def list_available_orders(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    tinh_trang_don_hang: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    result = shipper_repo.list_available_orders(
        db=db, page=page, limit=limit, order_status=tinh_trang_don_hang
    )
    return {"success": True, **result}


@router.get("/orders/my")
def list_my_orders(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    tinh_trang_don_hang: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    shipper = get_shipper_or_404(db, current_user.user_id)
    result = shipper_repo.list_my_orders(
        db=db, shipper_id=shipper.shipper_id,
        page=page, limit=limit, order_status=tinh_trang_don_hang
    )
    return {"success": True, **result}


@router.post("/orders/accept")
def accept_order(
    body: AcceptOrderBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    shipper = get_shipper_or_404(db, current_user.user_id)
    try:
        result = shipper_repo.accept_order(
            db=db,
            shipper_id=shipper.shipper_id,
            order_id=body.ma_don_hang
        )
        return {
            "success": True,
            **result,
            "message": "Đã nhận đơn hàng thành công" if result["is_new"] else "Đơn hàng đã được bạn nhận trước đó"
        }
    except LookupError as e:
        raise HTTPException(404, str(e))
    except PermissionError as e:
        raise HTTPException(409, str(e))
    except ValueError as e:
        raise HTTPException(400, str(e))


@router.patch("/orders/{ma_don_hang}/status")
def update_order_status(
    ma_don_hang: str,
    body: UpdateStatusBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    shipper = get_shipper_or_404(db, current_user.user_id)
    try:
        result = shipper_repo.update_order_status(
            db=db,
            shipper_id=shipper.shipper_id,
            order_id=ma_don_hang,
            new_status=body.tinh_trang_don_hang
        )
        return {"success": True, "order": result}
    except LookupError as e:
        raise HTTPException(404, str(e))
    except PermissionError as e:
        raise HTTPException(403, str(e))
    except ValueError as e:
        raise HTTPException(400, str(e))

