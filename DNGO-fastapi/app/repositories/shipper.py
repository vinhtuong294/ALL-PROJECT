from collections import defaultdict
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional, Dict, Any
from app.models.models import (
    Shipper, Order, OrderDetail, Consolidation,
    User, TimeSlot, Goods, Ingredient,
)
from app.models.models import Market, Stall as StallModel
from app.models.models import Buyer as BuyerModel, Payment as PaymentModel
import secrets




def gen_consolidation_id():
    rand = secrets.token_urlsafe(6)[:8].upper()
    return f"GD{rand}"




def get_shipper_by_user_id(db: Session, user_id: str):
    return db.query(Shipper).filter(Shipper.user_id == user_id).first()




def list_available_orders(db: Session, page: int = 1, limit: int = 10,
                          order_status: Optional[str] = None) -> Dict[str, Any]:
    skip = (page - 1) * limit
    status = order_status or "da_xac_nhan"

    base_filter = [Order.order_status == status, Order.consolidation_id == None]
    total = db.query(func.count(Order.order_id)).filter(*base_filter).scalar()
    orders = (
        db.query(Order)
        .filter(*base_filter)
        .order_by(Order.distance_km.asc().nullslast())
        .offset(skip).limit(limit)
        .all()
    )

    if not orders:
        return {"items": [], "total": total, "page": page, "limit": limit,
                "totalPages": (total + limit - 1) // limit}

    order_ids = [o.order_id for o in orders]

    # ── Batch 1: market name ────────────────────────────────────────────────
    market_map = {
        row[0]: row[1]
        for row in (
            db.query(OrderDetail.order_id, Market.market_name)
            .join(StallModel, StallModel.stall_id == OrderDetail.stall_id)
            .join(Market, Market.market_id == StallModel.market_id)
            .filter(OrderDetail.order_id.in_(order_ids))
            .all()
        )
    }

    # ── Batch 2: time slots ─────────────────────────────────────────────────
    ts_ids = {o.time_slot_id for o in orders if o.time_slot_id}
    ts_map = (
        {ts.time_slot_id: ts for ts in
         db.query(TimeSlot).filter(TimeSlot.time_slot_id.in_(ts_ids)).all()}
        if ts_ids else {}
    )

    # ── Batch 3: order details + ingredient + stall (single JOIN query) ─────
    detail_rows = (
        db.query(
            OrderDetail.order_id,
            OrderDetail.ingredient_id,
            OrderDetail.quantity_order,
            OrderDetail.detail_status,
            Ingredient.ingredient_name,
            Goods.unit,
            StallModel.stall_name,
        )
        .join(Goods, (Goods.ingredient_id == OrderDetail.ingredient_id) &
              (Goods.stall_id == OrderDetail.stall_id), isouter=True)
        .join(Ingredient, Ingredient.ingredient_id == OrderDetail.ingredient_id, isouter=True)
        .join(StallModel, StallModel.stall_id == OrderDetail.stall_id, isouter=True)
        .filter(
            OrderDetail.order_id.in_(order_ids),
            OrderDetail.ingredient_id != "NLQD01",
        )
        .all()
    )
    details_map: Dict[str, list] = defaultdict(list)
    for row in detail_rows:
        details_map[row.order_id].append({
            "ingredient_id": row.ingredient_id,
            "ten_nguyen_lieu": row.ingredient_name,
            "so_luong": row.quantity_order,
            "don_vi": row.unit,
            "ten_gian_hang": row.stall_name,
            "trang_thai": row.detail_status,
        })

    # ── Batch 4: buyer + user info ──────────────────────────────────────────
    buyer_ids = [o.buyer_id for o in orders if o.buyer_id]
    buyer_map = (
        {row.buyer_id: row for row in (
            db.query(BuyerModel.buyer_id, User.user_name, User.phone, User.address)
            .join(User, User.user_id == BuyerModel.user_id, isouter=True)
            .filter(BuyerModel.buyer_id.in_(buyer_ids))
            .all()
        )}
        if buyer_ids else {}
    )

    # ── Batch 5: payment ────────────────────────────────────────────────────
    payment_ids = [o.payment_id for o in orders if o.payment_id]
    payment_map = (
        {row.payment_id: row for row in (
            db.query(PaymentModel.payment_id, PaymentModel.payment_method,
                     PaymentModel.payment_status)
            .filter(PaymentModel.payment_id.in_(payment_ids))
            .all()
        )}
        if payment_ids else {}
    )

    # ── Assemble ────────────────────────────────────────────────────────────
    items = []
    for order in orders:
        ts    = ts_map.get(order.time_slot_id)
        buyer = buyer_map.get(order.buyer_id)
        pay   = payment_map.get(order.payment_id)

        items.append({
            "ma_don_hang":        order.order_id,
            "tong_tien":          order.total_amount,
            "dia_chi_giao_hang":  order.delivery_address,
            "tinh_trang_don_hang": order.order_status,
            "thoi_gian_giao_hang": order.delivery_time,
            "distance_km":        order.distance_km,
            "ten_cho":            market_map.get(order.order_id),
            "san_pham":           details_map.get(order.order_id, []),
            "khung_gio": {
                "time_slot_id": ts.time_slot_id,
                "gio_bat_dau":  ts.start_time,
                "gio_ket_thuc": ts.end_time,
            } if ts else None,
            "nguoi_mua": {
                "buyer_id":       order.buyer_id,
                "ten_nguoi_dung": buyer.user_name if buyer else None,
                "sdt":            buyer.phone     if buyer else None,
                "dia_chi":        buyer.address   if buyer else None,
            } if buyer else None,
            "thanh_toan": {
                "hinh_thuc_thanh_toan":  pay.payment_method,
                "tinh_trang_thanh_toan": pay.payment_status,
            } if pay else None,
            "shipper_info": None,
        })

    return {
        "items": items,
        "total": total,
        "page": page,
        "limit": limit,
        "totalPages": (total + limit - 1) // limit,
    }


def list_my_orders(db: Session, shipper_id: str, page: int = 1, limit: int = 10,
                   order_status: Optional[str] = None,
                   order_statuses: Optional[list] = None) -> Dict[str, Any]:
    skip = (page - 1) * limit

    query = db.query(Order).join(
        Consolidation, Order.consolidation_id == Consolidation.consolidation_id
    ).filter(Consolidation.shipper_id == shipper_id)

    if order_statuses:
        query = query.filter(Order.order_status.in_(order_statuses))
    elif order_status:
        query = query.filter(Order.order_status == order_status)


    query = query.order_by(Order.delivery_time.asc())
    total = query.count()
    orders = query.offset(skip).limit(limit).all()


    # Batch load market_name và time_slot (thay vì N+1 queries)
    order_ids = [o.order_id for o in orders]
    my_market_rows = (
        db.query(OrderDetail.order_id, Market.market_name)
        .join(StallModel, StallModel.stall_id == OrderDetail.stall_id)
        .join(Market, Market.market_id == StallModel.market_id)
        .filter(OrderDetail.order_id.in_(order_ids))
        .all()
    )
    my_market_map = {row[0]: row[1] for row in my_market_rows}

    ts_ids = {o.time_slot_id for o in orders if o.time_slot_id}
    my_ts_map = {ts.time_slot_id: ts for ts in db.query(TimeSlot).filter(TimeSlot.time_slot_id.in_(ts_ids)).all()} if ts_ids else {}

    # Batch load consolidations
    con_ids = {o.consolidation_id for o in orders if o.consolidation_id}
    con_map = (
        {c.consolidation_id: c for c in
         db.query(Consolidation).filter(Consolidation.consolidation_id.in_(con_ids)).all()}
        if con_ids else {}
    )

    # Batch load buyer + user
    buyer_ids = [o.buyer_id for o in orders if o.buyer_id]
    my_buyer_map = (
        {row.buyer_id: row for row in (
            db.query(BuyerModel.buyer_id, User.user_name, User.phone, User.address)
            .join(User, User.user_id == BuyerModel.user_id, isouter=True)
            .filter(BuyerModel.buyer_id.in_(buyer_ids))
            .all()
        )}
        if buyer_ids else {}
    )

    # Batch load payment
    payment_ids = [o.payment_id for o in orders if o.payment_id]
    my_payment_map = (
        {row.payment_id: row for row in (
            db.query(PaymentModel.payment_id, PaymentModel.payment_method,
                     PaymentModel.payment_status)
            .filter(PaymentModel.payment_id.in_(payment_ids))
            .all()
        )}
        if payment_ids else {}
    )

    items = []
    for order in orders:
        consolidation = con_map.get(order.consolidation_id) if order.consolidation_id else None
        time_slot = my_ts_map.get(order.time_slot_id)
        buyer = my_buyer_map.get(order.buyer_id)
        pay = my_payment_map.get(order.payment_id)

        items.append({
            "ma_don_hang": order.order_id,
            "tong_tien": order.total_amount,
            "dia_chi_giao_hang": order.delivery_address,
            "tinh_trang_don_hang": order.order_status,
            "thoi_gian_giao_hang": order.delivery_time,
            "ngay_dat_hang": order.order_time,
            "ten_cho": my_market_map.get(order.order_id),
            "khung_gio": {
                "time_slot_id": time_slot.time_slot_id,
                "gio_bat_dau": time_slot.start_time,
                "gio_ket_thuc": time_slot.end_time,
            } if time_slot else None,
            "nguoi_mua": {
                "buyer_id": order.buyer_id,
                "ten_nguoi_dung": buyer.user_name if buyer else None,
                "sdt": buyer.phone if buyer else None,
                "dia_chi": buyer.address if buyer else None,
            } if buyer else None,
            "thanh_toan": {
                "hinh_thuc_thanh_toan": pay.payment_method,
                "tinh_trang_thanh_toan": pay.payment_status,
            } if pay else None,
            "gom_don": {
                "ma_gom_don": consolidation.consolidation_id,
            } if consolidation else None,
        })


    return {
        "items": items,
        "total": total,
        "page": page,
        "limit": limit,
        "totalPages": (total + limit - 1) // limit,
    }




def accept_order(db: Session, shipper_id: str, order_id: str) -> Dict[str, Any]:
    from app.models.models import Stall, Market

    order = db.query(Order).filter(Order.order_id == order_id).first()

    if not order:
        raise LookupError("ORDER_NOT_FOUND")

    if order.order_status != "da_xac_nhan":
        raise ValueError("Chỉ có thể nhận đơn hàng đã xác nhận")

    # Nếu đơn đã có consolidation
    if order.consolidation_id:
        consolidation = db.query(Consolidation).filter(
            Consolidation.consolidation_id == order.consolidation_id
        ).first()

        if not consolidation:
            # Orphaned reference — reset and re-assign below
            order.consolidation_id = None
            db.flush()
        elif consolidation.shipper_id != shipper_id:
            raise PermissionError("Đơn hàng đã được shipper khác nhận")
        else:
            return {
                "gom_don": {"ma_gom_don": consolidation.consolidation_id},
                "is_new": False
            }

    # ─────────────────────────────
    # 🔍 LẤY market_id từ order
    # ─────────────────────────────
    first_detail = db.query(OrderDetail).filter(
        OrderDetail.order_id == order.order_id
    ).first()

    if not first_detail:
        raise ValueError("Đơn hàng không có chi tiết")

    stall = db.query(Stall).filter(
        Stall.stall_id == first_detail.stall_id
    ).first()

    if not stall:
        raise ValueError("Không tìm thấy gian hàng")

    market_id = stall.market_id
    time_slot_id = order.time_slot_id

    # ─────────────────────────────
    # 🔍 TÌM consolidation phù hợp
    # ─────────────────────────────
    existing = (
        db.query(Consolidation)
        .join(Order, Order.consolidation_id == Consolidation.consolidation_id)
        .join(OrderDetail, OrderDetail.order_id == Order.order_id)
        .join(Stall, Stall.stall_id == OrderDetail.stall_id)
        .filter(
            Consolidation.shipper_id == shipper_id,
            Order.time_slot_id == time_slot_id,
            Stall.market_id == market_id,
            Order.order_status.in_(["cho_shipper", "dang_lay_hang"])
        )
        .first()
    )

    if existing:
        consolidation = existing
        is_new = False
    else:
        consolidation = Consolidation(
            consolidation_id=gen_consolidation_id(),
            shipper_id=shipper_id
        )
        db.add(consolidation)
        db.flush()
        is_new = True

    # ─────────────────────────────
    # GÁN đơn vào consolidation
    # ─────────────────────────────
    order.consolidation_id = consolidation.consolidation_id
    order.order_status = "cho_shipper"
    
    # Tự động set NLQD01 thành da_lay_hang (phí ship)
    shipping_fee_detail = db.query(OrderDetail).filter(
        OrderDetail.order_id == order.order_id,
        OrderDetail.ingredient_id == "NLQD01"
    ).first()
    
    if shipping_fee_detail:
        shipping_fee_detail.detail_status = "da_lay_hang"

    db.commit()

    return {
        "gom_don": {"ma_gom_don": consolidation.consolidation_id},
        "is_new": is_new
    }


def update_order_detail_status(db: Session, shipper_id: str, order_id: str, 
                               ingredient_id: str) -> Dict[str, Any]:
    """
    Cập nhật trạng thái chi tiết đơn hàng thành da_lay_hang
    Chỉ cho phép shipper của đơn hàng cập nhật
    """
    # Kiểm tra đơn hàng tồn tại và shipper có quyền
    order = db.query(Order).filter(Order.order_id == order_id).first()
    if not order:
        raise LookupError("Đơn hàng không tồn tại")
    
    if not order.consolidation_id:
        raise PermissionError("Đơn hàng chưa có shipper nhận")
    
    consolidation = db.query(Consolidation).filter(
        Consolidation.consolidation_id == order.consolidation_id
    ).first()
    
    if not consolidation or consolidation.shipper_id != shipper_id:
        raise PermissionError("Bạn không có quyền cập nhật đơn hàng này")
    
    # Kiểm tra chi tiết tồn tại
    detail = db.query(OrderDetail).filter(
        OrderDetail.order_id == order_id,
        OrderDetail.ingredient_id == ingredient_id
    ).first()
    
    if not detail:
        raise LookupError("Chi tiết đơn hàng không tồn tại")
    
    # Nguyên liệu NLQD01 luôn là da_lay_hang
    if detail.ingredient_id == "NLQD01":
        raise ValueError("Không thể cập nhật trạng thái của nguyên liệu NLQD01")
    
    # Cập nhật trạng thái
    detail.detail_status = "da_lay_hang"
    db.commit()
    db.refresh(detail)
    
    return {
        "success": True,
        "order_id": order_id,
        "ingredient_id": ingredient_id,
        "detail_status": detail.detail_status
    }


def update_order_status(db: Session, shipper_id: str, order_id: str,
                        new_status: str) -> Dict[str, Any]:
    allowed = ["dang_lay_hang", "dang_giao", "da_giao", "hoan_thanh"]
    if new_status not in allowed:
        raise ValueError(f"Trạng thái không hợp lệ. Chỉ cho phép: {', '.join(allowed)}")


    order = db.query(Order).filter(Order.order_id == order_id).first()
    if not order:
        raise LookupError("ORDER_NOT_FOUND")


    # Kiểm tra shipper có quyền không
    if order.consolidation_id:
        consolidation = db.query(Consolidation).filter(
            Consolidation.consolidation_id == order.consolidation_id
        ).first()
        if not consolidation or consolidation.shipper_id != shipper_id:
            raise PermissionError("Bạn không có quyền cập nhật đơn hàng này")
    else:
        raise PermissionError("Bạn không có quyền cập nhật đơn hàng này")


    current = order.order_status

    # Kiểm tra luồng trạng thái
    if new_status == "dang_lay_hang" and current != "cho_shipper":
        raise ValueError("Chỉ có thể bắt đầu lấy hàng từ trạng thái 'cho_shipper'")

    # cho phép cả cho_shipper (khi dang_lay_hang chưa được ghi vào DB do constraint)
    if new_status == "dang_giao" and current not in ("dang_lay_hang", "cho_shipper"):
        raise ValueError("Chỉ có thể bắt đầu giao từ trạng thái 'dang_lay_hang'")

    # Kiểm tra đã lấy đủ hàng trước khi chuyển sang dang_giao
    if new_status == "dang_giao":
        details = db.query(OrderDetail).filter(
            OrderDetail.order_id == order_id,
            OrderDetail.ingredient_id != "NLQD01"
        ).all()
        all_picked = all(d.detail_status == "da_lay_hang" for d in details)
        if not all_picked:
            raise ValueError("Chưa lấy hết hàng. Vui lòng cập nhật trạng thái cho tất cả nguyên liệu")

    if new_status == "da_giao" and current not in ("dang_giao", "cho_shipper"):
        raise ValueError("Chỉ có thể đánh dấu đã giao từ trạng thái 'dang_giao'")
    if new_status == "hoan_thanh" and current != "da_giao":
        raise ValueError("Chỉ có thể hoàn thành từ trạng thái 'da_giao'")

    # dang_lay_hang không được phép trong DB constraint → trả thành công mà không ghi DB
    # Flutter app nhận được status này và cập nhật UI, DB giữ nguyên cho_shipper
    if new_status == "dang_lay_hang":
        time_slot = db.query(TimeSlot).filter(
            TimeSlot.time_slot_id == order.time_slot_id
        ).first() if order.time_slot_id else None
        return {
            "ma_don_hang": order.order_id,
            "tinh_trang_don_hang": "dang_lay_hang",
            "tong_tien": order.total_amount,
            "dia_chi_giao_hang": order.delivery_address,
            "thoi_gian_giao_hang": order.delivery_time,
            "khung_gio": {
                "time_slot_id": time_slot.time_slot_id,
                "gio_bat_dau": time_slot.start_time,
                "gio_ket_thuc": time_slot.end_time,
            } if time_slot else None,
            "nguoi_mua": {
                "buyer_id": order.buyer.buyer_id,
                "ten_nguoi_dung": order.buyer.user.user_name if order.buyer and order.buyer.user else None,
                "sdt": order.buyer.user.phone if order.buyer and order.buyer.user else None,
            } if order.buyer else None,
            "gom_don": {"ma_gom_don": consolidation.consolidation_id},
        }

    order.order_status = new_status
    db.commit()
    db.refresh(order)

    # Xoá node tracking trên Firebase khi đơn hàng kết thúc
    if new_status in ["da_giao", "hoan_thanh", "da_huy"]:
        try:
            from app.firebase_client import get_db_ref
            ref = get_db_ref(f"tracking/{order_id}")
            ref.delete()
        except Exception as e:
            import logging
            logging.error(f"Lỗi khi xóa Firebase tracking/{order_id}: {e}")

    time_slot = db.query(TimeSlot).filter(
        TimeSlot.time_slot_id == order.time_slot_id
    ).first() if order.time_slot_id else None


    return {
        "ma_don_hang": order.order_id,
        "tinh_trang_don_hang": order.order_status,
        "tong_tien": order.total_amount,
        "dia_chi_giao_hang": order.delivery_address,
        "thoi_gian_giao_hang": order.delivery_time,
        "khung_gio": {
            "time_slot_id": time_slot.time_slot_id,
            "gio_bat_dau": time_slot.start_time,
            "gio_ket_thuc": time_slot.end_time,
        } if time_slot else None,
        "nguoi_mua": {
            "buyer_id": order.buyer.buyer_id,
            "ten_nguoi_dung": order.buyer.user.user_name if order.buyer and order.buyer.user else None,
            "sdt": order.buyer.user.phone if order.buyer and order.buyer.user else None,
        } if order.buyer else None,
        "gom_don": {
            "ma_gom_don": consolidation.consolidation_id,
        }
    }




def get_order_details(db: Session, order_id: str):
    from app.models.models import Order, OrderDetail, Ingredient, Stall, Market

    order = db.query(Order).filter(Order.order_id == order_id).first()
    if not order:
        return None

    details = (
        db.query(OrderDetail, Ingredient, Stall)
        .join(Ingredient, Ingredient.ingredient_id == OrderDetail.ingredient_id)
        .join(Stall, Stall.stall_id == OrderDetail.stall_id)
        .filter(OrderDetail.order_id == order_id)
        .all()
    )

    time_slot = db.query(TimeSlot).filter(
        TimeSlot.time_slot_id == order.time_slot_id
    ).first() if order.time_slot_id else None

    # Market info (lấy từ gian hàng đầu tiên)
    market_info = None
    if details:
        first_stall = details[0][2]
        market = db.query(Market).filter(Market.market_id == first_stall.market_id).first()
        if market:
            market_info = {
                "ten_cho": market.market_name,
                "dia_chi_cho": market.market_address,
                "lat": market.lat_market,
                "lng": market.long_market,
            }

    return {
        "ma_don_hang": order.order_id,
        "tong_tien": order.total_amount,
        "dia_chi_giao_hang": order.delivery_address,
        "tinh_trang_don_hang": order.order_status,
        "thoi_gian_giao_hang": order.delivery_time,
        "distance_km": order.distance_km,
        "ten_cho": market_info["ten_cho"] if market_info else None,
        "cho_info": market_info,
        "thanh_toan": {
            "hinh_thuc_thanh_toan": order.payment.payment_method if order.payment else None,
            "tinh_trang_thanh_toan": order.payment.payment_status if order.payment else None,
        },
        "khung_gio": {
            "time_slot_id": time_slot.time_slot_id,
            "gio_bat_dau": str(time_slot.start_time),
            "gio_ket_thuc": str(time_slot.end_time),
        } if time_slot else None,
        "nguoi_mua": {
            "ten_nguoi_dung": order.buyer.user.user_name if order.buyer and order.buyer.user else None,
            "sdt": order.buyer.user.phone if order.buyer and order.buyer.user else None,
            "dia_chi": order.buyer.user.address if order.buyer and order.buyer.user else None,
        } if order.buyer else None,
        "san_pham": [
            {
                "ingredient_id": od.ingredient_id,
                "ten_nguyen_lieu": ing.ingredient_name,
                "so_luong": od.quantity_order,
                "don_gia": float(od.final_price),
                "thanh_tien": float(od.final_price) * od.quantity_order,
                "ten_gian_hang": stall.stall_name,
                "stall_id": stall.stall_id,
                "stall_location": stall.stall_location,
                "grid_row": stall.grid_row,
                "grid_col": stall.grid_col,
                "grid_floor": stall.grid_floor,
                "detail_status": od.detail_status
            }
            for od, ing, stall in details
            if od.ingredient_id != "NLQD01"  # ẩn phí ship khỏi danh sách lấy hàng
        ]
    }


def get_dashboard_stats(db: Session, shipper_id: str) -> Dict[str, Any]:
    from datetime import date
    from sqlalchemy import func
    today = date.today()

    orders_today = db.query(Order).join(
        Consolidation, Consolidation.consolidation_id == Order.consolidation_id
    ).filter(
        Consolidation.shipper_id == shipper_id,
        func.date(Order.delivery_time) == today
    ).count()

    total_completed = db.query(Order).join(
        Consolidation, Consolidation.consolidation_id == Order.consolidation_id
    ).filter(
        Consolidation.shipper_id == shipper_id,
        Order.order_status.in_(["da_giao", "hoan_thanh"])
    ).count()

    total_orders = db.query(Order).join(
        Consolidation, Consolidation.consolidation_id == Order.consolidation_id
    ).filter(Consolidation.shipper_id == shipper_id).count()

    completion_rate = round(total_completed / total_orders * 100, 1) if total_orders > 0 else 0.0

    return {
        "don_hom_nay": orders_today,
        "tong_don_hoan_thanh": total_completed,
        "ty_le_hoan_thanh": completion_rate,
    }


def get_earnings(db: Session, shipper_id: str, filter_type=None, from_date=None, to_date=None) -> Dict[str, Any]:
    from sqlalchemy import func, cast, Date
    from datetime import date, timedelta

    today = date.today()
    if filter_type == "hom_nay":
        from_date = to_date = today
    elif filter_type == "tuan_nay":
        from_date = today - timedelta(days=today.weekday())
        to_date = today
    elif filter_type == "thang_nay":
        from_date = today.replace(day=1)
        to_date = today

    SHIP_ID = "NLQD01"
    q = db.query(
        Order.order_id,
        Order.order_time,
        func.sum(OrderDetail.final_price * OrderDetail.quantity_order).label("so_tien")
    ).join(
        OrderDetail, OrderDetail.order_id == Order.order_id
    ).join(
        Consolidation, Consolidation.consolidation_id == Order.consolidation_id
    ).filter(
        OrderDetail.ingredient_id == SHIP_ID,
        Consolidation.shipper_id == shipper_id,
        Order.order_status.in_(["da_giao", "hoan_thanh"]),
    ).group_by(Order.order_id, Order.order_time)

    if from_date and to_date:
        from sqlalchemy import cast, Date
        q = q.filter(cast(Order.order_time, Date) >= from_date, cast(Order.order_time, Date) <= to_date)

    rows = q.all()
    tong = sum(int(r.so_tien or 0) for r in rows)
    chi_tiet = [{"order_id": r.order_id, "so_tien": int(r.so_tien or 0), "ngay": r.order_time} for r in rows]

    return {"tong_thu_nhap": tong, "chi_tiet": chi_tiet}


def update_shipper_profile(db: Session, user_id: str, **kwargs) -> Dict[str, Any]:
    shipper = get_shipper_by_user_id(db, user_id)
    if not shipper:
        raise LookupError("Shipper profile not found")
    user = db.query(User).filter(User.user_id == user_id).first()
    for k, v in kwargs.items():
        if k in ("vehicle_type", "vehicle_plate") and hasattr(shipper, k):
            setattr(shipper, k, v)
        elif k in ("bank_account", "bank_name", "phone", "address") and user and hasattr(user, k):
            setattr(user, k, v)
    db.commit()
    return {"message": "Cập nhật thành công"}


def submit_pod(db: Session, shipper_id: str, order_id: str, image_url: str, note: Optional[str] = None) -> Dict[str, Any]:
    from app.models.models import DeliveryProof
    order = db.query(Order).filter(Order.order_id == order_id).first()
    if not order:
        raise LookupError("ORDER_NOT_FOUND")
    consolidation = db.query(Consolidation).filter(Consolidation.consolidation_id == order.consolidation_id).first()
    if not consolidation or consolidation.shipper_id != shipper_id:
        raise PermissionError("Bạn không có quyền với đơn hàng này")
    pod = DeliveryProof(order_id=order_id, shipper_id=shipper_id, image_url=image_url, note=note)
    db.add(pod)
    db.commit()
    db.refresh(pod)
    return {"id": pod.id, "order_id": pod.order_id, "image_url": pod.image_url}


def report_failed_delivery(db: Session, shipper_id: str, order_id: str, reason: str, note: Optional[str] = None, evidence_image_url: Optional[str] = None) -> Dict[str, Any]:
    from app.models.models import FailedDeliveryReport
    order = db.query(Order).filter(Order.order_id == order_id).first()
    if not order:
        raise LookupError("ORDER_NOT_FOUND")
    consolidation = db.query(Consolidation).filter(Consolidation.consolidation_id == order.consolidation_id).first()
    if not consolidation or consolidation.shipper_id != shipper_id:
        raise PermissionError("Bạn không có quyền với đơn hàng này")
    report = FailedDeliveryReport(order_id=order_id, shipper_id=shipper_id, reason=reason, note=note, evidence_image_url=evidence_image_url)
    db.add(report)
    order.order_status = "da_huy"
    db.commit()
    return {"id": report.id, "order_id": order_id, "reason": reason}


def get_shipper_reviews(db: Session, shipper_id: str, page: int = 1, limit: int = 10) -> Dict[str, Any]:
    from app.models.models import ReviewShipper
    skip = (page - 1) * limit
    q = db.query(ReviewShipper).filter(ReviewShipper.shipper_id == shipper_id)
    total = q.count()
    rows = q.order_by(ReviewShipper.review_shipper_date.desc()).offset(skip).limit(limit).all()
    items = [{"rating": r.rating_shipper, "comment": r.comment_shipper, "ngay": r.review_shipper_date} for r in rows]
    return {"items": items, "total": total, "page": page, "limit": limit}


def get_shipper_notifications(db: Session, user_id: str, page: int = 1, limit: int = 20) -> Dict[str, Any]:
    from app.models.models import Notification
    skip = (page - 1) * limit
    q = db.query(Notification).filter(Notification.user_id == user_id)
    total = q.count()
    rows = q.order_by(Notification.created_at.desc()).offset(skip).limit(limit).all()
    items = [{"noti_id": n.noti_id, "title": n.title, "body": n.body, "is_read": n.is_read, "created_at": n.created_at} for n in rows]
    return {"items": items, "total": total}


def mark_notification_read(db: Session, user_id: str, noti_id: int) -> bool:
    from app.models.models import Notification
    noti = db.query(Notification).filter(Notification.noti_id == noti_id, Notification.user_id == user_id).first()
    if not noti:
        return False
    noti.is_read = True
    db.commit()
    return True


def mark_all_notifications_read(db: Session, user_id: str) -> int:
    from app.models.models import Notification
    count = db.query(Notification).filter(Notification.user_id == user_id, Notification.is_read == False).update({"is_read": True})
    db.commit()
    return count
