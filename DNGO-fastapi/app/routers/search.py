from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.database import get_db
from app.middlewares.auth import allow, AuthUser
from app.repositories import search as search_repo

router = APIRouter(prefix="/api/search", tags=["search"])


@router.get("/")
def search(
    q: str = Query(..., min_length=1),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("nguoi_mua", "admin"))
):
    q = q.strip()
    if not q:
        raise HTTPException(400, "Vui lòng nhập từ khóa tìm kiếm")

    result = search_repo.search_all(db=db, query=q)
    return {"success": True, **result}