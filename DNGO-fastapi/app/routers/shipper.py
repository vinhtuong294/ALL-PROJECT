from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from datetime import date
from pydantic import BaseModel
from app.database import get_db
from app.middlewares.auth import allow, AuthUser
from app.repositories import shipper as shipper_repo
import logging as _log
_logger = _log.getLogger(__name__)


def _fill_missing_distances(db: Session, items: list) -> None:
    """Tính distance_km cho các đơn null ngay trong request, cập nhật DB và items[]."""
    from app.models.models import Order, OrderDetail, Stall, Market
    from app.utils.distance import calculate_distance

    null_items = [o for o in items if o.get("distance_km") is None]
    if not null_items:
        return

    null_ids = [o["ma_don_hang"] for o in null_items]

    # Batch-load market addresses keyed by order_id
    rows = (
        db.query(OrderDetail.order_id, Market.market_address)
        .join(Stall, Stall.stall_id == OrderDetail.stall_id)
        .join(Market, Market.market_id == Stall.market_id)
        .filter(OrderDetail.order_id.in_(null_ids))
        .distinct()
        .all()
    )
    market_addr_map = {r.order_id: r.market_address for r in rows}

    # Geocode with deduplication: (market_addr, delivery_addr) → distance
    distance_cache: dict = {}
    order_distance: dict = {}

    for item in null_items:
        oid = item["ma_don_hang"]
        market_addr = market_addr_map.get(oid)
        delivery_addr = item.get("dia_chi_giao_hang", "")
        if not market_addr or not delivery_addr:
            continue
        cache_key = (market_addr, delivery_addr)
        if cache_key not in distance_cache:
            try:
                distance_cache[cache_key] = calculate_distance(market_addr, delivery_addr)
            except Exception as e:
                _logger.warning(f"[fill_distances] {oid}: {e}")
                distance_cache[cache_key] = None
        dist = distance_cache[cache_key]
        if dist is not None:
            order_distance[oid] = dist

    if not order_distance:
        return

    # Update items in-place
    for item in items:
        if item["ma_don_hang"] in order_distance:
            item["distance_km"] = round(order_distance[item["ma_don_hang"]], 2)

    # Persist to DB
    db.query(Order).filter(Order.order_id.in_(list(order_distance.keys()))).all()
    for order in db.query(Order).filter(Order.order_id.in_(list(order_distance.keys()))).all():
        order.distance_km = order_distance[order.order_id]
    try:
        db.commit()
    except Exception as e:
        _logger.error(f"[fill_distances] commit error: {e}")
        db.rollback()

router = APIRouter(prefix="/api/shipper", tags=["shipper"])


# ==================== REQUEST BODIES ====================

class AcceptOrderBody(BaseModel):
    ma_don_hang: str


class UpdateDetailStatusBody(BaseModel):
    ma_don_hang: str
    ma_nguyen_lieu: str


class UpdateStatusBody(BaseModel):
    tinh_trang_don_hang: str


class UpdateProfileBody(BaseModel):
    vehicle_type: Optional[str] = None
    vehicle_plate: Optional[str] = None
    bank_account: Optional[str] = None
    bank_name: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None


class SubmitPodBody(BaseModel):
    image_url: str
    note: Optional[str] = None


class FailedDeliveryBody(BaseModel):
    reason: str
    note: Optional[str] = None
    evidence_image_url: Optional[str] = None


# ==================== HELPERS ====================

def get_shipper_or_404(db, user_id):
    shipper = shipper_repo.get_shipper_by_user_id(db, user_id)
    if not shipper:
        raise HTTPException(404, "Shipper profile not found")
    return shipper


