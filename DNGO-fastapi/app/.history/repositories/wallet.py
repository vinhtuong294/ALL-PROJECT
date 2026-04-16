from typing import cast
from sqlalchemy.orm import Session
from sqlalchemy import select, func
from fastapi import HTTPException
from app.models import Wallet, WalletDetail
from app.schemas.wallet import WalletCreate, TransactionCreate, DoubleEntryRequest


class WalletRepository:

    # ── Wallet ──────────────────────────────────────────

    def get_by_id(self, db: Session, wallet_id: str) -> Wallet | None:
        return cast(Wallet | None, db.get(Wallet, wallet_id))

    def get_by_owner(self, db: Session, owner_id: str, owner_type: str) -> Wallet | None:
        return db.execute(
            select(Wallet).where(
                Wallet.owner_id == owner_id,
                Wallet.owner_type == owner_type,
            )
        ).scalar_one_or_none()

    def get_or_404(self, db: Session, wallet_id: str) -> Wallet:
        wallet = self.get_by_id(db, wallet_id)
        if not wallet:
            raise HTTPException(status_code=404, detail=f"Wallet '{wallet_id}' không tồn tại")
        return wallet

    def create(self, db: Session, data: WalletCreate) -> Wallet:
        existing = self.get_by_owner(db, data.owner_id, data.owner_type)
        if existing:
            raise HTTPException(
                status_code=409,
                detail=f"{data.owner_type} '{data.owner_id}' đã có ví ({existing.wallet_id})"
            )
        wallet = Wallet(**data.model_dump())
        db.add(wallet)
        db.commit()
        db.refresh(wallet)
        return wallet

    # ── Balance ──────────────────────────────────────────

    def get_balance(self, db: Session, wallet_id: str) -> int:
        self.get_or_404(db, wallet_id)
        result = db.execute(
            select(func.coalesce(func.sum(WalletDetail.amount), 0))
            .where(WalletDetail.wallet_id == wallet_id)
        ).scalar()
        return int(result)  # cast rõ ràng tránh Pylance warning

    # ── Transactions ──────────────────────────────────────

    def get_transactions(
        self,
        db: Session,
        wallet_id: str,
        limit: int = 50,
        offset: int = 0,
    ) -> list[WalletDetail]:
        self.get_or_404(db, wallet_id)
        return list(
            db.execute(
                select(WalletDetail)
                .where(WalletDetail.wallet_id == wallet_id)
                .order_by(WalletDetail.created_at.desc())
                .limit(limit)
                .offset(offset)
            ).scalars().all()
        )

    def _create_tx(self, db: Session, data: TransactionCreate) -> WalletDetail:
        tx = WalletDetail(**data.model_dump())
        db.add(tx)
        return tx

    # ── Double Entry ──────────────────────────────────────

    def double_entry(
        self, db: Session, data: DoubleEntryRequest
    ) -> tuple[WalletDetail, WalletDetail]:
        self.get_or_404(db, data.from_wallet_id)
        self.get_or_404(db, data.to_wallet_id)

        debit = self._create_tx(db, TransactionCreate(
            wallet_id=data.from_wallet_id,
            order_id=data.order_id,
            amount=-data.amount,
            transaction_type=data.transaction_type,
        ))
        credit = self._create_tx(db, TransactionCreate(
            wallet_id=data.to_wallet_id,
            order_id=data.order_id,
            amount=data.amount,
            transaction_type=data.transaction_type,
        ))

        db.commit()
        db.refresh(debit)
        db.refresh(credit)
        return debit, credit


wallet_repo = WalletRepository()