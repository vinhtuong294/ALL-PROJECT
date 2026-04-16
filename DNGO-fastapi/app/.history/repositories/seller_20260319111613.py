from sqlalchemy.orm import Session
from sqlalchemy import and_
from typing import Optional, Dict, Any
from datetime import datetime
from app.models.models import Stall, Goods, Ingredient, Order, OrderDetail, Ingredient, Buyer
from app.utils.paginate import paginate, create_meta
from app.utils.vietnamese import remove_accents


def get_stall_id(db: Session, user_id: str) -> str:
    stall = db.query(Stall).filter(Stall.user_id == user_id).first()
    if not stall:
        raise Exception("Người dùng chưa đăng ký gian hàng")
    return stall.stall_id


def list_products(db: Session, user_id: str, page: int = 1, limit: int = 10,
                  search: Optional[str] = None, sort: str = "update_date",
                  order: str = "desc") -> Dict[str, Any]:

    stall_id = get_stall_id(db, user_id)
    pagination = paginate(page, limit)

    query = db.query(Goods).filter(Goods.stall_id == stall_id)

    # Search không dấu (Refactored to DB-level for performance)
    if search:
        search_pattern = f"%{search}%"
        query = query.join(Ingredient).filter(Ingredient.ingredient_name.ilike(search_pattern))

    SORT_MAP = {
        "update_date": Goods.update_date,
        "good_price": Goods.good_price,
        "inventory": Goods.inventory,
        "discount": Goods.discount,
    }
    sort_col = SORT_MAP.get(sort, Goods.update_date)
    if order == "asc":
        query = query.order_by(sort_col.asc())
    else:
        query = query.order_by(sort_col.desc())

    total = query.count()
    rows = query.offset(pagination["skip"]).limit(pagination["take"]).all()

    data = [
        {
            "ma_nguyen_lieu": r.ingredient_id,
            "ten_nguyen_lieu": r.ingredient.ingredient_name if r.ingredient else None,
            "hinh_anh": r.good_image,
            "so_luong_ban": r.inventory,
            "gia_goc": r.good_price,
            "gia_cuoi": float((r.good_price or 0) * (1 - (r.discount or 0) / 100)),
            "don_vi_ban": r.unit,
            "phan_tram_giam_gia": r.discount,
            "ngay_cap_nhat": r.update_date,
        }
        for r in rows
    ]

    return {
        "data": data,
        "meta": create_meta(pagination["page"], pagination["take"], total)
    }


def add_product(db: Session, user_id: str, ingredient_id: str, good_image: str,
                inventory: float, good_price: int, unit: str,
                discount: Optional[float] = None,
                sale_start_date=None, sale_end_date=None) -> Dict[str, Any]:

    stall_id = get_stall_id(db, user_id)

    exists = db.query(Goods).filter(
        Goods.ingredient_id == ingredient_id,
        Goods.stall_id == stall_id
    ).first()

    if exists:
        raise Exception("Sản phẩm này đã có trong gian hàng của bạn")

    good = Goods(
        ingredient_id=ingredient_id,
        stall_id=stall_id,
        good_image=good_image,
        inventory=inventory,
        good_price=good_price,
        unit=unit,
        discount=discount,
        sale_start_date=sale_start_date,
        sale_end_date=sale_end_date,
        update_date=datetime.utcnow()
    )
    db.add(good)
    db.commit()
    db.refresh(good)

    return {
        "ma_nguyen_lieu": good.ingredient_id,
        "ma_gian_hang": good.stall_id,
        "hinh_anh": good.good_image,
        "so_luong_ban": good.inventory,
        "gia_goc": good.good_price,
        "gia_cuoi": float((good.good_price or 0) * (1 - (good.discount or 0) / 100)),
        "don_vi_ban": good.unit,
        "phan_tram_giam_gia": good.discount,
        "ngay_cap_nhat": good.update_date,
    }


def update_product(db: Session, user_id: str, ingredient_id: str,
                   good_image: Optional[str] = None, inventory: Optional[float] = None,
                   good_price: Optional[int] = None, unit: Optional[str] = None,
                   discount: Optional[float] = None,
                   sale_start_date=None, sale_end_date=None) -> Dict[str, Any]:

    stall_id = get_stall_id(db, user_id)

    good = db.query(Goods).filter(
        Goods.ingredient_id == ingredient_id,
        Goods.stall_id == stall_id
    ).first()

    if not good:
        raise Exception("Sản phẩm không tồn tại trong gian hàng")

    if good_image is not None:
        good.good_image = good_image
    if inventory is not None:
        good.inventory = inventory
    if good_price is not None:
        good.good_price = good_price
    if unit is not None:
        good.unit = unit
    if discount is not None:
        good.discount = discount
    if sale_start_date is not None:
        good.sale_start_date = sale_start_date
    if sale_end_date is not None:
        good.sale_end_date = sale_end_date

    good.update_date = datetime.utcnow()
    db.commit()
    db.refresh(good)

    return {
        "ma_nguyen_lieu": good.ingredient_id,
        "ma_gian_hang": good.stall_id,
        "hinh_anh": good.good_image,
        "so_luong_ban": good.inventory,
        "gia_goc": good.good_price,
        "gia_cuoi": float((good.good_price or 0) * (1 - (good.discount or 0) / 100)),
        "don_vi_ban": good.unit,
        "phan_tram_giam_gia": good.discount,
        "ngay_cap_nhat": good.update_date,
    }


