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


@router.get("/orders/{ma_don_hang}/details")
def get_order_details(
    ma_don_hang: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    result = shipper_repo.get_order_details(db=db, order_id=ma_don_hang)
    if not result:
        raise HTTPException(404, "Không tìm thấy đơn hàng")
    return {"success": True, "data": result}


class OptimizeRouteBody(BaseModel):
    order_ids: list[str]

class OptimizeRouteBody(BaseModel):
    consolidation_id: str

@router.post("/orders/optimize-route")
def optimize_route(
    body: OptimizeRouteBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    from app.models.models import Order, Stall, Market, OrderDetail, Consolidation
    from app.utils.distance import optimize_delivery_route

    # Kiểm tra mã gom đơn
    consolidation = db.query(Consolidation).filter(
        Consolidation.consolidation_id == body.consolidation_id
    ).first()
    if not consolidation:
        raise HTTPException(404, "Không tìm thấy mã gom đơn")

    # Lấy tất cả đơn hàng trong gom đơn
    orders = db.query(Order).filter(
        Order.consolidation_id == body.consolidation_id
    ).all()

    if not orders:
        raise HTTPException(404, "Không có đơn hàng nào trong gom đơn này")

    # Lấy địa chỉ chợ từ đơn đầu tiên
    first_detail = db.query(OrderDetail).filter(
        OrderDetail.order_id == orders[0].order_id
    ).first()

    stall = db.query(Stall).filter(Stall.stall_id == first_detail.stall_id).first()
    market = db.query(Market).filter(Market.market_id == stall.market_id).first()
    market_address = market.market_address

    # Lấy địa chỉ giao hàng của từng đơn
    delivery_addresses = [
        {
            "order_id": order.order_id,
            "address": order.delivery_address
        }
        for order in orders
    ]

    try:
        result = optimize_delivery_route(market_address, delivery_addresses)
        return {
            "success": True,
            "consolidation_id": body.consolidation_id,
            "ten_cho": market.market_name,
            "so_don": len(orders),
            "data": result
        }
    except ValueError as e:
        raise HTTPException(400, str(e))