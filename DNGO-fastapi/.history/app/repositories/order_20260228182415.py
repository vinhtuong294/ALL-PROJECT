from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional, Dict, Any
from app.models.models import (
    Order, OrderDetail, Payment, Buyer, Cart, CartDetail,
    Consolidation, Shipper, Goods, Ingredient, Stall, TimeSlot
)


def get_buyer(db: Session, user_id: str):
    return db.query(Buyer).filter(Buyer.user_id == user_id).first()


def list_orders(db: Session, user_id: str, page: int = 1, limit: int = 12,
                order_status: Optional[str] = None, sort: str = "delivery_time",
                order: str = "desc") -> Dict[str, Any]:

    buyer = get_buyer(db, user_id)
    if not buyer:
        raise Exception("Buyer profile not found")

    query = db.query(Order).filter(Order.buyer_id == buyer.buyer_id)

    if order_status:
        query = query.filter(Order.order_status == order_status)

    SORT_MAP = {
        "delivery_time": Order.delivery_time,
        "total_amount": Order.total_amount,
        "order_status": Order.order_status,
    }
    sort_col = SORT_MAP.get(sort, Order.delivery_time)
    if order == "asc":
        query = query.order_by(sort_col.asc())
    else:
        query = query.order_by(sort_col.desc())

    total = query.count()
    rows = query.offset((page - 1) * limit).limit(limit).all()

    items = []
    for o in rows:
        items.append({
            "ma_don_hang": o.order_id,
            "tong_tien": o.total_amount,
            "dia_chi_giao_hang": o.delivery_address,
            "tinh_trang_don_hang": o.order_status,
            "thoi_gian_giao_hang": o.delivery_time,
            "ma_thanh_toan": o.payment_id,
            "thanh_toan": {
                "ma_thanh_toan": o.payment.payment_id,
                "hinh_thuc_thanh_toan": o.payment.payment_method,
                "tinh_trang_thanh_toan": o.payment.payment_status,
                "thoi_gian_thanh_toan": o.payment.payment_time,
            } if o.payment else None,
        })

    return {
        "items": items,
        "total": total,
        "page": page,
        "limit": limit,
        "totalPages": (total + limit - 1) // limit,
    }


def get_order_detail(db: Session, order_id: str, user_id: str) -> Optional[Dict[str, Any]]:

    buyer = get_buyer(db, user_id)
    if not buyer:
        return None

    order = db.query(Order).filter(
        Order.order_id == order_id,
        Order.buyer_id == buyer.buyer_id
    ).first()

    if not order:
        return None

    order_details = db.query(OrderDetail).filter(OrderDetail.order_id == order_id).all()

    enriched_items = []
    for item in order_details:
        goods = db.query(Goods).filter(
            Goods.ingredient_id == item.ingredient_id,
            Goods.stall_id == item.stall_id
        ).first()

        enriched_items.append({
            "ma_nguyen_lieu": item.ingredient_id,
            "ma_gian_hang": item.stall_id,
            "so_luong": item.quantity_order,
            "gia_cuoi": item.final_price,
            "thanh_tien": (item.final_price or 0) * (item.quantity_order or 0),
            "ma_mon_an": item.dish_id,
            "nguyen_lieu": {
                "ma_nguyen_lieu": goods.ingredient.ingredient_id,
                "ten_nguyen_lieu": goods.ingredient.ingredient_name,
                "don_vi": goods.unit,
            } if goods and goods.ingredient else None,
            "gian_hang": {
                "ma_gian_hang": goods.stall.stall_id,
                "ten_gian_hang": goods.stall.stall_name,
                "vi_tri": goods.stall.stall_location,
                "hinh_anh": goods.stall.stall_image,
            } if goods and goods.stall else None,
            "don_vi_ban": goods.unit if goods else None,
        })

    return {
        "ma_don_hang": order.order_id,
        "tong_tien": order.total_amount,
        "dia_chi_giao_hang": order.delivery_address,
        "tinh_trang_don_hang": order.order_status,
        "thoi_gian_giao_hang": order.delivery_time,
        "ma_thanh_toan": order.payment_id,
        "thanh_toan": {
            "ma_thanh_toan": order.payment.payment_id,
            "hinh_thuc_thanh_toan": order.payment.payment_method,
            "tai_khoan_thanh_toan": order.payment.payment_account,
            "thoi_gian_thanh_toan": order.payment.payment_time,
            "tinh_trang_thanh_toan": order.payment.payment_status,
        } if order.payment else None,
        "items": enriched_items,
    }