def delete_product(db: Session, user_id: str, ingredient_id: str):
    stall_id = get_stall_id(db, user_id)

    good = db.query(Goods).filter(
        Goods.ingredient_id == ingredient_id,
        Goods.stall_id == stall_id
    ).first()

    if not good:
        raise Exception("Sản phẩm không tồn tại trong gian hàng")

    db.delete(good)
    db.commit()
    
def get_revenue(db: Session, user_id: str, from_date: str, to_date: str) -> Dict[str, Any]:
    from app.models.models import Order, OrderDetail
    from sqlalchemy import func
    from datetime import datetime

    stall_id = get_stall_id(db, user_id)

    try:
        start = datetime.strptime(from_date, "%Y-%m-%d")
        end = datetime.strptime(to_date, "%Y-%m-%d").replace(hour=23, minute=59, second=59)
    except ValueError:
        raise Exception("Định dạng ngày không hợp lệ, dùng YYYY-MM-DD")

    rows = (
        db.query(
            func.date(Order.delivery_time).label("ngay"),
            func.sum(OrderDetail.final_price * OrderDetail.quantity_order).label("doanh_thu")
        )
        .join(OrderDetail, OrderDetail.order_id == Order.order_id)
        .filter(
            OrderDetail.stall_id == stall_id,
            Order.delivery_time >= start,
            Order.delivery_time <= end,
            Order.order_status != "da_huy"
        )
        .group_by(func.date(Order.delivery_time))
        .order_by(func.date(Order.delivery_time))
        .all()
    )

    data = [{"ngay": str(r.ngay), "doanh_thu": float(r.doanh_thu)} for r in rows]
    tong = sum(r["doanh_thu"] for r in data)

    return {
        "stall_id": stall_id,
        "from_date": from_date,
        "to_date": to_date,
        "tong_doanh_thu": tong,
        "chi_tiet": data
    }
    
def update_my_stall_status(db: Session, user_id: str, status: str):
    from app.models.models import Stall, User

    if status not in ["mo_cua", "dong_cua"]:
        raise Exception("Trạng thái không hợp lệ, chỉ chấp nhận mo_cua hoặc dong_cua")

    stall = db.query(Stall).filter(Stall.user_id == user_id).first()
    if not stall:
        raise Exception("Không tìm thấy gian hàng")

    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        raise Exception("Không tìm thấy người dùng")

    user.active_status = status
    db.commit()

    return {"success": True, "message": "Cập nhật trạng thái gian hàng thành công"}

def get_orders(db: Session, user_id: str, page: int = 1, limit: int = 10):
    from app.models.models import Order, OrderDetail, Ingredient, User as UserModel
    from sqlalchemy import desc

    stall_id = get_stall_id(db, user_id)
    offset = (page - 1) * limit

    # Lấy danh sách order có chứa sản phẩm của gian hàng này
    orders = (
        db.query(Order)
        .join(OrderDetail, OrderDetail.order_id == Order.order_id)
        .filter(
            OrderDetail.stall_id == stall_id,
            Order.order_status != "da_huy"
        )
        .distinct()
        .order_by(desc(Order.delivery_time))
        .offset(offset)
        .limit(limit)
        .all()
    )

    total = (
        db.query(Order)
        .join(OrderDetail, OrderDetail.order_id == Order.order_id)
        .filter(
            OrderDetail.stall_id == stall_id,
            Order.order_status != "da_huy"
        )
        .distinct()
        .count()
    )

    data = []
    for order in orders:
        # Lấy thông tin người mua
        
        buyer = db.query(Buyer).filter(Buyer.buyer_id == order.buyer_id).first()
        # Lấy nguyên liệu của gian hàng này trong đơn hàng
        items = (
            db.query(OrderDetail, Ingredient)
            .join(Ingredient, Ingredient.ingredient_id == OrderDetail.ingredient_id)
            .filter(
                OrderDetail.order_id == order.order_id,
                OrderDetail.stall_id == stall_id
            )
            .all()
        )

        data.append({
            "order_id": order.order_id,
            "order_status": order.order_status,
            "delivery_time": str(order.delivery_time),
            "delivery_address": order.delivery_address,
            "nguoi_mua": buyer.buyer_name if buyer else "Không rõ",
            "nguyen_lieu": [
                {
                    "ingredient_id": od.ingredient_id,
                    "ingredient_name": ing.ingredient_name,
                    "quantity": od.quantity_order,
                    "price": float(od.final_price)
                }
                for od, ing in items
            ]
        })

    return {
        "success": True,
        "data": data,
        "meta": {
            "page": page,
            "limit": limit,
            "total": total,
            "total_pages": (total + limit - 1) // limit
        }
    }