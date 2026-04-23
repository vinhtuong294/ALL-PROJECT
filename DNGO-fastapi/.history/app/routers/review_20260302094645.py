from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from pydantic import BaseModel, Field
from app.database import get_db
from app.middlewares.auth import allow, AuthUser
from app.repositories import review as review_repo

router = APIRouter(prefix="/api", tags=["reviews"])


class ReviewBody(BaseModel):
    ma_don_hang: str
    ma_nguyen_lieu: str
    ma_gian_hang: str
    rating: int = Field(..., ge=1, le=5)
    binh_luan: Optional[str] = None


@router.post("/reviews")
def create_or_update_review(
    body: ReviewBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua"))
):
    buyer = review_repo.get_buyer(db, current_user.user_id)
    if not buyer:
        raise HTTPException(403, "BUYER_PROFILE_NOT_FOUND")

    try:
        result = review_repo.upsert_review(
            db=db,
            buyer_id=buyer.buyer_id,
            order_id=body.ma_don_hang,
            ingredient_id=body.ma_nguyen_lieu,
            stall_id=body.ma_gian_hang,
            rating=body.rating,
            binh_luan=body.binh_luan.strip() if body.binh_luan else None
        )
        return {"success": True, **result}
    except PermissionError as e:
        raise HTTPException(403, str(e))
    except ValueError as e:
        raise HTTPException(400, str(e))


@router.get("/stores/{ma_gian_hang}/reviews")
def list_reviews_by_store(
    ma_gian_hang: str,
    ma_nguyen_lieu: Optional[str] = None,
    skip: int = Query(0, ge=0),
    take: int = Query(10, ge=1, le=50),
    sort: str = Query("desc", pattern="^(asc|desc)$"),
    db: Session = Depends(get_db)
):
    result = review_repo.list_reviews_by_store(
        db=db,
        stall_id=ma_gian_hang,
        ingredient_id=ma_nguyen_lieu,
        skip=skip, take=take, sort=sort
    )
    return {"success": True, **result}


@router.get("/my/reviews")
def get_my_reviews(
    ma_don_hang: Optional[str] = None,
    ma_nguyen_lieu: Optional[str] = None,
    ma_gian_hang: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua"))
):
    buyer = review_repo.get_buyer(db, current_user.user_id)
    if not buyer:
        raise HTTPException(403, "BUYER_PROFILE_NOT_FOUND")

    if not ma_don_hang and not (ma_nguyen_lieu and ma_gian_hang):
        raise HTTPException(400, "ma_don_hang or (ma_nguyen_lieu and ma_gian_hang) is required")

    result = review_repo.get_my_review(
        db=db,
        buyer_id=buyer.buyer_id,
        order_id=ma_don_hang,
        ingredient_id=ma_nguyen_lieu,
        stall_id=ma_gian_hang
    )

    if ma_don_hang:
        return {"success": True, "reviews": result}
    return {"success": True, "review": result}


@router.delete("/reviews/{ma_danh_gia}")
def delete_review(
    ma_danh_gia: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua"))
):
    buyer = review_repo.get_buyer(db, current_user.user_id)
    if not buyer:
        raise HTTPException(403, "BUYER_PROFILE_NOT_FOUND")

    try:
        result = review_repo.delete_my_review(
            db=db,
            buyer_id=buyer.buyer_id,
            review_id=ma_danh_gia
        )
        return {"success": True, **result}
    except LookupError:
        raise HTTPException(404, "REVIEW_NOT_FOUND")
    except PermissionError:
        raise HTTPException(403, "FORBIDDEN_REVIEW")