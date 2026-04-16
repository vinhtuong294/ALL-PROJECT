from sqlalchemy.orm import Session
from sqlalchemy import func, and_, or_
from typing import Optional, Dict, Any, List
from app.models.models import (
    District, Market, Stall, Category, Ingredient, Goods,
    DishGroup, Dish, DishClassification, Recipe, Order, OrderDetail)
from app.utils.paginate import paginate, create_meta
from app.utils.vietnamese import remove_accents


def list_districts(
    db: Session,
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    sort: str = "district_name",
    order: str = "asc"
) -> Dict[str, Any]:
    """Lấy danh sách khu vực"""
    
    pagination = paginate(page, limit)
    
    query = db.query(District)
    
    # Search không dấu (Refactored to DB-level for performance)
    if search:
        search_pattern = f"%{search}%"
        query = query.filter(District.district_name.ilike(search_pattern))
    
    sort_column = getattr(District, sort if sort in ["district_id", "district_name"] else "district_name")
    if order == "desc":
        query = query.order_by(sort_column.desc())
    else:
        query = query.order_by(sort_column.asc())
    
    total = query.count()
    rows = query.offset(pagination["skip"]).limit(pagination["take"]).all()
    
    district_ids = [r.district_id for r in rows]
    market_counts = {}
    
    if district_ids:
        counts = db.query(
            Market.district_id,
            func.count(Market.market_id).label("count")
        ).filter(
            Market.district_id.in_(district_ids)
        ).group_by(Market.district_id).all()
        
        market_counts = {c.district_id: c.count for c in counts}
    
    data = [
        {
            "ma_khu_vuc": r.district_id,
            "phuong": r.district_name,
            "longitude": None,
            "latitude": None,
            "so_cho": market_counts.get(r.district_id, 0)
        }
        for r in rows
    ]
    
    return {
        "data": data,
        "meta": create_meta(pagination["page"], pagination["take"], total)
    }


def list_markets(
    db: Session,
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    district_id: Optional[str] = None,
    sort: str = "market_name",
    order: str = "asc"
) -> Dict[str, Any]:
    """Lấy danh sách chợ"""
    
    pagination = paginate(page, limit)
    
    query = db.query(Market).join(District)
    
    if district_id:
        query = query.filter(Market.district_id == district_id)
    
    # Search không dấu (Refactored to DB-level for performance)
    if search:
        search_pattern = f"%{search}%"
        query = query.filter(
            or_(
                Market.market_name.ilike(search_pattern),
                Market.market_address.ilike(search_pattern)
            )
        )
    
    sort_map = {
        "market_name": Market.market_name,
        "market_id": Market.market_id,
        "market_address": Market.market_address
    }
    sort_column = sort_map.get(sort, Market.market_name)
    
    if order == "desc":
        query = query.order_by(sort_column.desc())
    else:
        query = query.order_by(sort_column.asc())
    
    total = query.count()
    rows = query.offset(pagination["skip"]).limit(pagination["take"]).all()
    
    market_ids = [r.market_id for r in rows]
    stall_counts = {}
    
    if market_ids:
        counts = db.query(
            Stall.market_id,
            func.count(Stall.stall_id).label("count")
        ).filter(
            Stall.market_id.in_(market_ids)
        ).group_by(Stall.market_id).all()
        
        stall_counts = {c.market_id: c.count for c in counts}
    
    data = [
        {
            "ma_cho": r.market_id,
            "ten_cho": r.market_name,
            "ma_khu_vuc": r.district_id,
            "ten_khu_vuc": r.district.district_name if r.district else None,
            "dia_chi": r.market_address,
            "hinh_anh": r.market_image,
            "so_gian_hang": stall_counts.get(r.market_id, 0)
        }
        for r in rows
    ]
    
    return {
        "data": data,
        "meta": create_meta(pagination["page"], pagination["take"], total)
    }


