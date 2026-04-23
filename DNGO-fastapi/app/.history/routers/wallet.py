from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.dependencies import get_db
from app.repositories.wallet import wallet_repo
from app.schemas.wallet import (
    WalletCreate, WalletResponse,
    TransactionResponse, BalanceResponse,
    DoubleEntryRequest, DoubleEntryResponse,
)

router = APIRouter(prefix="/wallets", tags=["Wallet"])


# ── Tạo ví ───────────────────────────────────────────────
@router.post("/", response_model=WalletResponse, status_code=201)
def create_wallet(data: WalletCreate, db: Session = Depends(get_db)):
    return wallet_repo.create(db, data)


# ── Lấy thông tin ví ─────────────────────────────────────
@router.get("/{wallet_id}", response_model=WalletResponse)
def get_wallet(wallet_id: str, db: Session = Depends(get_db)):
    return wallet_repo.get_or_404(db, wallet_id)


# ── Số dư ────────────────────────────────────────────────
@router.get("/{wallet_id}/balance", response_model=BalanceResponse)
def get_balance(wallet_id: str, db: Session = Depends(get_db)):
    wallet = wallet_repo.get_or_404(db, wallet_id)
    balance = wallet_repo.get_balance(db, wallet_id)
    return BalanceResponse(
        wallet_id=wallet_id,
        owner_id=wallet.owner_id,
        owner_type=wallet.owner_type,
        balance=balance,
    )


# ── Lịch sử giao dịch ────────────────────────────────────
@router.get("/{wallet_id}/transactions", response_model=list[TransactionResponse])
def list_transactions(
    wallet_id: str,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    return wallet_repo.get_transactions(db, wallet_id, limit, offset)


# ── Giao dịch kép (double-entry) ─────────────────────────
@router.post("/transfer", response_model=DoubleEntryResponse, status_code=201)
def transfer(data: DoubleEntryRequest, db: Session = Depends(get_db)):
    """
    Dùng cho mọi luồng tiền:
    - Buyer thanh toán → from: buyer_wallet, to: platform_wallet
    - Payout seller    → from: platform_wallet, to: seller_wallet
    - Payout shipper   → from: platform_wallet, to: shipper_wallet
    - Hoàn tiền        → from: platform_wallet, to: buyer_wallet
    """
    debit, credit = wallet_repo.double_entry(db, data)
    return DoubleEntryResponse(debit=debit, credit=credit)