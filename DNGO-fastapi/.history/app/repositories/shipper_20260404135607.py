from sqlalchemy.orm import Session
from sqlalchemy import and_
from typing import Optional, Dict, Any
from datetime import datetime
from app.models.models import (
    Shipper, Order, OrderDetail, Consolidation,
    Buyer, User, TimeSlot, Payment
)
import secrets


def gen_consolidation_id():
    rand = secrets.token_urlsafe(6)[:8].upper()
    return f"GD{rand}"


def get_shipper_by_user_id(db: Session, user_id: str):
    return db.query(Shipper).filter(Shipper.user_id == user_id).first()


def list_available_orders(db: Session, page: int = 1, limit: int = 10,
                          order_status: Optional[str] = None) -> Dict[str, Any]:
    skip = (page - 1) * limit

    if order_status:
        query = db.query(Order).filter(Order.order_status == order_status)
    else:
        query = db.query(Order).filter(
            Order.order_status.in_(["da_xac_nhan", "dang_giao"])
        )

    # Sort theo distance_km từ thấp đến cao
    query = query.order_by(Order.distance_km.asc().nullslast())
    total = query.count()
    orders = query.offset(skip).limit(limit).all()

    items = []
    for order in orders:
        consolidation = db.query(Consolidation).filter(
            Consolidation.consolidation_id == order.consolidation_id
        ).first() if order.consolidation_id else None

        shipper_info = None
        if consolidation:
            shipper = consolidation.shipper
            shipper_info = {
                "ma_gom_don": consolidation.consolidation_id,
                "ma_shipper": shipper.shipper_id if shipper else None,
                "ten_shipper": shipper.user.user_name if shipper and shipper.user else None,
                "sdt_shipper": shipper.user.phone if shipper and shipper.user else None,
            }

        time_slot = db.query(TimeSlot).filter(
            TimeSlot.time_slot_id == order.time_slot_id
        ).first() if order.time_slot_id else None

        items.append({
            "ma_don_hang": order.order_id,
            "tong_tien": order.total_amount,
            "dia_chi_giao_hang": order.delivery_address,
            "tinh_trang_don_hang": order.order_status,
            "thoi_gian_giao_hang": order.delivery_time,
            "distance_km": order.distance_km,  # thêm dòng này
            "khung_gio": {
                "time_slot_id": time_slot.time_slot_id,
                "gio_bat_dau": time_slot.start_time,
                "gio_ket_thuc": time_slot.end_time,
            } if time_slot else None,
            "nguoi_mua": {
                "buyer_id": order.buyer.buyer_id,
                "ten_nguoi_dung": order.buyer.user.user_name if order.buyer and order.buyer.user else None,
                "sdt": order.buyer.user.phone if order.buyer and order.buyer.user else None,
                "dia_chi": order.buyer.user.address if order.buyer and order.buyer.user else None,
            } if order.buyer else None,
            "thanh_toan": {
                "hinh_thuc_thanh_toan": order.payment.payment_method,
                "tinh_trang_thanh_toan": order.payment.payment_status,
            } if order.payment else None,
            "shipper_info": shipper_info,
        })

    return {
        "items": items,
        "total": total,
        "page": page,
        "limit": limit,
        "totalPages": (total + limit - 1) // limit,
    }


def list_my_orders(db: Session, shipper_id: str, page: int = 1, limit: int = 10,
                   order_status: Optional[str] = None) -> Dict[str, Any]:
    skip = (page - 1) * limit

    query = db.query(Order).filter(
        Order.consolidation_id == Consolidation.consolidation_id,
        Consolidation.shipper_id == shipper_id
    )

    if order_status:
        query = query.filter(Order.order_status == order_status)

    query = query.order_by(Order.delivery_time.asc())
    total = query.count()
    orders = query.offset(skip).limit(limit).all()

    items = []
    for order in orders:
        consolidation = db.query(Consolidation).filter(
            Consolidation.consolidation_id == order.consolidation_id
        ).first() if order.consolidation_id else None

        time_slot = db.query(TimeSlot).filter(
            TimeSlot.time_slot_id == order.time_slot_id
        ).first() if order.time_slot_id else None

        items.append({
            "ma_don_hang": order.order_id,
            "tong_tien": order.total_amount,
            "dia_chi_giao_hang": order.delivery_address,
            "tinh_trang_don_hang": order.order_status,
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
                "dia_chi": order.buyer.user.address if order.buyer and order.buyer.user else None,
            } if order.buyer else None,
            "thanh_toan": {
                "hinh_thuc_thanh_toan": order.payment.payment_method,
                "tinh_trang_thanh_toan": order.payment.payment_status,
            } if order.payment else None,
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
    order = db.query(Order).filter(Order.order_id == order_id).first()

    if not order:
        raise LookupError("ORDER_NOT_FOUND")

    if order.order_status != "da_xac_nhan":
        raise ValueError("Chỉ có thể nhận đơn hàng đã xác nhận")

    # Kiểm tra đã có consolidation chưa
    if order.consolidation_id:
        consolidation = db.query(Consolidation).filter(
            Consolidation.consolidation_id == order.consolidation_id
        ).first()
        if consolidation and consolidation.shipper_id != shipper_id:
            raise PermissionError("Đơn hàng đã được shipper khác nhận")
        return {"gom_don": {"ma_gom_don": consolidation.consolidation_id}, "is_new": False}

    # Tạo consolidation mới
    consolidation = Consolidation(
        consolidation_id=gen_consolidation_id(),
        shipper_id=shipper_id
    )
    db.add(consolidation)
    db.flush()

    order.consolidation_id = consolidation.consolidation_id
    order.order_status = "dang_giao"
    db.commit()

    return {
        "gom_don": {"ma_gom_don": consolidation.consolidation_id},
        "is_new": True
    }


def update_order_status(db: Session, shipper_id: str, order_id: str,
                        new_status: str) -> Dict[str, Any]:
    allowed = ["dang_giao", "da_giao", "hoan_thanh"]
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
    if new_status == "dang_giao" and current not in ("da_xac_nhan", "dang_giao"):
        raise ValueError("Chỉ có thể bắt đầu giao từ trạng thái 'da_xac_nhan'")
    if new_status == "da_giao" and current != "dang_giao":
        raise ValueError("Chỉ có thể đánh dấu đã giao từ trạng thái 'dang_giao'")
    if new_status == "hoan_thanh" and current != "da_giao":
        raise ValueError("Chỉ có thể hoàn thành từ trạng thái 'da_giao'")

    order.order_status = new_status
    db.commit()
    db.refresh(order)

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
    from app.models.models import Order, OrderDetail, Ingredient, Stall

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

    return {
        "ma_don_hang": order.order_id,
        "tong_tien": order.total_amount,
        "dia_chi_giao_hang": order.delivery_address,
        "tinh_trang_don_hang": order.order_status,
        "thoi_gian_giao_hang": order.delivery_time,
        "distance_km": order.distance_km,
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
                "detail_status": od.detail_status
            }
            for od, ing, stall in details
        ]
    }
    