def list_stalls(
    db: Session,
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    market_id: Optional[str] = None,
    sort: str = "stall_name",
    order: str = "asc"
) -> Dict[str, Any]:
    """Lấy danh sách gian hàng"""
    
    pagination = paginate(page, limit)
    
    query = db.query(Stall)
    
    if market_id:
        query = query.filter(Stall.market_id == market_id)
    
    # Search không dấu (Refactored to DB-level for performance)
    if search:
        search_pattern = f"%{search}%"
        query = query.filter(
            or_(
                Stall.stall_name.ilike(search_pattern),
                Stall.stall_location.ilike(search_pattern)
            )
        )
    
    sort_map = {
        "stall_name": Stall.stall_name,
        "stall_location": Stall.stall_location,
        "avr_rating": Stall.avr_rating,
        "stall_id": Stall.stall_id
    }
    sort_column = sort_map.get(sort, Stall.stall_name)
    
    if order == "desc":
        query = query.order_by(sort_column.desc())
    else:
        query = query.order_by(sort_column.asc())
    
    total = query.count()
    rows = query.offset(pagination["skip"]).limit(pagination["take"]).all()
    
    data = [
    {
        "ma_gian_hang": r.stall_id,
        "ten_gian_hang": r.stall_name,
        "vi_tri": r.stall_location,
        "hinh_anh": r.stall_image,
        "danh_gia_tb": r.avr_rating,
        "ma_cho": r.market_id,
        # Thêm thông tin vị trí
        "vi_tri_gian_hang": {
            "cot": r.grid_col,
            "hang": r.grid_row,
            "tang": r.grid_floor
        }
    }
    for r in rows
]
    
    return {
        "data": data,
        "meta": create_meta(pagination["page"], pagination["take"], total)
    }


def get_stall_detail(
    db: Session,
    stall_id: str,
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    sort: str = "update_date",
    order: str = "desc"
) -> Optional[Dict[str, Any]]:
    """Lấy chi tiết gian hàng"""
    
    pagination = paginate(page, limit)
    
    stall = db.query(Stall).filter(Stall.stall_id == stall_id).first()
    
    if not stall:
        return None
    
    product_count = db.query(Goods).filter(Goods.stall_id == stall_id).count()
    review_count = 0
    
    product_query = db.query(Goods).join(Ingredient).filter(Goods.stall_id == stall_id)
    
    # Search không dấu cho sản phẩm (Refactored to DB-level)
    if search:
        search_pattern = f"%{search}%"
        product_query = product_query.filter(
            Ingredient.ingredient_name.ilike(search_pattern)
        )

    # --- THÊM ĐOẠN NÀY ---
    SORT_MAP = {
        "ten_nguyen_lieu": Ingredient.ingredient_name,
        "gia_goc": Goods.good_price,
        "gia_cuoi": Goods.good_price,
        "so_luong_ban": Goods.inventory,
        "ngay_cap_nhat": Goods.update_date,
        "update_date": Goods.update_date,
    }
    sort_col = SORT_MAP.get(sort, Goods.update_date)
    if order == "asc":
        product_query = product_query.order_by(sort_col.asc())
    else:
        product_query = product_query.order_by(sort_col.desc())
    # ----------------------

    product_total = product_query.count()
    products = product_query.offset(pagination["skip"]).limit(pagination["take"]).all()
    
    product_data = [
        {
            "ma_nguyen_lieu": p.ingredient_id,
            "ten_nguyen_lieu": p.ingredient.ingredient_name if p.ingredient else None,
            "don_vi": p.unit,
            "ma_nhom_nguyen_lieu": p.ingredient.category_id if p.ingredient else None,
            "ten_nhom_nguyen_lieu": p.ingredient.category.category_name if p.ingredient and p.ingredient.category else None,
            "hinh_anh": p.good_image,
            "gia_goc": p.good_price,
            "gia_cuoi": float(p.good_price * (1 - (p.discount or 0) / 100)),
            "so_luong_ban": p.inventory,
            "phan_tram_giam_gia": p.discount,
            "ngay_cap_nhat": p.update_date
        }
        for p in products
    ]
    
    market_info = None
    if stall.market:
        market_info = {
            "ma_cho": stall.market.market_id,
            "ten_cho": stall.market.market_name,
            "dia_chi": stall.market.market_address,
            "hinh_anh": stall.market.market_image,
            "khu_vuc": {
                "ma_khu_vuc": stall.market.district_id,
                "phuong": stall.market.district.district_name if stall.market.district else None
            } if stall.market.district_id else None
        }
    
    return {
        "detail": {
            "ma_gian_hang": stall.stall_id,
            "ten_gian_hang": stall.stall_name,
            "vi_tri": stall.stall_location,
            "hinh_anh": stall.stall_image,
            "danh_gia_tb": stall.avr_rating,
            "ngay_dang_ky": stall.signup_date,
            "so_san_pham": product_count,
            "so_danh_gia": review_count,
            "cho": market_info,
            "vi_tri_gian_hang": {
                "cot": stall.grid_col,
                "hang": stall.grid_row,
                "tang": stall.grid_floor
            }
        },
        "san_pham": {
            "data": product_data,
            "meta": create_meta(pagination["page"], pagination["take"], product_total)
        }
    }