# ==================== EXISTING ENDPOINTS ====================

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
    current_user: AuthUser = Depends(allow("shipper")),
):
    result = shipper_repo.list_available_orders(
        db=db, page=page, limit=limit, order_status=tinh_trang_don_hang
    )
    _fill_missing_distances(db, result["items"])
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
    # Hỗ trợ filter nhiều status: "cho_shipper,dang_giao,dang_lay_hang"
    statuses = [s.strip() for s in tinh_trang_don_hang.split(",")] if tinh_trang_don_hang and "," in tinh_trang_don_hang else None
    result = shipper_repo.list_my_orders(
        db=db, shipper_id=shipper.shipper_id,
        page=page, limit=limit,
        order_status=tinh_trang_don_hang if not statuses else None,
        order_statuses=statuses
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
    except Exception as e:
        import traceback
        raise HTTPException(500, f"Exception: {str(e)}\n{traceback.format_exc()}")


@router.patch("/orders/{ma_don_hang}/items/{ma_nguyen_lieu}/pickup")
def update_order_detail_status(
    ma_don_hang: str,
    ma_nguyen_lieu: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    """Cập nhật trạng thái lấy hàng cho từng nguyên liệu (chi tiết đơn hàng)"""
    shipper = get_shipper_or_404(db, current_user.user_id)
    try:
        result = shipper_repo.update_order_detail_status(
            db=db,
            shipper_id=shipper.shipper_id,
            order_id=ma_don_hang,
            ingredient_id=ma_nguyen_lieu
        )
        return {
            "success": True,
            **result
        }
    except LookupError as e:
        raise HTTPException(404, str(e))
    except PermissionError as e:
        raise HTTPException(409, str(e))
    except ValueError as e:
        raise HTTPException(400, str(e))
    except Exception as e:
        import traceback
        raise HTTPException(500, f"Exception: {str(e)}\n{traceback.format_exc()}")


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
    if not first_detail:
        raise HTTPException(400, "Đơn hàng không có chi tiết nguyên liệu")

    stall = db.query(Stall).filter(Stall.stall_id == first_detail.stall_id).first()
    if not stall:
        raise HTTPException(400, "Không tìm thấy gian hàng")

    market = db.query(Market).filter(Market.market_id == stall.market_id).first()
    if not market:
        raise HTTPException(400, "Không tìm thấy chợ")

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
# ==================== NEW: DASHBOARD ====================

@router.get("/dashboard")
def get_dashboard(
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    """Thống kê tổng quan cho Shipper: đơn hôm nay, thu nhập, tỷ lệ hoàn thành"""
    shipper = get_shipper_or_404(db, current_user.user_id)
    result = shipper_repo.get_dashboard_stats(db=db, shipper_id=shipper.shipper_id)
    return {"success": True, **result}


# ==================== NEW: EARNINGS ====================

@router.get("/earnings")
def get_earnings(
    filter_type: Optional[str] = Query(
        None, description="hom_nay | tuan_nay | thang_nay | khoang"
    ),
    from_date: Optional[date] = Query(None, description="YYYY-MM-DD"),
    to_date: Optional[date] = Query(None, description="YYYY-MM-DD"),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    """Lịch sử thu nhập (phí ship) theo khoảng thời gian"""
    shipper = get_shipper_or_404(db, current_user.user_id)
    result = shipper_repo.get_earnings(
        db=db, shipper_id=shipper.shipper_id,
        filter_type=filter_type, from_date=from_date, to_date=to_date
    )
    return {"success": True, **result}


# ==================== NEW: UPDATE PROFILE ====================

@router.put("/profile")
def update_profile(
    body: UpdateProfileBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    """Cập nhật thông tin phương tiện và ngân hàng"""
    try:
        result = shipper_repo.update_shipper_profile(
            db=db, user_id=current_user.user_id,
            **body.model_dump(exclude_unset=True)
        )
        return {"success": True, "data": result}
    except LookupError as e:
        raise HTTPException(404, str(e))


# ==================== NEW: POD ====================

@router.post("/orders/{ma_don_hang}/pod")
def submit_pod(
    ma_don_hang: str,
    body: SubmitPodBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    """Upload bằng chứng giao hàng (Proof of Delivery)"""
    shipper = get_shipper_or_404(db, current_user.user_id)
    try:
        result = shipper_repo.submit_pod(
            db=db, shipper_id=shipper.shipper_id,
            order_id=ma_don_hang,
            image_url=body.image_url, note=body.note
        )
        return {"success": True, "message": "Đã lưu bằng chứng giao hàng", "data": result}
    except LookupError as e:
        raise HTTPException(404, str(e))
    except PermissionError as e:
        raise HTTPException(403, str(e))


# ==================== NEW: FAILED DELIVERY ====================

@router.post("/orders/{ma_don_hang}/fail")
def report_failed(
    ma_don_hang: str,
    body: FailedDeliveryBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    """Báo cáo giao hàng thất bại"""
    shipper = get_shipper_or_404(db, current_user.user_id)
    try:
        result = shipper_repo.report_failed_delivery(
            db=db, shipper_id=shipper.shipper_id,
            order_id=ma_don_hang,
            reason=body.reason, note=body.note,
            evidence_image_url=body.evidence_image_url
        )
        return {"success": True, "message": "Đã báo cáo giao hàng thất bại", "data": result}
    except LookupError as e:
        raise HTTPException(404, str(e))
    except PermissionError as e:
        raise HTTPException(403, str(e))


# ==================== NEW: REVIEWS ====================

@router.get("/reviews")
def get_reviews(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    """Xem danh sách đánh giá từ khách hàng"""
    shipper = get_shipper_or_404(db, current_user.user_id)
    result = shipper_repo.get_shipper_reviews(
        db=db, shipper_id=shipper.shipper_id, page=page, limit=limit
    )
    return {"success": True, **result}


# ==================== NEW: NOTIFICATIONS ====================

@router.get("/notifications")
def get_notifications(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    """Lấy danh sách thông báo"""
    result = shipper_repo.get_shipper_notifications(
        db=db, user_id=current_user.user_id, page=page, limit=limit
    )
    return {"success": True, **result}


@router.patch("/notifications/{noti_id}/read")
def mark_read(
    noti_id: int,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    """Đánh dấu thông báo đã đọc"""
    success = shipper_repo.mark_notification_read(
        db=db, user_id=current_user.user_id, noti_id=noti_id
    )
    if not success:
        raise HTTPException(404, "Không tìm thấy thông báo")
    return {"success": True, "message": "Đã đánh dấu đã đọc"}


@router.patch("/notifications/read-all")
def mark_all_read(
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("shipper"))
):
    """Đánh dấu tất cả thông báo đã đọc"""
    count = shipper_repo.mark_all_notifications_read(
        db=db, user_id=current_user.user_id
    )
    return {"success": True, "message": f"Đã đánh dấu {count} thông báo đã đọc"}
