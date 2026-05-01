from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.middlewares.auth import get_current_user, allow, AuthUser
from app.repositories.wallet import wallet_repo
from app.schemas.wallet import WalletBalanceResponse, WithdrawRequestBody

router = APIRouter(prefix="/api/wallets", tags=["Wallet"])


def _validate(filter_type, from_date, to_date):
    if filter_type == "khoang":
        if not from_date or not to_date:
            raise HTTPException(
                status_code=400,
                detail="Cần truyền from_date và to_date khi filter_type=khoang"
            )
        if from_date > to_date:
            raise HTTPException(
                status_code=400,
                detail="from_date phải nhỏ hơn hoặc bằng to_date"
            )


@router.get("/{wallet_id}/balance", response_model=WalletBalanceResponse)
def get_wallet_balance(
    wallet_id: str,
    filter_type: str | None = Query(
        None,
        description="hom_nay | tuan_nay | thang_nay | khoang | bỏ trống = tất cả"
    ),
    from_date: date | None = Query(None, description="YYYY-MM-DD (dùng khi khoang)"),
    to_date:   date | None = Query(None, description="YYYY-MM-DD (dùng khi khoang)"),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user),
):
    """
    1 API duy nhất — truyền wallet_id, tự nhận biết loại ví:
    - platform → chỉ admin được xem
    - seller   → chỉ chủ gian hàng được xem
    - shipper  → chỉ shipper được xem
    - buyer    → chỉ buyer được xem
    """
    _validate(filter_type, from_date, to_date)

    wallet = wallet_repo.get_or_404(db, wallet_id)

    # Kiểm tra quyền xem
    role = current_user.role
    if wallet.owner_type == "platform" and role != "admin":
        raise HTTPException(status_code=403, detail="Chỉ admin được xem ví sàn")
    if wallet.owner_type == "seller" and role != "nguoi_ban":
        raise HTTPException(status_code=403, detail="Chỉ người bán được xem ví này")
    if wallet.owner_type == "shipper" and role != "shipper":
        raise HTTPException(status_code=403, detail="Chỉ shipper được xem ví này")
    if wallet.owner_type == "buyer" and role != "nguoi_mua":
        raise HTTPException(status_code=403, detail="Chỉ người mua được xem ví này")

    return wallet_repo.get_balance(
        db=db,
        wallet_id=wallet_id,
        filter_type=filter_type,
        from_date=from_date,
        to_date=to_date,
    )

@router.post("/{wallet_id}/withdraw")
def request_withdrawal(
    wallet_id: str,
    body: WithdrawRequestBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user),
):
    """
    Tạo yêu cầu rút tiền
    """
    wallet = wallet_repo.get_or_404(db, wallet_id)

    # Kiểm tra quyền
    role = current_user.role
    if wallet.owner_type == "platform" and role != "admin":
        raise HTTPException(status_code=403, detail="Chỉ admin mới thao tác được")
    if wallet.owner_type == "seller" and role != "nguoi_ban":
        raise HTTPException(status_code=403, detail="Chỉ chủ ví mới rút được tiền")
    if wallet.owner_type == "shipper" and role != "shipper":
        raise HTTPException(status_code=403, detail="Chỉ chủ ví mới rút được tiền")

    try:
        result = wallet_repo.request_withdraw(
            db=db,
            wallet_id=wallet_id,
            amount=body.amount,
            bank_bin=body.bank_bin,
            bank_account_no=body.bank_account_no,
            account_name=body.account_name
        )
        return {"success": True, "message": "Đã tạo yêu cầu rút tiền thành công", "data": result}
    except ValueError as e:
        raise HTTPException(400, str(e))


# ==================== ADMIN: VÍ SÀN & RÚT TIỀN ====================

class ProcessWithdrawalRequest(BaseModel):
    approved: bool
    note: Optional[str] = None


@router.get("/platform/balance")
def get_platform_wallet_balance(
    filter_type: Optional[str] = Query(None, description="hom_nay | tuan_nay | thang_nay | khoang"),
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("admin")),
):
    """Admin xem số dư và lịch sử ví sàn (không cần wallet_id)."""
    _validate(filter_type, from_date, to_date)
    return wallet_repo.get_platform_balance(db, filter_type=filter_type, from_date=from_date, to_date=to_date)


@router.post("/platform/withdraw")
def platform_withdraw(
    body: WithdrawRequestBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("admin")),
):
    """Admin tạo yêu cầu rút tiền từ ví sàn."""
    wallet = wallet_repo.get_platform_wallet(db)
    try:
        result = wallet_repo.request_withdraw(
            db=db,
            wallet_id=wallet.wallet_id,
            amount=body.amount,
            bank_bin=body.bank_bin,
            bank_account_no=body.bank_account_no,
            account_name=body.account_name,
        )
        return {"success": True, "message": "Đã tạo yêu cầu rút tiền thành công", "data": result}
    except ValueError as e:
        raise HTTPException(400, str(e))


@router.get("/admin/withdrawals")
def admin_list_withdrawals(
    status: Optional[str] = Query(None, description="chờ_duyệt | da_duyet | tu_choi | tat_ca"),
    owner_type: Optional[str] = Query(None, description="seller | shipper | platform | tat_ca"),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("admin")),
):
    """Admin xem tất cả yêu cầu rút tiền từ seller, shipper và sàn."""
    return wallet_repo.list_withdrawal_requests(db, status=status, owner_type=owner_type, page=page, limit=limit)


@router.patch("/admin/withdrawals/{request_id}")
def admin_process_withdrawal(
    request_id: int,
    body: ProcessWithdrawalRequest,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(allow("admin")),
):
    """Admin duyệt (approved=true) hoặc từ chối (approved=false) một yêu cầu rút tiền."""
    return wallet_repo.process_withdrawal(db, request_id=request_id, approved=body.approved, note=body.note)