def list_ingredients(
    db: Session,
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    category_id: Optional[str] = None,
    market_id: Optional[str] = None,
    stall_id: Optional[str] = None,
    has_image: Optional[bool] = None,
    sort: str = "ingredient_name",
    order: str = "asc"
) -> Dict[str, Any]:
    """Lấy danh sách nguyên liệu"""

    pagination = paginate(page, limit)

    # Query nguyên liệu
    query = db.query(Ingredient)

    if category_id:
        query = query.filter(Ingredient.category_id == category_id)

    if search:
        search_pattern = f"%{search}%"
        query = query.filter(Ingredient.ingredient_name.ilike(search_pattern))

    # Lọc theo stall/market nếu có
    if stall_id or market_id or has_image:
        goods_query = db.query(Goods.ingredient_id).filter(Goods.ingredient_id.isnot(None))
        if stall_id:
            goods_query = goods_query.filter(Goods.stall_id == stall_id)
        if market_id:
            goods_query = goods_query.join(Stall).filter(Stall.market_id == market_id)
        if has_image:
            goods_query = goods_query.filter(Goods.good_image.isnot(None), Goods.good_image != "")
        ingredient_ids_with_goods = [r[0] for r in goods_query.distinct().all()]
        query = query.filter(Ingredient.ingredient_id.in_(ingredient_ids_with_goods))

    # Sort
    SORT_MAP = {
        "ingredient_name": Ingredient.ingredient_name,
        "ingredient_id": Ingredient.ingredient_id,
        "ten_nguyen_lieu": Ingredient.ingredient_name,
        "ma_nguyen_lieu": Ingredient.ingredient_id,
    }
    sort_col = SORT_MAP.get(sort, Ingredient.ingredient_name)
    if order == "desc":
        query = query.order_by(sort_col.desc())
    else:
        query = query.order_by(sort_col.asc())

    total = query.count()
    rows = query.offset(pagination["skip"]).limit(pagination["take"]).all()

    if not rows:
        return {
            "data": [],
            "meta": create_meta(pagination["page"], pagination["take"], total)
        }

    ingredient_ids = [r.ingredient_id for r in rows]

    # Lọc goods theo filter
    goods_filter = [Goods.ingredient_id.in_(ingredient_ids)]
    if stall_id:
        goods_filter.append(Goods.stall_id == stall_id)
    if market_id:
        goods_filter.append(Stall.market_id == market_id)
    if has_image:
        goods_filter.append(Goods.good_image.isnot(None))
        goods_filter.append(Goods.good_image != "")

    # Đếm số gian hàng bán mỗi nguyên liệu
    seller_query = db.query(Goods.ingredient_id, Goods.stall_id).filter(*goods_filter)
    if market_id:
        seller_query = seller_query.join(Stall)
    seller_rows = seller_query.distinct().all()

    seller_count = {}
    for r in seller_rows:
        seller_count[r.ingredient_id] = seller_count.get(r.ingredient_id, 0) + 1

    # Lấy thông tin mới nhất của goods cho mỗi nguyên liệu
    latest_query = db.query(Goods).filter(*goods_filter)
    if market_id:
        latest_query = latest_query.join(Stall)
    latest_query = latest_query.order_by(Goods.ingredient_id.asc(), Goods.update_date.desc())
    latest_goods = latest_query.all()

    latest_map = {}
    for g in latest_goods:
        if g.ingredient_id not in latest_map:
            latest_map[g.ingredient_id] = g

    data = []
    for nl in rows:
        l = latest_map.get(nl.ingredient_id)
        data.append({
            "ma_nguyen_lieu": nl.ingredient_id,
            "ten_nguyen_lieu": nl.ingredient_name,
            "don_vi": l.unit if l else None,
            "ma_nhom_nguyen_lieu": nl.category_id,
            "ten_nhom_nguyen_lieu": nl.category.category_name if nl.category else None,
            "so_gian_hang": seller_count.get(nl.ingredient_id, 0),
            "gia_goc": l.good_price if l else None,
            "gia_cuoi": float((l.good_price or 0) * (1 - (l.discount or 0) / 100)) if l else None,
            "ngay_cap_nhat": l.update_date if l else None,
            "hinh_anh": l.good_image if l else None,
        })

    return {
        "data": data,
        "meta": create_meta(pagination["page"], pagination["take"], total)
    }


