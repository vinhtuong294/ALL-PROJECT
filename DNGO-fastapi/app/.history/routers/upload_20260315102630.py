from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from typing import List
from app.utils.storage import save_file, delete_file
from app.middlewares.auth import get_current_user, AuthUser
import os

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