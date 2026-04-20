from datetime import date, datetime, timedelta
from typing import Optional
from sqlalchemy.orm import Session
from sqlalchemy import func, cast, Date
from fastapi import HTTPException

from app.models.models import (
    Wallet, Order, OrderDetail,
    Payment, StallFee,
    Buyer, Stall, Shipper, Consolidation
)


# ==================== HELPER ====================

def _apply_date_filter(query, date_col, filter_type, from_date, to_date):
    today = date.today()
    if filter_type == "hom_nay":
        from_date = to_date = today
    elif filter_type == "tuan_nay":
        from_date = today - timedelta(days=today.weekday())
        to_date = today
    elif filter_type == "thang_nay":
        from_date = today.replace(day=1)
        to_date = today

    if from_date and to_date:
        query = query.filter(
            cast(date_col, Date) >= from_date,
            cast(date_col, Date) <= to_date,
        )
    return query, from_date, to_date


def _update_wallet_time(db: Session, owner_id: str):
    wallet = db.query(Wallet).filter(Wallet.owner_id == owner_id).first()
    if wallet:
        wallet.updated_wallet = datetime.utcnow()
        db.commit()


class WalletRepository:

    def get_or_404(self, db: Session, wallet_id: str) -> Wallet:
        wallet = db.query(Wallet).filter(Wallet.wallet_id == wallet_id).first()
        if not wallet:
            raise HTTPException(status_code=404, detail=f"Wallet '{wallet_id}' không tồn tại")
        return wallet

    # ==================== 1 API GỘP ====================

    def get_balance(
        self,
        db: Session,
        wallet_id: str,
        filter_type: Optional[str] = None,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
    ) -> dict:

        wallet = self.get_or_404(db, wallet_id)
        owner_type = wallet.owner_type

        if owner_type == "platform":
            return self._platform_balance(db, wallet, filter_type, from_date, to_date)
        elif owner_type == "seller":
            return self._seller_balance(db, wallet, filter_type, from_date, to_date)
        elif owner_type == "shipper":
            return self._shipper_balance(db, wallet, filter_type, from_date, to_date)
        elif owner_type == "buyer":
            return self._buyer_balance(db, wallet, filter_type, from_date, to_date)
        else:
            raise HTTPException(status_code=400, detail="owner_type không hợp lệ")

    # ==================== PLATFORM ====================

    def _platform_balance(self, db, wallet, filter_type, from_date, to_date):
        chi_tiet = []
        tien_vao = 0
        tien_ra  = 0

        # ── TIỀN VÀO 1: đơn hàng đã thanh toán ────────
        q = db.query(
            Order.order_id,
            Order.payment_id,
            Payment.payment_time,
            func.sum(OrderDetail.line_total).label("so_tien"),
        ).join(
            OrderDetail, OrderDetail.order_id == Order.order_id
        ).join(
            Payment, Payment.payment_id == Order.payment_id
        ).filter(
            Payment.payment_status == "da_thanh_toan"
        ).group_by(
            Order.order_id, Order.payment_id, Payment.payment_time
        )
        q, fd, td = _apply_date_filter(q, Payment.payment_time, filter_type, from_date, to_date)

        for r in q.all():
            so_tien = int(r.so_tien or 0)
            tien_vao += so_tien
            chi_tiet.append(WalletDetailItem(
                loai="don_hang",
                huong="vao",
                so_tien=so_tien,
                order_id=r.order_id,
                payment_id=r.payment_id,
                ngay=r.payment_time,
            ))

        # ── TIỀN VÀO 2: phí gian hàng đã nộp ──────────
        q2 = db.query(StallFee).filter(StallFee.fee_status == "da_nop")
        if fd and td:
            q2 = q2.filter(StallFee.month >= fd, StallFee.month <= td)

        for r in q2.all():
            so_tien = int(r.fee or 0)
            tien_vao += so_tien
            chi_tiet.append(WalletDetailItem(
                loai="phi_gian_hang",
                huong="vao",
                so_tien=so_tien,
                fee_id=r.fee_id,
                ngay=datetime.combine(r.month, datetime.min.time()) if r.month else None,
            ))

        # ── TIỀN RA: hoàn hàng ─────────────────────────
        q3 = db.query(
            OrderDetail.order_id,
            Order.order_time,
            func.sum(OrderDetail.line_total).label("so_tien"),
        ).join(
            Order, Order.order_id == OrderDetail.order_id
        ).filter(
            OrderDetail.detail_status == "hoan_hang"
        ).group_by(
            OrderDetail.order_id, Order.order_time
        )
        q3, _, __ = _apply_date_filter(q3, Order.order_time, filter_type, from_date, to_date)

        for r in q3.all():
            so_tien = int(r.so_tien or 0)
            tien_ra += so_tien
            chi_tiet.append(WalletDetailItem(
                loai="hoan_hang",
                huong="ra",
                so_tien=so_tien,
                order_id=r.order_id,
                ngay=r.order_time,
            ))

        chi_tiet.sort(key=lambda x: x.ngay or datetime.min, reverse=True)

        return {
            "wallet_id":     wallet.wallet_id,
            "owner_id":      wallet.owner_id,
            "owner_type":    wallet.owner_type,
            "updated_wallet": wallet.updated_wallet,
            "tong_tien_vao": tien_vao,
            "tong_tien_ra":  tien_ra,
            "so_du":         tien_vao - tien_ra,
            "chi_tiet":      chi_tiet,
        }

    # ==================== SELLER ====================

    def _seller_balance(self, db, wallet, filter_type, from_date, to_date):
        chi_tiet = []
        tien_vao = 0
        tien_ra  = 0

        stall_id = wallet.owner_id

        # ── TIỀN VÀO: đơn hoàn thành ───────────────────
        q = db.query(
            OrderDetail.order_id,
            Order.order_time,
            func.sum(OrderDetail.line_total).label("so_tien"),
        ).join(
            Order, Order.order_id == OrderDetail.order_id
        ).filter(
            OrderDetail.stall_id == stall_id,
            Order.order_status == "da_giao",
        ).group_by(OrderDetail.order_id, Order.order_time)
        q, _, __ = _apply_date_filter(q, Order.order_time, filter_type, from_date, to_date)

        for r in q.all():
            so_tien = int(r.so_tien or 0)
            tien_vao += so_tien
            chi_tiet.append(WalletDetailItem(
                loai="don_hang",
                huong="vao",
                so_tien=so_tien,
                order_id=r.order_id,
                ngay=r.order_time,
            ))

        # ── TIỀN RA: lỗi sản phẩm ──────────────────────
        q2 = db.query(
            OrderDetail.order_id,
            Order.order_time,
            OrderDetail.cancel_reason,
            func.sum(OrderDetail.line_total).label("so_tien"),
        ).join(
            Order, Order.order_id == OrderDetail.order_id
        ).filter(
            OrderDetail.stall_id == stall_id,
            OrderDetail.cancel_reason.in_([
                "Sản phẩm không giống mô tả",
                "Chất lượng sản phẩm kém",
            ])
        ).group_by(OrderDetail.order_id, Order.order_time, OrderDetail.cancel_reason)
        q2, _, __ = _apply_date_filter(q2, Order.order_time, filter_type, from_date, to_date)

        for r in q2.all():
            so_tien = int(r.so_tien or 0)
            tien_ra += so_tien
            chi_tiet.append(WalletDetailItem(
                loai="hoan_hang",
                huong="ra",
                so_tien=so_tien,
                order_id=r.order_id,
                cancel_reason=r.cancel_reason,
                ngay=r.order_time,
            ))

        chi_tiet.sort(key=lambda x: x.ngay or datetime.min, reverse=True)

        return {
            "wallet_id":     wallet.wallet_id,
            "owner_id":      wallet.owner_id,
            "owner_type":    wallet.owner_type,
            "updated_wallet": wallet.updated_wallet,
            "tong_tien_vao": tien_vao,
            "tong_tien_ra":  tien_ra,
            "so_du":         tien_vao - tien_ra,
            "chi_tiet":      chi_tiet,
        }

    # ==================== SHIPPER ====================

    def _shipper_balance(self, db, wallet, filter_type, from_date, to_date):
        chi_tiet = []
        tien_vao = 0
        tien_ra  = 0

        shipper = db.query(Shipper).filter(
            Shipper.shipper_id == wallet.owner_id
        ).first()
        if not shipper:
            raise HTTPException(status_code=404, detail="Không tìm thấy shipper")

        SHIP_ID = "NLQD01"

        # ── TIỀN VÀO: phí ship đơn hoàn thành ─────────
        q = db.query(
            OrderDetail.order_id,
            Order.order_time,
            func.sum(OrderDetail.line_total).label("so_tien"),
        ).join(
            Order, Order.order_id == OrderDetail.order_id
        ).join(
            Consolidation,
            Consolidation.consolidation_id == Order.consolidation_id
        ).filter(
            OrderDetail.ingredient_id == SHIP_ID,
            Consolidation.shipper_id == shipper.shipper_id,
            Order.order_status == "da_giao",
        ).group_by(OrderDetail.order_id, Order.order_time)
        q, _, __ = _apply_date_filter(q, Order.order_time, filter_type, from_date, to_date)

        for r in q.all():
            so_tien = int(r.so_tien or 0)
            tien_vao += so_tien
            chi_tiet.append(WalletDetailItem(
                loai="phi_ship",
                huong="vao",
                so_tien=so_tien,
                order_id=r.order_id,
                ngay=r.order_time,
            ))

        # ── TIỀN RA: lỗi giao hàng ─────────────────────
        q2 = db.query(
            OrderDetail.order_id,
            Order.order_time,
            OrderDetail.cancel_reason,
            func.sum(OrderDetail.line_total).label("so_tien"),
        ).join(
            Order, Order.order_id == OrderDetail.order_id
        ).join(
            Consolidation,
            Consolidation.consolidation_id == Order.consolidation_id
        ).filter(
            OrderDetail.ingredient_id == SHIP_ID,
            Consolidation.shipper_id == shipper.shipper_id,
            OrderDetail.cancel_reason.in_([
                "Hàng hóa đổ bể",
                "Giao hàng trễ",
            ])
        ).group_by(OrderDetail.order_id, Order.order_time, OrderDetail.cancel_reason)
        q2, _, __ = _apply_date_filter(q2, Order.order_time, filter_type, from_date, to_date)

        for r in q2.all():
            so_tien = int(r.so_tien or 0)
            tien_ra += so_tien
            chi_tiet.append(WalletDetailItem(
                loai="loi_giao_hang",
                huong="ra",
                so_tien=so_tien,
                order_id=r.order_id,
                cancel_reason=r.cancel_reason,
                ngay=r.order_time,
            ))

        chi_tiet.sort(key=lambda x: x.ngay or datetime.min, reverse=True)

        return {
            "wallet_id":     wallet.wallet_id,
            "owner_id":      wallet.owner_id,
            "owner_type":    wallet.owner_type,
            "updated_wallet": wallet.updated_wallet,
            "tong_tien_vao": tien_vao,
            "tong_tien_ra":  tien_ra,
            "so_du":         tien_vao - tien_ra,
            "chi_tiet":      chi_tiet,
        }

    # ==================== BUYER ====================

    def _buyer_balance(self, db, wallet, filter_type, from_date, to_date):
        chi_tiet = []
        tien_vao = 0

        buyer = db.query(Buyer).filter(
            Buyer.buyer_id == wallet.owner_id
        ).first()
        if not buyer:
            raise HTTPException(status_code=404, detail="Không tìm thấy buyer")

        # ── TIỀN VÀO: được hoàn tiền ───────────────────
        q = db.query(
            OrderDetail.order_id,
            OrderDetail.detail_status,
            Order.order_time,
            func.sum(OrderDetail.line_total).label("so_tien"),
        ).join(
            Order, Order.order_id == OrderDetail.order_id
        ).filter(
            Order.buyer_id == buyer.buyer_id,
            OrderDetail.detail_status.in_([
                "tu_choi", "huy_hang", "hoan_hang"
            ])
        ).group_by(
            OrderDetail.order_id,
            OrderDetail.detail_status,
            Order.order_time,
        )
        q, _, __ = _apply_date_filter(q, Order.order_time, filter_type, from_date, to_date)

        for r in q.all():
            so_tien = int(r.so_tien or 0)
            tien_vao += so_tien
            chi_tiet.append(WalletDetailItem(
                loai="hoan_tien",
                huong="vao",
                so_tien=so_tien,
                order_id=r.order_id,
                detail_status=r.detail_status,
                ngay=r.order_time,
            ))

        chi_tiet.sort(key=lambda x: x.ngay or datetime.min, reverse=True)

        return {
            "wallet_id":      wallet.wallet_id,
            "owner_id":       wallet.owner_id,
            "owner_type":     wallet.owner_type,
            "updated_wallet": wallet.updated_wallet,
            "tong_tien_vao":  tien_vao,
            "tong_tien_ra":   0,          # ← buyer không có tiền ra
            "so_du":          tien_vao,   # ← so_du = tien_vao
            "chi_tiet":       chi_tiet,
        }

wallet_repo = WalletRepository()


# ── Import ở cuối tránh circular ─────────────────────────
from app.schemas.wallet import WalletDetailItem