def get_ingredient_detail(
    db: Session,
    ingredient_id: str,
    page: int = 1,
    limit: int = 10,
    market_id: Optional[str] = None,
    sort: str = "update_date",
    order: str = "desc"
) -> Optional[Dict[str, Any]]:
    """Lấy chi tiết nguyên liệu"""

    pagination = paginate(page, limit)

    # Lấy thông tin nguyên liệu
    nl = db.query(Ingredient).filter(Ingredient.ingredient_id == ingredient_id).first()
    if not nl:
        return None

    # Query goods theo nguyên liệu + filter chợ
    goods_query = db.query(Goods).filter(Goods.ingredient_id == ingredient_id)
    if market_id:
        goods_query = goods_query.join(Stall).filter(Stall.market_id == market_id)

    # Đếm số gian hàng distinct
    all_goods = goods_query.all()
    seen_stalls = set()
    sellers_all = []
    stall_latest = {}

    # Lấy goods mới nhất theo từng gian hàng
    for g in sorted(all_goods, key=lambda x: x.update_date or "", reverse=True):
        if g.stall_id not in seen_stalls:
            seen_stalls.add(g.stall_id)
            stall_latest[g.stall_id] = g

    so_gian_hang = len(seen_stalls)

    # Lấy thông tin goods mới nhất toàn bộ
    latest = goods_query.order_by(Goods.update_date.desc()).first()

    # Build danh sách sellers
    for stall_id, g in stall_latest.items():
        stall = g.stall
        sellers_all.append({
            "ma_gian_hang": stall_id,
            "ten_gian_hang": stall.stall_name if stall else None,
            "vi_tri": stall.stall_location if stall else None,
            "ma_cho": stall.market_id if stall else None,
            "gia_goc": g.good_price,
            "gia_cuoi": float((g.good_price or 0) * (1 - (g.discount or 0) / 100)),
            "hinh_anh": g.good_image,
            "ngay_cap_nhat": g.update_date,
            "so_luong_ban": g.inventory,
            "don_vi_ban": g.unit,
        })

    # Sort sellers
    SORT_MAP = {
        "update_date": "ngay_cap_nhat",
        "ngay_cap_nhat": "ngay_cap_nhat",
        "gia_goc": "gia_goc",
        "gia_cuoi": "gia_cuoi",
        "so_luong_ban": "so_luong_ban",
    }
    sort_key = SORT_MAP.get(sort, "ngay_cap_nhat")
    reverse = order.lower() != "asc"
    sellers_all.sort(key=lambda x: (x[sort_key] is None, x[sort_key]), reverse=reverse)

    # Phân trang sellers
    skip = pagination["skip"]
    take = pagination["take"]
    sellers_page = sellers_all[skip: skip + take]
    sellers_total = len(sellers_all)

    return {
        "detail": {
            "ma_nguyen_lieu": nl.ingredient_id,
            "ten_nguyen_lieu": nl.ingredient_name,
            "don_vi": (latest.unit if latest else None),
            "ma_nhom_nguyen_lieu": nl.category_id,
            "ten_nhom_nguyen_lieu": nl.category.category_name if nl.category else None,
            "so_gian_hang": so_gian_hang,
            "gia_goc": latest.good_price if latest else None,
            "gia_cuoi": float((latest.good_price or 0) * (1 - (latest.discount or 0) / 100)) if latest else None,
            "ngay_cap_nhat_moi_nhat": latest.update_date if latest else None,
            "hinh_anh_moi_nhat": latest.good_image if latest else None,
        },
        "sellers": {
            "data": sellers_page,
            "meta": {
                "page": pagination["page"],
                "limit": take,
                "total": sellers_total,
                "hasNext": skip + take < sellers_total,
            }
        }
    }


