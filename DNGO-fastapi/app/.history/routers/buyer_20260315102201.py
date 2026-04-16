from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.middlewares.auth import allow, AuthUser
from app.repositories import buyer as buyer_repo

router = APIRouter(
    prefix="/api/buyer",
    tags=["Buyer"],
    responses={404: {"description": "Not found"}}
)


# ==================== KHU VỰC (DISTRICT) ====================

@router.get("/khu-vuc")
def list_districts(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = None,
    sort: str = "district_name",
    order: str = "asc",
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua", "admin", "nguoi_ban"))
):
    """Lấy danh sách khu vực"""
    result = buyer_repo.list_districts(
        db=db, page=page, limit=limit, 
        search=search, sort=sort, order=order
    )
    return result


# ==================== CHỢ (MARKET) ====================

@router.get("/cho")
def list_markets(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = None,
    ma_khu_vuc: Optional[str] = None,
    sort: str = "market_name",
    order: str = "asc",
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua", "admin", "nguoi_ban"))
):
    """Lấy danh sách chợ"""
    result = buyer_repo.list_markets(
        db=db, page=page, limit=limit,
        search=search, district_id=ma_khu_vuc,
        sort=sort, order=order
    )
    return result


# ==================== GIAN HÀNG (STALL) ====================

@router.get("/gian-hang")
def list_stalls(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = None,
    ma_cho: Optional[str] = None,
    sort: str = "stall_name",
    order: str = "asc",
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua", "admin", "nguoi_ban"))
):
    """Lấy danh sách gian hàng"""
    result = buyer_repo.list_stalls(
        db=db, page=page, limit=limit,
        search=search, market_id=ma_cho,
        sort=sort, order=order
    )
    return result


@router.get("/gian-hang/{ma_gian_hang}")
def get_stall_detail(
    ma_gian_hang: str,
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = None,
    sort: str = "update_date",
    order: str = "desc",
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua", "admin", "nguoi_ban"))
):
    """Lấy chi tiết gian hàng"""
    result = buyer_repo.get_stall_detail(
        db=db, stall_id=ma_gian_hang,
        page=page, limit=limit,
        search=search, sort=sort, order=order
    )
    
    if not result:
        raise HTTPException(status_code=404, detail="Gian hàng không tồn tại")
    
    return {"success": True, **result}


# ==================== NGUYÊN LIỆU (INGREDIENT) ====================

@router.get("/nguyen-lieu")
def list_ingredients(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = None,
    ma_nhom_nguyen_lieu: Optional[str] = None,
    ma_cho: Optional[str] = None,
    ma_gian_hang: Optional[str] = None,
    hinh_anh: Optional[bool] = None,
    sort: str = "ingredient_name",
    order: str = "asc",
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua", "admin", "nguoi_ban"))
):
    """Lấy danh sách nguyên liệu"""
    # TODO: Implement listNguyenLieuRepo equivalent
    return buyer_repo.list_ingredients(
    db=db,
    page=page, limit=limit,
    search=search,
    category_id=ma_nhom_nguyen_lieu,
    market_id=ma_cho,
    stall_id=ma_gian_hang,
    has_image=hinh_anh,
    sort=sort,
    order=order
)


@router.get("/nguyen-lieu/{ma_nguyen_lieu}")
def get_ingredient_detail(
    ma_nguyen_lieu: str,
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    ma_cho: Optional[str] = None,
    sort: str = "update_date",
    order: str = "desc",
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua", "admin", "nguoi_ban"))
):
    """Lấy chi tiết nguyên liệu"""
    result = buyer_repo.get_ingredient_detail(
        db=db,
        ingredient_id=ma_nguyen_lieu,
        page=page, limit=limit,
        market_id=ma_cho,
        sort=sort, order=order
    )
    if not result:
        raise HTTPException(status_code=404, detail="Nguyên liệu không tồn tại")
    return {"success": True, **result}

# ==================== DANH MỤC NGUYÊN LIỆU (CATEGORY) ====================

@router.get("/danh-muc-nguyen-lieu")
def list_categories(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = None,
    sort: str = "category_name",
    order: str = "asc",
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua", "admin", "nguoi_ban"))
):
    """Lấy danh sách danh mục nguyên liệu"""
    result = buyer_repo.list_categories(
        db=db, page=page, limit=limit,
        search=search, sort=sort, order=order
    )
    return result


# ==================== DANH MỤC MÓN ĂN (DISH CATEGORY) ====================

@router.get("/danh-muc-mon-an")
def list_dish_categories(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = None,
    sort: str = "group_name",
    order: str = "asc",
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua", "admin", "nguoi_ban"))
):
    """Lấy danh sách danh mục món ăn"""
    result = buyer_repo.list_dish_categories(
        db=db, page=page, limit=limit,
        search=search, sort=sort, order=order
    )
    return result


# ==================== MÓN ĂN (DISH) ====================

@router.get("/mon-an")
def list_dishes(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = None,
    ma_danh_muc_mon_an: Optional[str] = None,
    hinh_anh: Optional[bool] = None,
    sort: str = "dish_name",
    order: str = "asc",
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua", "admin", "nguoi_ban"))
):
    """Lấy danh sách món ăn"""
    result = buyer_repo.list_dishes(
        db=db, page=page, limit=limit,
        search=search, category_id=ma_danh_muc_mon_an,
        has_image=hinh_anh or False,
        sort=sort, order=order
    )
    return result


@router.get("/mon-an/{ma_mon_an}")
def get_dish_detail(
    ma_mon_an: str,
    khau_phan: Optional[int] = Query(None, ge=1),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua", "admin", "nguoi_ban"))
):
    """Lấy chi tiết món ăn"""
    result = buyer_repo.get_dish_detail(
        db=db, dish_id=ma_mon_an, servings=khau_phan
    )
    
    if not result:
        raise HTTPException(status_code=404, detail="Món ăn không tồn tại")
    
    return {"success": True, **result}