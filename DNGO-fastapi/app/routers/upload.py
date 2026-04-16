from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from typing import List
from app.utils.storage import save_file, delete_file
from app.middlewares.auth import get_current_user, AuthUser
import os
from sqlalchemy.orm import Session
from app.database import get_db

router = APIRouter(prefix="/api/upload", tags=["Upload"])

ALLOWED_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"}
MAX_SIZE = 5 * 1024 * 1024  # 5MB

def validate_file(file: UploadFile):
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(400, "Chỉ chấp nhận file ảnh: jpeg, jpg, png, gif, webp")

@router.post("/single")
async def upload_single(
    file: UploadFile = File(...),
    folder: str = "uploads",
    current_user: AuthUser = Depends(get_current_user)
):
    validate_file(file)
    content = await file.read()
    if len(content) > MAX_SIZE:
        raise HTTPException(400, "File quá lớn. Kích thước tối đa là 5MB")
    
    url = save_file(content, file.filename, folder)
    return {
        "success": True,
        "message": "Upload ảnh thành công",
        "data": {
            "url": url,
            "originalName": file.filename,
            "size": len(content),
            "mimetype": file.content_type
        }
    }

@router.post("/multiple")
async def upload_multiple(
    files: List[UploadFile] = File(...),
    folder: str = "uploads",
    current_user: AuthUser = Depends(get_current_user)
):
    if not files:
        raise HTTPException(400, "Không có file nào được upload")
    if len(files) > 10:
        raise HTTPException(400, "Tối đa 10 file mỗi lần upload")
    
    results = []
    for file in files:
        validate_file(file)
        content = await file.read()
        if len(content) > MAX_SIZE:
            raise HTTPException(400, f"File {file.filename} quá lớn. Tối đa 5MB")
        url = save_file(content, file.filename, folder)
        results.append({
            "url": url,
            "originalName": file.filename,
            "size": len(content),
            "mimetype": file.content_type
        })
    
    return {
        "success": True,
        "message": f"Upload {len(results)} ảnh thành công",
        "data": results
    }
    
@router.post("/product-image/{ingredient_id}")
async def upload_product_image(
    ingredient_id: str,
    file: UploadFile = File(...),
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from app.database import get_db
    from app.repositories import seller as seller_repo
    
    validate_file(file)
    content = await file.read()
    if len(content) > MAX_SIZE:
        raise HTTPException(400, "File quá lớn. Kích thước tối đa là 5MB")
    
    url = save_file(content, file.filename, "products")
    
    # Tự động update DB
    seller_repo.update_product(
        db=db,
        user_id=current_user.user_id,
        ingredient_id=ingredient_id,
        good_image=url
    )
    
    return {
        "success": True,
        "message": "Upload và cập nhật ảnh thành công",
        "data": {
            "url": url,
            "ingredient_id": ingredient_id
        }
    }
    
@router.post("/stall-image/{stall_id}")
async def upload_stall_image(
    stall_id: str,
    file: UploadFile = File(...),
    current_user: AuthUser = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    from app.models.models import Stall
    
    validate_file(file)
    content = await file.read()
    if len(content) > MAX_SIZE:
        raise HTTPException(400, "File quá lớn. Kích thước tối đa là 5MB")
    
    # Lưu file với tên là stall_id
    ext = file.filename.rsplit(".", 1)[-1]
    file_name = f"{stall_id}.{ext}"
    url = save_file(content, file_name, "stalls")
    
    # Update DB
    stall = db.query(Stall).filter(Stall.stall_id == stall_id).first()
    if not stall:
        raise HTTPException(404, "Không tìm thấy gian hàng")
    
    stall.stall_image = url
    db.commit()
    
    return {
        "success": True,
        "message": "Upload ảnh gian hàng thành công",
        "data": {
            "url": url,
            "stall_id": stall_id
        }
    }