def list_categories(
    db: Session,
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    sort: str = "category_name",
    order: str = "asc"
) -> Dict[str, Any]:
    """Lấy danh sách danh mục nguyên liệu"""
    
    pagination = paginate(page, limit)
    
    query = db.query(Category)
    
    if search:
        search_pattern = f"%{search}%"
        query = query.filter(Category.category_name.ilike(search_pattern))
    
    if order == "desc":
        query = query.order_by(Category.category_name.desc())
    else:
        query = query.order_by(Category.category_name.asc())
    
    total = query.count()
    rows = query.offset(pagination["skip"]).limit(pagination["take"]).all()
    
    category_ids = [r.category_id for r in rows]
    ingredient_counts = {}
    
    if category_ids:
        counts = db.query(
            Ingredient.category_id,
            func.count(Ingredient.ingredient_id).label("count")
        ).filter(
            Ingredient.category_id.in_(category_ids)
        ).group_by(Ingredient.category_id).all()
        
        ingredient_counts = {c.category_id: c.count for c in counts}
    
    data = [
        {
            "ma_nhom_nguyen_lieu": r.category_id,
            "ten_nhom_nguyen_lieu": r.category_name,
            "so_nguyen_lieu": ingredient_counts.get(r.category_id, 0)
        }
        for r in rows
    ]
    
    return {
        "data": data,
        "meta": create_meta(pagination["page"], pagination["take"], total)
    }


def list_dish_categories(
    db: Session,
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    sort: str = "group_name",
    order: str = "asc"
) -> Dict[str, Any]:
    """Lấy danh sách danh mục món ăn"""
    
    pagination = paginate(page, limit)
    
    query = db.query(DishGroup)
    
    if search:
        search_pattern = f"%{search}%"
        query = query.filter(DishGroup.group_name.ilike(search_pattern))
    
    if order == "desc":
        query = query.order_by(DishGroup.group_name.desc())
    else:
        query = query.order_by(DishGroup.group_name.asc())
    
    total = query.count()
    rows = query.offset(pagination["skip"]).limit(pagination["take"]).all()
    
    group_ids = [r.group_id for r in rows]
    dish_counts = {}
    
    if group_ids:
        counts = db.query(
            DishClassification.group_id,
            func.count(DishClassification.dish_id).label("count")
        ).filter(
            DishClassification.group_id.in_(group_ids)
        ).group_by(DishClassification.group_id).all()
        
        dish_counts = {c.group_id: c.count for c in counts}
    
    data = [
        {
            "ma_danh_muc_mon_an": r.group_id,
            "ten_danh_muc_mon_an": r.group_name,
            "so_mon_an": dish_counts.get(r.group_id, 0)
        }
        for r in rows
    ]
    
    return {
        "data": data,
        "meta": create_meta(pagination["page"], pagination["take"], total)
    }


