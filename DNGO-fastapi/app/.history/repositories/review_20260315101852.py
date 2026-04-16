from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional, Dict, Any
from app.models.models import Review, Order, OrderDetail, Stall, Buyer, User
import secrets


def gen_review_id():
    return "DG" + secrets.token_urlsafe(6)[:8].upper()


def get_buyer(db: Session, user_id: str):
    return db.query(Buyer).filter(Buyer.user_id == user_id).first()


def can_review_item(db: Session, buyer_id: str, order_id: str, ingredient_id: str, stall_id: str) -> bool:
    order = db.query(Order).filter(
        Order.order_id == order_id,
        Order.buyer_id == buyer_id,
        Order.order_status.in_(["da_giao", "hoan_thanh"])
    ).first()

    if not order:
        return False

    detail = db.query(OrderDetail).filter(
        OrderDetail.order_id == order_id,
        OrderDetail.ingredient_id == ingredient_id,
        OrderDetail.stall_id == stall_id
    ).first()

    return detail is not None


def upsert_review(db: Session, buyer_id: str, order_id: str, ingredient_id: str,
                  stall_id: str, rating: int, binh_luan: Optional[str] = None) -> Dict[str, Any]:
    from datetime import datetime

    if not (1 <= rating <= 5):
        raise ValueError("INVALID_RATING")
    if binh_luan and len(binh_luan) > 2000:
        raise ValueError("COMMENT_TOO_LONG")

    if not can_review_item(db, buyer_id, order_id, ingredient_id, stall_id):
        raise PermissionError("Chỉ có thể đánh giá nguyên liệu trong đơn hàng đã giao của bạn")

    existing = db.query(Review).filter(
        Review.buyer_id == buyer_id,
        Review.order_id == order_id,
        Review.stall_id == stall_id,
    ).first()

    if existing:
        existing.rating = rating
        existing.comment = binh_luan
        existing.review_date = datetime.utcnow()
        review = existing
    else:
        review = Review(
            review_id=gen_review_id(),
            buyer_id=buyer_id,
            stall_id=stall_id,
            order_id=order_id,
            rating=rating,
            comment=binh_luan,
            review_date=datetime.utcnow()
        )
        db.add(review)

    db.flush()

    # Cập nhật avr_rating cho stall
    avg_result = db.query(func.avg(Review.rating)).filter(
        Review.stall_id == stall_id,
        Review.rating.isnot(None)
    ).scalar()
    danh_gia_tb = round(float(avg_result), 2) if avg_result else 0

    stall = db.query(Stall).filter(Stall.stall_id == stall_id).first()
    if stall:
        stall.avr_rating = danh_gia_tb

    db.commit()

    return {
        "review": {
            "review_id": review.review_id,
            "buyer_id": review.buyer_id,
            "stall_id": review.stall_id,
            "order_id": review.order_id,
            "rating": review.rating,
            "comment": review.comment,
            "review_date": review.review_date,
        },
        "danh_gia_tb": danh_gia_tb
    }


def list_reviews_by_store(db: Session, stall_id: str, ingredient_id: Optional[str] = None,
                           skip: int = 0, take: int = 10, sort: str = "desc") -> Dict[str, Any]:
    query = db.query(Review).filter(Review.stall_id == stall_id)

    if ingredient_id:
        # filter theo ingredient nếu có (Review không có ingredient_id trực tiếp,
        # join qua OrderDetail)
        matched_order_ids = db.query(OrderDetail.order_id).filter(
            OrderDetail.stall_id == stall_id,
            OrderDetail.ingredient_id == ingredient_id
        ).subquery()
        query = query.filter(Review.order_id.in_(matched_order_ids))

    total = query.count()

    if sort == "asc":
        query = query.order_by(Review.review_date.asc())
    else:
        query = query.order_by(Review.review_date.desc())

    take = min(take, 50)
    items = query.offset(skip).limit(take).all()

    stall = db.query(Stall).filter(Stall.stall_id == stall_id).first()
    avg = stall.avr_rating if stall and stall.avr_rating else 0

    mapped = []
    for it in items:
        ten_hien_thi = "Người dùng"
        if it.buyer and it.buyer.user:
            ten_hien_thi = it.buyer.user.user_name

        mapped.append({
            "review_id": it.review_id,
            "order_id": it.order_id,
            "rating": it.rating,
            "comment": it.comment,
            "review_date": it.review_date,
            "nguoi_danh_gia": {
                "buyer_id": it.buyer_id,
                "ten_hien_thi": ten_hien_thi,
            }
        })

    return {"items": mapped, "total": total, "avg": avg}


def get_my_review(db: Session, buyer_id: str, order_id: Optional[str] = None,
                  ingredient_id: Optional[str] = None, stall_id: Optional[str] = None):
    if order_id:
        reviews = db.query(Review).filter(
            Review.buyer_id == buyer_id,
            Review.order_id == order_id
        ).all()
        return [{"review_id": r.review_id, "order_id": r.order_id,
                 "stall_id": r.stall_id, "rating": r.rating,
                 "comment": r.comment, "review_date": r.review_date} for r in reviews]

    review = db.query(Review).filter(
        Review.buyer_id == buyer_id,
        Review.stall_id == stall_id
    ).first()

    if not review:
        return None

    return {
        "review_id": review.review_id,
        "order_id": review.order_id,
        "stall_id": review.stall_id,
        "rating": review.rating,
        "comment": review.comment,
        "review_date": review.review_date
    }


def delete_my_review(db: Session, buyer_id: str, review_id: str) -> Dict[str, Any]:
    review = db.query(Review).filter(Review.review_id == review_id).first()

    if not review:
        raise LookupError("REVIEW_NOT_FOUND")
    if review.buyer_id != buyer_id:
        raise PermissionError("FORBIDDEN_REVIEW")

    stall_id = review.stall_id
    db.delete(review)
    db.flush()

    avg_result = db.query(func.avg(Review.rating)).filter(
        Review.stall_id == stall_id,
        Review.rating.isnot(None)
    ).scalar()
    danh_gia_tb = round(float(avg_result), 2) if avg_result else 0

    stall = db.query(Stall).filter(Stall.stall_id == stall_id).first()
    if stall:
        stall.avr_rating = danh_gia_tb

    db.commit()

    return {"danh_gia_tb": danh_gia_tb}