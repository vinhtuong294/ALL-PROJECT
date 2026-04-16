from sqlalchemy.orm import Session
from typing import Optional
from app.models.models import User, Stall, MarketManagement, StallFee
from app.schemas.merchant import MerchantCreate

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


def get_manage_id_fallback(db: Session, user_id: str) -> Optional[str]:
    """Fallback: find manage_id by looking at stalls where user manages,
    or return the first market_management record if admin-level user."""
    # Try through stalls
    stall = db.query(Stall).filter(Stall.manage_id != None).first()
    if stall:
        return stall.manage_id
    # Try first record in market_management
    manage = db.query(MarketManagement).first()
    return manage.manage_id if manage else None


def get_market_by_manage_id(db: Session, manage_id: str) -> Optional[str]:
    manage = db.query(MarketManagement).filter(MarketManagement.manage_id == manage_id).first()
    return manage.market_id if manage else None


def list_tieu_thuong(db: Session, manage_id: str, page: int = 1, limit: int = 10, search: Optional[str] = None, status: Optional[str] = None):
    from datetime import datetime
    current_month = datetime.now().date().replace(day=1)
    offset = (page - 1) * limit

    query = db.query(User, Stall, StallFee).outerjoin(
        Stall, Stall.user_id == User.user_id
    ).outerjoin(
        StallFee, (StallFee.stall_id == Stall.stall_id) & (StallFee.month == current_month)
    ).filter(
        User.role == "nguoi_ban",
        Stall.manage_id == manage_id
    )

    if search:
        search_filter = f"%{search}%"
        query = query.filter(
            (User.user_name.ilike(search_filter)) |
            (Stall.stall_id.ilike(search_filter)) |
            (Stall.stall_name.ilike(search_filter))
        )

    if status and status != "tat_ca":
        # Status from UI: hoat_dong, tam_nghi
        # Map to DB active_status: mo_cua, dong_cua
        db_status = "mo_cua" if status == "hoat_dong" else "dong_cua"
        query = query.filter(User.active_status == db_status)

    total = query.count()
    rows = query.offset(offset).limit(limit).all()

    data = []
    for user, stall, fee in rows:
        if user.approval_status == 0 or stall is None:
            tinh_trang = "chua_co_gian_hang"
        else:
            tinh_trang = "hoat_dong" if user.active_status == "mo_cua" else "tam_nghi"

        data.append({
            "ma_nguoi_dung": user.user_id,
            "ten_nguoi_dung": user.user_name,
            "ma_gian_hang": stall.stall_id if stall else None,
            "ten_gian_hang": stall.stall_name if stall else None,
            "vi_tri_gian_hang": stall.stall_location if stall else None,
            "tinh_trang": tinh_trang,
            "fee_status": fee.fee_status if fee else "chua_nop",
            "fee_id": fee.fee_id if fee else None
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
    from datetime import date
    import random, string

    # Kiểm tra user tồn tại và có role nguoi_ban
    user = db.query(User).filter(
        User.user_id == user_id,
        User.role == "nguoi_ban"
    ).first()
    if not user:
        raise ValueError("Không tìm thấy tiểu thương")

    # Kiểm tra user đã có gian hàng chưa
    existing_stall = db.query(Stall).filter(Stall.user_id == user_id).first()
    if existing_stall:
        raise ValueError("Tiểu thương này đã có gian hàng rồi")

    # Lấy market_id từ manage_id
    market_id = get_market_by_manage_id(db, manage_id)
    if not market_id:
        raise ValueError("Không tìm thấy thông tin chợ")

    # Kiểm tra stall_location hợp lệ
    if stall_location not in STALL_LOCATION_OPTIONS:
        raise ValueError(f"Loại hàng hóa không hợp lệ. Chọn: {list(STALL_LOCATION_OPTIONS.keys())}")

    # Tự động sinh stall_id GH + 6 ký tự
    chars = string.ascii_uppercase + string.digits
    while True:
        stall_id = "GH" + ''.join(random.choices(chars, k=6))
        exists = db.query(Stall).filter(Stall.stall_id == stall_id).first()
        if not exists:
            break

    # Tạo stall mới
    new_stall = Stall(
        stall_id=stall_id,
        stall_name=stall_name,
        market_id=market_id,
        user_id=user_id,
        manage_id=manage_id,
        stall_location=stall_location,
        stall_image=None,
        avr_rating=None,
        signup_date=date.today(),
        grid_col=grid_col,
        grid_row=grid_row,
        grid_floor=grid_floor,
        stall_fee=0
    )
    db.add(new_stall)

    # Cập nhật approval_status của user thành 1
    user.approval_status = 1

    db.commit()
    db.refresh(new_stall)

    return {
        "ma_gian_hang": new_stall.stall_id,
        "ten_gian_hang": new_stall.stall_name,
        "ma_cho": new_stall.market_id,
        "vi_tri": new_stall.stall_location,
        "so_gian_hang": f"{new_stall.grid_col}-{new_stall.grid_row}",
        "tang": new_stall.grid_floor,
        "ma_quan_ly": new_stall.manage_id
    }


def get_dashboard_stats(db: Session, manage_id: str):
    from datetime import date, datetime
    from sqlalchemy import func
    from app.models.models import Market, District, Order, StallFee, OrderDetail, User, MarketManagement

    # 1. Lấy thông tin quản lý và chợ
    manage = db.query(MarketManagement, Market, District, User).join(
        Market, Market.market_id == MarketManagement.market_id
    ).join(
        District, District.district_id == Market.district_id
    ).join(
        User, User.user_id == MarketManagement.user_id
    ).filter(
        MarketManagement.manage_id == manage_id
    ).first()

    if not manage:
        return None

    mm, market, district, user = manage

    # 2. Số lượng tiểu thương (đếm số user_id duy nhất có gian hàng)
    active_merchants = db.query(func.count(func.distinct(Stall.user_id))).filter(
        Stall.manage_id == manage_id
    ).scalar() or 0

    # 2.1 Tổng số gian hàng
    total_stalls = db.query(Stall).filter(
        Stall.manage_id == manage_id
    ).count()

    # 3. Đơn hàng hôm nay
    # Sử dụng delivery_time (timestamp) để so sánh ngày
    today = date.today()
    orders_today = db.query(func.count(func.distinct(Order.order_id))).join(
        OrderDetail, OrderDetail.order_id == Order.order_id
    ).join(
        Stall, Stall.stall_id == OrderDetail.stall_id
    ).filter(
        Stall.manage_id == manage_id,
        func.date(Order.delivery_time) == today,
        Order.order_status != 'da_huy'
    ).scalar() or 0

    # 4. Tổng thu thuế tháng này (phí gian hàng đã nộp)
    first_day_of_month = today.replace(day=1)
    monthly_tax_revenue = db.query(func.sum(StallFee.fee)).join(
        Stall, Stall.stall_id == StallFee.stall_id
    ).filter(
        Stall.manage_id == manage_id,
        StallFee.month >= first_day_of_month,
        StallFee.fee_status == "da_nop"
    ).scalar() or 0.0



    # 5. Số gian hàng chưa nộp phí tháng này
    # Lấy danh sách stall_id thuộc quản lý này
    stalls_in_market = db.query(Stall.stall_id).filter(Stall.manage_id == manage_id).all()
    stall_ids = [s[0] for s in stalls_in_market]
    
    if not stall_ids:
        pending_tax_stalls = 0
    else:
        # Tìm các gian hàng ĐÃ nộp phí trong tháng này
        paid_stall_ids = db.query(StallFee.stall_id).filter(
            StallFee.stall_id.in_(stall_ids),
            StallFee.month >= first_day_of_month,
            StallFee.fee_status == "da_nop"
        ).all()
        paid_count = len(set(s[0] for s in paid_stall_ids))
        pending_tax_stalls = len(stall_ids) - paid_count

    return {
        "manager_name": user.user_name,
        "market_name": market.market_name,
        "district_name": district.district_name,
        "active_merchants": active_merchants,
        "total_stalls": total_stalls,
        "orders_today": orders_today,
        "monthly_tax_revenue": float(monthly_tax_revenue),
        "pending_tax_stalls": pending_tax_stalls
    }


def generate_random_id(prefix: str, length: int = 6) -> str:
    import random
    import string
    return prefix + ''.join(random.choices(string.ascii_uppercase + string.digits, k=length))


def create_tieu_thuong(db: Session, manage_id: str, merchant_in: MerchantCreate):
    from app.models.models import User, Stall, StallFee, MarketManagement, Payment
    from app.utils.password import hash_password
    from datetime import datetime
    import decimal

    # 1. Lấy market_id từ manage_id
    mm = db.query(MarketManagement).filter(MarketManagement.manage_id == manage_id).first()
    if not mm:
        raise ValueError("Không tìm thấy thông tin quản lý chợ")

    # 2. Tạo User mới (Tiểu thương)
    user_id = generate_random_id("ND", length=4)
    hashed_pwd = hash_password("123456")
    login_name = f"tt_{user_id.lower()}"
    new_user = User(
        user_id=user_id,
        user_name=merchant_in.ten_nguoi_dung,
        phone=merchant_in.so_dien_thoai,
        address=merchant_in.dia_chi,
        role="nguoi_ban", # standard role for merchant
        login_name=login_name,
        password=hashed_pwd,
        gender="O", # Other/Not specified
        active_status="mo_cua",
        approval_status=1
    )
    db.add(new_user)

    # 3. Tạo/Cập nhật Gian hàng
    # Kiểm tra xem mã gian hàng đã tồn tại chưa
    stall = db.query(Stall).filter(
        Stall.stall_id == merchant_in.ma_gian_hang,
        Stall.market_id == mm.market_id
    ).first()

    if stall:
        # Nếu đã có gian hàng này, cập nhật chủ sở hữu
        stall.user_id = user_id
        stall.stall_name = f"Quầy của {merchant_in.ten_nguoi_dung}"
        stall.stall_location = merchant_in.loai_hang_hoa
        # stall.tinh_trang = "mo_cua" # Stall model doesn't have tinh_trang? Check models.py
    else:
        # Tạo mới
        stall = Stall(
            stall_id=merchant_in.ma_gian_hang,
            stall_name=f"Quầy của {merchant_in.ten_nguoi_dung}",
            user_id=user_id,
            market_id=mm.market_id,
            manage_id=manage_id,
            stall_location=merchant_in.loai_hang_hoa,
            signup_date=datetime.now().date(),
            grid_col=merchant_in.grid_col or 0,
            grid_row=merchant_in.grid_row or 0,
            grid_floor=1
        )
        db.add(stall)

    # 4. Tạo phí gian hàng (Tax) cho tháng hiện tại
    current_month_date = datetime.now().date().replace(day=1)
    
    # Do stall_fee.payment_id có constraint và NOT NULL, ta cần tạo Payment record trước
    payment_id = generate_random_id("PM", length=8) # Tổng 10 ký tự
    new_payment = Payment(
        payment_id=payment_id,
        payment_method="tien_mat",
        payment_account="ACCOUNT_SYSTEM",
        payment_time=datetime.now(),
        payment_status="chua_thanh_toan"
    )
    db.add(new_payment)
    db.flush()

    fee_id = generate_random_id("FE", length=8) # Tổng 10 ký tự
    new_fee = StallFee(
        fee_id=fee_id,
        stall_id=stall.stall_id,
        fee=decimal.Decimal(str(merchant_in.tien_thue_mac_dinh)),
        fee_status="chua_nop",
        month=current_month_date,
        payment_id=payment_id
    )
    db.add(new_fee)

    db.commit()
    db.refresh(new_user)
    
    return {
        "success": True,
        "message": f"Tạo thành công. Tài khoản: {login_name} - Mật khẩu: 123456",
        "data": {
            "user_id": new_user.user_id,
            "user_name": new_user.user_name,
            "login_name": login_name,
            "default_password": "123456",
            "stall_id": stall.stall_id,
            "stall_name": stall.stall_name
        }
    }


def list_stall_fees(
    db: Session,
    manage_id: str,
    month: str,  # format: "YYYY-MM"
    status: Optional[str] = None,  # da_nop / chua_nop / None (all)
    search: Optional[str] = None,
    page: int = 1,
    limit: int = 20
):
    from app.models.models import User, Stall, StallFee, MarketManagement, Payment
    from datetime import datetime
    from sqlalchemy import func, or_, text

    # month string "YYYY-MM" -> first day of month
    try:
        month_date = datetime.strptime(f"{month}-01", "%Y-%m-%d").date()
    except ValueError:
        month_date = datetime.now().date().replace(day=1)

    next_month = (month_date.replace(day=28) + __import__('datetime').timedelta(days=4)).replace(day=1)

    # Single subquery for total_collected (avoids second round trip to remote DB)
    total_collected_subq = (
        db.query(func.coalesce(func.sum(StallFee.fee), 0.0))
        .join(Stall, Stall.stall_id == StallFee.stall_id)
        .filter(
            Stall.manage_id == manage_id,
            StallFee.month >= month_date,
            StallFee.month < next_month,
            StallFee.fee_status == "da_nop"
        )
        .scalar_subquery()
    )

    # Main query: join Stall + User + StallFee for the given month
    query = (
        db.query(Stall, User, StallFee, Payment)
        .join(User, User.user_id == Stall.user_id)
        .outerjoin(
            StallFee,
            (StallFee.stall_id == Stall.stall_id) &
            (StallFee.month >= month_date) &
            (StallFee.month < next_month)
        )
        .outerjoin(Payment, StallFee.payment_id == Payment.payment_id)
        .filter(Stall.manage_id == manage_id)
    )

    if search:
        search_filter = f"%{search}%"
        query = query.filter(
            or_(
                Stall.stall_id.ilike(search_filter),
                User.user_name.ilike(search_filter)
            )
        )

    if status and status != "tat_ca":
        if status == "da_nop":
            query = query.filter(StallFee.fee_status == "da_nop")
        elif status == "chua_nop":
            query = query.filter(
                (StallFee.fee_status == "chua_nop") | (StallFee.fee_id == None)
            )

    total = query.count()
    offset = (page - 1) * limit
    rows = query.offset(offset).limit(limit).all()

    # Execute total_collected in the same DB session (no extra network round trip)
    total_collected = float(
        db.query(func.coalesce(func.sum(StallFee.fee), 0.0))
        .join(Stall, Stall.stall_id == StallFee.stall_id)
        .filter(
            Stall.manage_id == manage_id,
            StallFee.month >= month_date,
            StallFee.month < next_month,
            StallFee.fee_status == "da_nop"
        )
        .scalar() or 0.0
    )

    data = []
    for stall, user, fee, payment in rows:
        fee_id = fee.fee_id if fee else None
        fee_status = fee.fee_status if fee else "chua_nop"
        fee_amount = float(fee.fee) if fee else 500000.0
        payment_time = payment.payment_time if payment else None
        
        # Auto-initialize missing record if needed (or just show placeholder info)
        # For listing, we just return the data. If user clicks, get_stall_fee_detail will initialize.
        
        data.append({
            "stall_id": stall.stall_id,
            "stall_name": stall.stall_name,
            "user_name": user.user_name if user else "Không rõ",
            "fee": fee_amount,
            "fee_status": fee_status,
            "fee_id": fee_id,
            "payment_time": payment_time,
        })

    return {
        "success": True,
        "data": data,
        "total_collected": float(total_collected),
        "meta": {
            "page": page,
            "limit": limit,
            "total": total,
            "total_pages": max(1, (total + limit - 1) // limit),
            "month": month
        }
    }


def get_stall_fee_detail(db: Session, fee_id: str):
    from app.models.models import Stall, User, StallFee, Market
    
    result = (
        db.query(StallFee, Stall, User, Market)
        .join(Stall, Stall.stall_id == StallFee.stall_id)
        .join(User, User.user_id == Stall.user_id)
        .join(Market, Market.market_id == Stall.market_id)
        .filter(StallFee.fee_id == fee_id)
        .first()
    )
    
    if not result:
        # Check if stall exists to auto-initialize fee record
        # Note: fee_id in our system usually looks like FE001. 
        # But if it's missing, we might have been passed a stall_id or just an empty record.
        # Actually, if we get here with a "fee_id" that doesn't exist, we should check if it's a stall_id.
        # For simplicity, if fee_id doesn't match a StallFee, we return None.
        # The frontend should ensure it only calls this with valid feeIds or handles missing ones.
        return None
        
    fee, stall, user, market = result
    
    return {
        "success": True,
        "data": {
            "fee_id": fee.fee_id,
            "stall_id": stall.stall_id,
            "stall_name": stall.stall_name,
            "user_name": user.user_name,
            "address": user.address,
            "fee": float(fee.fee),
            "fee_status": fee.fee_status,
            "month": fee.month.strftime("%Y-%m")
        }
    }


def confirm_stall_fee_payment(db: Session, fee_id: str, payment_method: str, note: Optional[str], amount: float):
    from app.models.models import StallFee, Payment, Stall
    from datetime import datetime
    import uuid
    
    # Try finding by fee_id first
    fee = db.query(StallFee).filter(StallFee.fee_id == fee_id).first()
    
    # If not found, check if fee_id is actually a stall_id (fallback for uninitialized records)
    if not fee:
        stall = db.query(Stall).filter(Stall.stall_id == fee_id).first()
        if not stall:
            return None
            
        current_month = datetime.now().date().replace(day=1)
        # Check if already exists for this stall/month (race condition guard)
        fee = db.query(StallFee).filter(
            StallFee.stall_id == stall.stall_id,
            StallFee.month == current_month
        ).first()
        
        if not fee:
            # Create a new record on-the-fly
            new_id = f"FE{str(uuid.uuid4())[:5].upper()}"
            fee = StallFee(
                fee_id=new_id,
                stall_id=stall.stall_id,
                fee=amount,
                fee_status="da_nop",
                fee_method=payment_method,
                month=current_month,
                note=note
            )
            db.add(fee)
            db.commit()
            db.refresh(fee)
            return {"success": True, "message": "Thu thuế thành công", "fee_id": fee.fee_id}

    # Update existing fee record
    fee.fee_status = "da_nop"
    fee.fee_method = payment_method
    fee.fee = amount
    fee.note = note
    
    # Update related payment record if it exists
    if hasattr(fee, 'payment_id') and fee.payment_id:
        payment = db.query(Payment).filter(Payment.payment_id == fee.payment_id).first()
        if payment:
            payment.payment_status = "da_thanh_toan"
            payment.payment_method = payment_method
            payment.amount = amount
            payment.payment_time = datetime.now()
    
    db.commit()
    return {"success": True, "message": "Xác nhận thu thuế thành công", "fee_id": fee.fee_id}


def get_dashboard_v2(db: Session, manage_id: str):
    from datetime import date, datetime
    from sqlalchemy import func
    from app.models.models import User, Stall

    # 1. Thống kê chung
    stalls = db.query(Stall, User).join(User, User.user_id == Stall.user_id).filter(
        Stall.manage_id == manage_id
    ).all()

    total_stalls = len(stalls)
    open_stalls = sum(1 for s, u in stalls if u.active_status == "mo_cua")
    closed_stalls = total_stalls - open_stalls

    # 2. Thống kê theo loại hàng (Category)
    cat_counts = {}
    for code, label in STALL_LOCATION_OPTIONS.items():
        cat_counts[code] = 0
    
    for stall, user in stalls:
        loc = stall.stall_location
        if loc in cat_counts:
            cat_counts[loc] += 1
        else:
            cat_counts["KH"] = cat_counts.get("KH", 0) + 1

    categories = [
        {"ma": "tat_ca", "ten": "Tất cả", "count": total_stalls}
    ]
    for code, label in STALL_LOCATION_OPTIONS.items():
        categories.append({"ma": code, "ten": f"Bán {label.lower()}", "count": cat_counts[code]})

    # 3. Danh sách gian hàng cho Grid
    stall_list = []
    for s, u in stalls:
        stall_list.append({
            "stall_id": s.stall_id,
            "stall_name": s.stall_name,
            "status": u.active_status,
            "user_name": u.user_name,
            "category_ma": s.stall_location
        })

    # 4. Nhật ký cập nhật hôm nay (Đã gỡ bỏ do giới hạn database)
    recent_logs = []

    return {
        "total_stalls": total_stalls,
        "open_stalls": open_stalls,
        "closed_stalls": closed_stalls,
        "categories": categories,
        "stalls": stall_list,
        "recent_logs": recent_logs
    }


def update_stall_status(db: Session, stall_id: str, status: str, note: Optional[str] = None):
    from datetime import datetime
    import uuid
    from app.models.models import Stall, User

    print(f"BACKEND: Updating status for stall {stall_id} to {status}")
    stall = db.query(Stall).filter(Stall.stall_id == stall_id).first()
    if not stall:
        print(f"BACKEND ERROR: Stall {stall_id} not found")
        return None

    user = db.query(User).filter(User.user_id == stall.user_id).first()
    if not user:
        print(f"BACKEND ERROR: User {stall.user_id} for stall {stall_id} not found")
        return None

    # status: mo_cua / dong_cua
    user.active_status = status
    print(f"BACKEND: Committing status update for user {user.user_id}")
    db.commit()

    return {"success": True, "message": "Cập nhật trạng thái thành công"}


def get_map_stalls(db: Session, manage_id: Optional[str] = None):
    from app.models.models import Stall, User
    
    query = db.query(Stall, User).join(User, User.user_id == Stall.user_id)
    if manage_id:
        query = query.filter(Stall.manage_id == manage_id)
        
    stalls = query.all()
    
    result = []
    for stall, user in stalls:
        result.append({
            "stall_id": stall.stall_id,
            "ten_gian_hang": stall.stall_name,
            "nguoi_ban": user.user_name,
            "x_col": stall.grid_col or 0,
            "y_row": stall.grid_row or 0,
            "loai_hang": stall.stall_location,
            "trang_thai": user.active_status,
            "sdt": user.phone
        })
        
    return result