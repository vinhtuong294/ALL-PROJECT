from sqlalchemy.orm import Session
from typing import Optional
from app.models.models import User, Stall, MarketManagement

STALL_LOCATION_OPTIONS = {
    "TH": "Thịt",
    "RC": "Rau củ",
    "HS": "Hải sản",
    "GV": "Gia vị/Tạp hóa",
    "KH": "Khác"
}


def get_manage_id_by_user(db: Session, user_id: str) -> Optional[str]:
    manage = db.query(MarketManagement).filter(MarketManagement.user_id == user_id).first()
    return manage.manage_id if manage else None


def get_market_by_manage_id(db: Session, manage_id: str) -> Optional[str]:
    manage = db.query(MarketManagement).filter(MarketManagement.manage_id == manage_id).first()
    return manage.market_id if manage else None


def list_tieu_thuong(db: Session, manage_id: str, page: int = 1, limit: int = 10):
    offset = (page - 1) * limit

    query = db.query(User, Stall).outerjoin(
        Stall, Stall.user_id == User.user_id
    ).filter(
        User.role == "nguoi_ban",
        Stall.manage_id == manage_id
    )

    total = query.count()
    rows = query.offset(offset).limit(limit).all()

    data = []
    for user, stall in rows:
        if user.approval_status == 0 or stall is None:
            tinh_trang = "chua_co_gian_hang"
        else:
            tinh_trang = user.active_status

        data.append({
            "ma_nguoi_dung": user.user_id,
            "ten_nguoi_dung": user.user_name,
            "ma_gian_hang": stall.stall_id if stall else None,
            "ten_gian_hang": stall.stall_name if stall else None,
            "vi_tri_gian_hang": stall.stall_location if stall else None,
            "tinh_trang": tinh_trang
        })

    return {
        "data": data,
        "meta": {
            "page": page,
            "limit": limit,
            "total": total,
            "total_pages": (total + limit - 1) // limit
        }
    }


def get_tieu_thuong_detail(db: Session, user_id: str, manage_id: str):
    user = db.query(User).filter(
        User.user_id == user_id,
        User.role == "nguoi_ban"
    ).first()

    if not user:
        return None

    stall = db.query(Stall).filter(
        Stall.user_id == user_id,
        Stall.manage_id == manage_id
    ).first()

    if user.approval_status == 0 or stall is None:
        tinh_trang = "chua_co_gian_hang"
    else:
        tinh_trang = user.active_status

    return {
        "ma_nguoi_dung": user.user_id,
        "ten_dang_nhap": user.login_name,
        "ten_nguoi_dung": user.user_name,
        "gioi_tinh": user.gender,
        "sdt": user.phone,
        "dia_chi": user.address,
        "so_tai_khoan": user.bank_account,
        "ngan_hang": user.bank_name,
        "tinh_trang": tinh_trang,
        "gian_hang": {
            "ma_gian_hang": stall.stall_id,
            "ten_gian_hang": stall.stall_name,
            "ma_cho": stall.market_id,
            "vi_tri": stall.stall_location,
            "hinh_anh": stall.stall_image,
            "danh_gia_tb": stall.avr_rating,
            "ngay_dang_ky": str(stall.signup_date),
            "vi_tri_gian_hang": {
                "cot": stall.grid_col,
                "hang": stall.grid_row,
                "tang": stall.grid_floor
            }
        } if stall else None
    }


def register_stall(
    db: Session,
    manage_id: str,
    user_id: str,
    stall_name: str,
    stall_location: str,
    grid_col: int,
    grid_row: int,
    grid_floor: Optional[int] = None
):
    # Kiểm tra user tồn tại và có role nguoi_ban
    user = db.query(User).filter(
        User.user_id == user_id,
        User.role == "nguoi_ban"
    ).first()
    if not user:
        raise ValueError("Không tìm thấy tiểu thương")

    # Lấy market_id từ manage_id
    market_id = get_market_by_manage_id(db, manage_id)
    if not market_id:
        raise ValueError("Không tìm thấy thông tin chợ")

    # Kiểm tra stall_location hợp lệ
    if stall_location not in STALL_LOCATION_OPTIONS:
        raise ValueError(f"Loại hàng hóa không hợp lệ. Chọn: {list(STALL_LOCATION_OPTIONS.keys())}")

    # Tìm stall của user
    stall = db.query(Stall).filter(Stall.user_id == user_id).first()
    if not stall:
        raise ValueError("Tiểu thương chưa có gian hàng trong hệ thống")

    # Cập nhật thông tin gian hàng
    stall.stall_name = stall_name
    stall.market_id = market_id
    stall.manage_id = manage_id
    stall.stall_location = stall_location
    stall.grid_col = grid_col
    stall.grid_row = grid_row
    stall.grid_floor = grid_floor

    # Cập nhật approval_status của user thành 1
    user.approval_status = 1

    db.commit()
    db.refresh(stall)

    return {
        "ma_gian_hang": stall.stall_id,
        "ten_gian_hang": stall.stall_name,
        "ma_cho": stall.market_id,
        "vi_tri": stall.stall_location,
        "so_gian_hang": f"{stall.grid_col}-{stall.grid_row}",
        "tang": stall.grid_floor,
        "ma_quan_ly": stall.manage_id
    }