def list_dishes(
    db: Session,
    page: int = 1,
    limit: int = 10,
    search: Optional[str] = None,
    category_id: Optional[str] = None,
    has_image: bool = False,
    sort: str = "dish_name",
    order: str = "asc"
) -> Dict[str, Any]:
    """Lấy danh sách món ăn"""
    
    pagination = paginate(page, limit)
    
    query = db.query(Dish)
    
    if category_id:
        query = query.join(DishClassification).filter(
            DishClassification.group_id == category_id
        )
    
    if has_image:
        query = query.filter(
            Dish.dish_image.isnot(None),
            Dish.dish_image != ""
        )
    
    # Search không dấu (Refactored to DB-level)
    if search:
        search_pattern = f"%{search}%"
        query = query.filter(Dish.dish_name.ilike(search_pattern))
    
    if order == "desc":
        query = query.order_by(Dish.dish_name.desc())
    else:
        query = query.order_by(Dish.dish_name.asc())
    
    total = query.count()
    rows = query.offset(pagination["skip"]).limit(pagination["take"]).all()
    
    dish_ids = [r.dish_id for r in rows]
    dish_categories = {}
    
    if dish_ids:
        classifications = db.query(DishClassification).join(DishGroup).filter(
            DishClassification.dish_id.in_(dish_ids)
        ).all()
        
        for c in classifications:
            if c.dish_id not in dish_categories:
                dish_categories[c.dish_id] = []
            dish_categories[c.dish_id].append({
                "ma_danh_muc_mon_an": c.group_id,
                "ten_danh_muc_mon_an": c.group.group_name if c.group else None
            })
    
    data = [
        {
            "ma_mon_an": r.dish_id,
            "ten_mon_an": r.dish_name,
            "hinh_anh": r.dish_image,
            "danh_muc": dish_categories.get(r.dish_id, [])
        }
        for r in rows
    ]
    
    return {
        "data": data,
        "meta": create_meta(pagination["page"], pagination["take"], total)
    }


def get_dish_detail(
    db: Session,
    dish_id: str,
    servings: Optional[int] = None
) -> Optional[Dict[str, Any]]:
    """Lấy chi tiết món ăn"""
    
    dish = db.query(Dish).filter(Dish.dish_id == dish_id).first()
    
    if not dish:
        return None
    
    standard_servings = dish.servings or 1
    requested_servings = servings if servings and servings > 0 else standard_servings
    factor = requested_servings / standard_servings
    
    calories_base = dish.calories
    calories_per_serving = calories_base / standard_servings if calories_base and standard_servings else None
    calories_total = calories_per_serving * requested_servings if calories_per_serving else calories_base
    
    recipes = db.query(Recipe).join(Ingredient).filter(
        Recipe.dish_id == dish_id
    ).all()
    
    classifications = db.query(DishClassification).join(DishGroup).filter(
        DishClassification.dish_id == dish_id
    ).all()
    
    categories = [
        {
            "ma_danh_muc_mon_an": c.group_id,
            "ten_danh_muc_mon_an": c.group.group_name if c.group else None
        }
        for c in classifications
    ]
    
    ingredients_list = []
    for r in recipes:
        quantity = r.quantity_cook
        if quantity and factor != 1:
            try:
                import re
                match = re.match(r'^(\d+(?:\.\d+)?)', quantity)
                if match:
                    value = float(match.group(1))
                    scaled = round(value * factor)
                    unit_match = re.search(r'([a-zA-ZÀ-ỹ]+)$', quantity)
                    unit = unit_match.group(1) if unit_match else ""
                    quantity = f"{scaled}{unit}" if unit else str(scaled)
            except:
                pass
        
        ingredients_list.append({
            "ma_nguyen_lieu": r.ingredient_id,
            "ten_nguyen_lieu": r.ingredient_name or (r.ingredient.ingredient_name if r.ingredient else None),
            "don_vi_goc": r.ingredient.category.category_name if r.ingredient and r.ingredient.category else None,
            "dinh_luong": quantity,
            "hinh_anh": None,
            "gia_goc": None,
            "gia_cuoi": None,
            "so_luong_ban": None,
            "so_gian_hang": 0,
            "gian_hang": []
        })
    
    return {
        "detail": {
            "ma_mon_an": dish.dish_id,
            "ten_mon_an": dish.dish_name,
            "hinh_anh": dish.dish_image,
            "khoang_thoi_gian": dish.cooking_time,
            "do_kho": dish.level,
            "khau_phan_tieu_chuan": standard_servings,
            "khau_phan_hien_tai": requested_servings,
            "calories_goc": calories_base,
            "calories_moi_khau_phan": calories_per_serving,
            "calories_tong_theo_khau_phan": calories_total,
            "calories": calories_base,
            "cach_thuc_hien": dish.steps,
            "so_che": dish.prep,
            "cach_dung": dish.serve,
            "so_danh_muc": len(categories),
            "so_nguyen_lieu": len(ingredients_list),
            "danh_muc": categories,
            "nguyen_lieu": ingredients_list
        }
    }
