from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from datetime import datetime
from pydantic import BaseModel
from app.database import get_db
from app.middlewares.auth import allow, AuthUser
from app.repositories import seller as seller_repo

router = APIRouter(prefix="/api/seller", tags=["seller"])


class AddProductBody(BaseModel):
    ma_nguyen_lieu: str
    good_image: str
    inventory: float
    good_price: int
    unit: str
    discount: Optional[float] = None
    sale_start_date: Optional[datetime] = None
    sale_end_date: Optional[datetime] = None


class UpdateProductBody(BaseModel):
    good_image: Optional[str] = None
    inventory: Optional[float] = None
    good_price: Optional[int] = None
    unit: Optional[str] = None
    discount: Optional[float] = None
    sale_start_date: Optional[datetime] = None
    sale_end_date: Optional[datetime] = None


@router.get("/products")
def list_products(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    search: Optional[str] = None,
    sort: str = "update_date",
    order: str = "desc",
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_ban"))
):
    try:
        return seller_repo.list_products(
            db=db, user_id=current_user.user_id,
            page=page, limit=limit,
            search=search, sort=sort, order=order
        )
    except Exception as e:
        raise HTTPException(400, str(e))


@router.post("/products", status_code=201)
def add_product(
    body: AddProductBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_ban"))
):
    try:
        return seller_repo.add_product(
            db=db, user_id=current_user.user_id,
            ingredient_id=body.ma_nguyen_lieu,
            good_image=body.good_image,
            inventory=body.inventory,
            good_price=body.good_price,
            unit=body.unit,
            discount=body.discount,
            sale_start_date=body.sale_start_date,
            sale_end_date=body.sale_end_date
        )
    except Exception as e:
        raise HTTPException(400, str(e))


@router.patch("/products/{ma_nguyen_lieu}")
def update_product(
    ma_nguyen_lieu: str,
    body: UpdateProductBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_ban"))
):
    try:
        return seller_repo.update_product(
            db=db, user_id=current_user.user_id,
            ingredient_id=ma_nguyen_lieu,
            good_image=body.good_image,
            inventory=body.inventory,
            good_price=body.good_price,
            unit=body.unit,
            discount=body.discount,
            sale_start_date=body.sale_start_date,
            sale_end_date=body.sale_end_date
        )
    except Exception as e:
        raise HTTPException(400, str(e))


@router.delete("/products/{ma_nguyen_lieu}")
def delete_product(
    ma_nguyen_lieu: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_ban"))
):
    try:
        seller_repo.delete_product(
            db=db, user_id=current_user.user_id,
            ingredient_id=ma_nguyen_lieu
        )
        return {"success": True, "message": "Đã xóa sản phẩm khỏi gian hàng"}
    except Exception as e:
        raise HTTPException(400, str(e))
    
@router.get("/revenue")
def get_revenue(
    period: Optional[str] = Query(None, description="ngay / tuan / thang"),
    from_date: Optional[str] = Query(None, description="Từ ngày YYYY-MM-DD"),
    to_date: Optional[str] = Query(None, description="Đến ngày YYYY-MM-DD"),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_ban"))  # sửa dòng này
):
    from datetime import date, timedelta

    today = date.today()

    if period == "ngay":
        from_date = str(today)
        to_date = str(today)
    elif period == "tuan":
        from_date = str(today - timedelta(days=today.weekday()))
        to_date = str(today)
    elif period == "thang":
        from_date = str(today.replace(day=1))
        to_date = str(today)

    if not from_date or not to_date:
        raise HTTPException(status_code=400, detail="Cần truyền period hoặc from_date và to_date")

    try:
        result = seller_repo.get_revenue(db, current_user.user_id, from_date, to_date)
        return result
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    
class UpdateStatusBody(BaseModel):
    status: str  # mo_cua / dong_cua

@router.patch("/stall/status")
def update_stall_status(
    body: UpdateStatusBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_ban"))
):
    try:
        return seller_repo.update_my_stall_status(db, current_user.user_id, body.status)
    except Exception as e:
        raise HTTPException(400, str(e))
    
@router.get("/orders")
def get_orders(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_ban"))
):
    try:
        return seller_repo.get_orders(db, current_user.user_id, page, limit)
    except Exception as e:
        raise HTTPException(400, str(e))
    
    
class ConfirmOrderBody(BaseModel):
    action: str  # da_duyet / tu_choi

@router.patch("/orders/{order_id}/items/{ingredient_id}/confirm")
def confirm_order_detail(
    order_id: str,
    ingredient_id: str,
    body: ConfirmOrderBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_ban"))
):
    try:
        return seller_repo.confirm_order_detail(db, current_user.user_id, order_id, ingredient_id, body.action)
    except Exception as e:
        raise HTTPException(400, str(e))
    
@router.get("/notifications")
def get_notifications(
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_ban"))
):
    from app.models.models import Notification
    offset = (page - 1) * limit
    
    notifs = db.query(Notification).filter(
        Notification.user_id == current_user.user_id
    ).order_by(Notification.created_at.desc()).offset(offset).limit(limit).all()
    
    total = db.query(Notification).filter(
        Notification.user_id == current_user.user_id
    ).count()
    
    unread = db.query(Notification).filter(
        Notification.user_id == current_user.user_id,
        Notification.is_read == False
    ).count()
    
    import json
    return {
        "success": True,
        "unread": unread,
        "data": [
            {
                "id": n.id,
                "title": n.title,
                "body": n.body,
                "data": json.loads(n.data) if n.data else {},
                "is_read": n.is_read,
                "created_at": str(n.created_at)
            }
            for n in notifs
        ],
        "meta": {
            "page": page,
            "limit": limit,
            "total": total
        }
    }

@router.patch("/notifications/{notification_id}/read")
def mark_notification_read(
    notification_id: int,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_ban"))
):
    from app.models.models import Notification
    notif = db.query(Notification).filter(
        Notification.id == notification_id,
        Notification.user_id == current_user.user_id
    ).first()
    if not notif:
        raise HTTPException(404, "Không tìm thấy thông báo")
    notif.is_read = True
    db.commit()
    return {"success": True}