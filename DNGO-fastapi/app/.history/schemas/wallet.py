from datetime import datetime
from pydantic import BaseModel, field_validator
from typing import Literal

OwnerType = Literal["buyer", "seller", "shipper", "platform"]
TransactionType = Literal["payment", "payout_seller", "payout_shipper", "refund", "penalty"]


class WalletCreate(BaseModel):
    wallet_id: str
    owner_id: str  # buyer_id / stall_id / shipper_id / 'PLATFORM'
    owner_type: OwnerType


class WalletResponse(BaseModel):
    wallet_id: str
    owner_id: str
    owner_type: str
    created_at: datetime

    model_config = {"from_attributes": True}


class TransactionCreate(BaseModel):
    wallet_id: str
    order_id: str | None = None
    amount: int
    transaction_type: TransactionType

    @field_validator("amount")
    @classmethod
    def amount_not_zero(cls, v: int) -> int:
        if v == 0:
            raise ValueError("amount không được bằng 0")
        return v


class TransactionResponse(BaseModel):
    transaction_id: int
    wallet_id: str
    order_id: str | None
    amount: int
    transaction_type: str
    created_at: datetime

    model_config = {"from_attributes": True}


class BalanceResponse(BaseModel):
    wallet_id: str
    owner_id: str
    owner_type: str
    balance: int


class DoubleEntryRequest(BaseModel):
    """Giao dịch kép: 1 request tạo 2 dòng cùng lúc"""
    from_wallet_id: str
    to_wallet_id: str
    order_id: str | None = None
    amount: int  # luôn dương — hệ thống tự xử lý dấu
    transaction_type: TransactionType

    @field_validator("amount")
    @classmethod
    def amount_positive(cls, v: int) -> int:
        if v <= 0:
            raise ValueError("amount phải dương (hệ thống tự xử lý dấu +/-)")
        return v


class DoubleEntryResponse(BaseModel):
    debit: TransactionResponse   # dòng trừ (from)
    credit: TransactionResponse  # dòng cộng (to)