VALID_CANCEL_REASONS = [
    "Hàng hóa đổ bể",
    "Giao hàng trễ",
    "Sản phẩm không giống mô tả",
    "Chất lượng sản phẩm kém",
    "Thiếu sản phẩm",
    "Không còn nhu cầu mua"
]

def refund_order_details(db: Session, buyer_id: str, order_id: str, items: list):
    from app.models.models import Order, OrderDetail

    # =========================
    # 1. CHECK ORDER
    # =========================
    order = db.query(Order).filter(
        Order.order_id == order_id,
        Order.buyer_id == buyer_id
    ).first()

    if not order:
        raise Exception("Không tìm thấy đơn hàng")

    updated_items = []

    # =========================
    # 2. LOOP ITEMS
    # =========================
    for item in items:
        ingredient_id = item.get("ingredient_id")
        stall_id = item.get("stall_id")
        reason = item.get("reason")

        if not ingredient_id or not stall_id or not reason:
            raise Exception("Thiếu ingredient_id, stall_id hoặc reason")

        # ❗ validate reason
        if reason not in VALID_CANCEL_REASONS:
            raise Exception(f"Lý do không hợp lệ: {reason}")

        # 🔍 tìm order_detail
        detail = db.query(OrderDetail).filter(
            OrderDetail.order_id == order_id,
            OrderDetail.ingredient_id == ingredient_id,
            OrderDetail.stall_id == stall_id
        ).first()

        if not detail:
            raise Exception(f"Không tìm thấy sản phẩm {ingredient_id} ở stall {stall_id}")

        # ❗ không cho hoàn lại lần 2
        if detail.detail_status == "hoan_hang":
            raise Exception(f"Sản phẩm {ingredient_id} đã hoàn trước đó")

        # ❗ rule cho hoàn
        if detail.detail_status not in ["da_duyet", "tu_choi"]:
            raise Exception(f"Sản phẩm {ingredient_id} chưa đủ điều kiện hoàn")

        # =========================
        # 3. UPDATE DETAIL
        # =========================
        detail.detail_status = "hoan_hang"
        detail.cancel_reason = reason
        db.flush()

        updated_items.append({
            "ingredient_id": ingredient_id,
            "stall_id": stall_id,
            "reason": reason
        })

    db.commit()

    # =========================
    # 4. RESPONSE
    # =========================
    return {
        "success": True,
        "order_id": order_id,
        "so_san_pham_hoan": len(updated_items),
        "items": updated_items
    }