def check_shipper_status(db: Session, order_id: str) -> Optional[Dict[str, Any]]:

    consolidation = db.query(Consolidation).join(Order).filter(
        Order.order_id == order_id,
        Order.consolidation_id == Consolidation.consolidation_id
    ).first()

    if not consolidation:
        return None

    shipper = consolidation.shipper

    return {
        "ma_gom_don": consolidation.consolidation_id,
        "shipper": {
            "ma_shipper": shipper.shipper_id,
            "ten_nguoi_dung": shipper.user.user_name if shipper.user else None,
            "sdt": shipper.user.phone if shipper.user else None,
            "phuong_tien": shipper.vehicle_type,
            "bien_so_xe": shipper.vehicle_plate,
        },
    }


def cancel_order(db: Session, order_id: str, user_id: str) -> Dict[str, Any]:

    buyer = get_buyer(db, user_id)
    if not buyer:
        raise Exception("Buyer profile not found")

    order = db.query(Order).filter(
        Order.order_id == order_id,
        Order.buyer_id == buyer.buyer_id
    ).first()

    if not order:
        raise Exception("Đơn hàng không tồn tại hoặc bạn không có quyền truy cập")

    if order.order_status not in ("chua_xac_nhan", "da_xac_nhan"):
        raise Exception(f"Không thể hủy đơn hàng ở trạng thái \"{order.order_status}\".")

    order_details = db.query(OrderDetail).filter(OrderDetail.order_id == order_id).all()

    if not order_details:
        raise Exception("Đơn hàng không có sản phẩm nào")

    # Lấy hoặc tạo cart
    cart = db.query(Cart).filter(Cart.buyer_id == buyer.buyer_id).order_by(Cart.cart_date.desc()).first()
    if not cart:
        raise Exception("Không tìm thấy giỏ hàng")

    # Khôi phục sản phẩm về giỏ hàng
    restored_items = []
    for item in order_details:
        existing = db.query(CartDetail).filter(
            CartDetail.cart_id == cart.cart_id,
            CartDetail.ingredient_id == item.ingredient_id,
            CartDetail.stall_id == item.stall_id
        ).first()

        if existing:
            existing.cart_quantity += item.quantity_order
        else:
            new_cart_detail = CartDetail(
                cart_id=cart.cart_id,
                ingredient_id=item.ingredient_id,
                stall_id=item.stall_id,
                cart_quantity=item.quantity_order,
            )
            db.add(new_cart_detail)

        restored_items.append({
            "ma_nguyen_lieu": item.ingredient_id,
            "ma_gian_hang": item.stall_id,
            "so_luong": item.quantity_order,
        })

    if order.order_status == "chua_xac_nhan":
    # Xóa order details
        db.query(OrderDetail).filter(OrderDetail.order_id == order_id).delete()
    # Xóa payment
        if order.payment_id:
            payment = db.query(Payment).filter(Payment.payment_id == order.payment_id).first()
            if payment:
                order.payment_id = None
                db.flush()
                db.delete(payment)
    # Xóa order
        db.delete(order)
    else:
    # da_xac_nhan -> chuyển thành da_huy
        order.order_status = "da_huy"

    db.commit()

    # Xóa order details
    db.query(OrderDetail).filter(OrderDetail.order_id == order_id).delete()

    # Xóa order
    db.delete(order)
    db.commit()

    return {
        "ma_don_hang": order_id,
        "restored_items": restored_items,
        "so_mat_hang": len(restored_items),
        "message": "Đơn hàng đã được hủy và sản phẩm đã được khôi phục về giỏ hàng",
    }