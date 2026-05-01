from fastapi import APIRouter, Depends, Request, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import update
from fastapi.responses import JSONResponse, HTMLResponse
from app.repositories.payment import _mark_paid

from app.database import get_db
from app.models import Payment, PaymentStatus
from app.utils.vnpay import verify_signature, verify_signature_debug
from app.schemas.payment import (
    VNPayCheckoutRequest,
    VNPayCheckoutResponse,
    VNPayReturnResponse,
    VNPayIPNResponse,
)
from app.middlewares.auth import get_current_user
from app.services.payment import (
    vnpay_checkout,
    vnpay_return,
    vnpay_ipn,
)


router = APIRouter()


def _build_return_html(success: bool, message: str, order_id: str = "", error_code: str = "") -> str:
    """Tạo trang HTML kết quả thanh toán VNPay"""
    if success:
        icon_svg = '''<svg width="80" height="80" viewBox="0 0 80 80" fill="none"><circle cx="40" cy="40" r="40" fill="#00B40F" fill-opacity="0.15"/><circle cx="40" cy="40" r="30" fill="#00B40F" fill-opacity="0.25"/><path d="M25 42L35 52L55 30" stroke="#00B40F" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>'''
        bg_gradient = "linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 50%, #a5d6a7 100%)"
        accent_color = "#00B40F"
        card_border = "2px solid rgba(0, 180, 15, 0.3)"
        title = "Thanh toán thành công!"
        subtitle = f'Đơn hàng <strong>#{order_id}</strong> đã được thanh toán và đang xử lý.' if order_id else "Giao dịch đã được xác nhận thành công."
        badge_bg = "rgba(0, 180, 15, 0.1)"
        badge_color = "#00B40F"
        badge_text = "✓ Hoàn tất"
    else:
        icon_svg = '''<svg width="80" height="80" viewBox="0 0 80 80" fill="none"><circle cx="40" cy="40" r="40" fill="#FF3B30" fill-opacity="0.15"/><circle cx="40" cy="40" r="30" fill="#FF3B30" fill-opacity="0.25"/><path d="M30 30L50 50M50 30L30 50" stroke="#FF3B30" stroke-width="4" stroke-linecap="round"/></svg>'''
        bg_gradient = "linear-gradient(135deg, #ffebee 0%, #ffcdd2 50%, #ef9a9a 100%)"
        accent_color = "#FF3B30"
        card_border = "2px solid rgba(255, 59, 48, 0.3)"
        title = "Thanh toán thất bại"
        error_detail = f" (Mã lỗi: {error_code})" if error_code and error_code != "00" else ""
        subtitle = f"{message}{error_detail}. Vui lòng thử lại hoặc chọn phương thức thanh toán khác."
        badge_bg = "rgba(255, 59, 48, 0.1)"
        badge_color = "#FF3B30"
        badge_text = "✗ Thất bại"

    return f'''<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>{"Thanh toán thành công" if success else "Thanh toán thất bại"} - DNGo</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            min-height: 100vh;
            background: {bg_gradient};
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }}
        .container {{
            width: 100%;
            max-width: 420px;
            animation: slideUp 0.6s cubic-bezier(0.16, 1, 0.3, 1);
        }}
        @keyframes slideUp {{
            from {{ opacity: 0; transform: translateY(40px); }}
            to {{ opacity: 1; transform: translateY(0); }}
        }}
        @keyframes scaleIn {{
            from {{ opacity: 0; transform: scale(0.5); }}
            to {{ opacity: 1; transform: scale(1); }}
        }}
        @keyframes checkDraw {{
            from {{ stroke-dashoffset: 60; }}
            to {{ stroke-dashoffset: 0; }}
        }}
        .card {{
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            border-radius: 24px;
            border: {card_border};
            box-shadow: 0 20px 60px rgba(0,0,0,0.08), 0 4px 20px rgba(0,0,0,0.04);
            padding: 40px 32px;
            text-align: center;
        }}
        .icon-wrap {{
            margin-bottom: 24px;
            animation: scaleIn 0.5s cubic-bezier(0.34, 1.56, 0.64, 1) 0.2s both;
        }}
        .icon-wrap svg {{ display: inline-block; }}
        .badge {{
            display: inline-block;
            background: {badge_bg};
            color: {badge_color};
            font-size: 13px;
            font-weight: 700;
            padding: 6px 16px;
            border-radius: 20px;
            margin-bottom: 20px;
            letter-spacing: 0.5px;
        }}
        .title {{
            font-size: 24px;
            font-weight: 800;
            color: #1a1a1a;
            margin-bottom: 12px;
            line-height: 1.3;
        }}
        .subtitle {{
            font-size: 15px;
            color: #666;
            line-height: 1.6;
            margin-bottom: 32px;
        }}
        .subtitle strong {{
            color: #333;
            font-weight: 700;
        }}
        .info-row {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 14px 0;
            border-bottom: 1px solid rgba(0,0,0,0.06);
        }}
        .info-row:last-child {{ border-bottom: none; }}
        .info-label {{
            font-size: 13px;
            color: #999;
            font-weight: 500;
        }}
        .info-value {{
            font-size: 14px;
            color: #333;
            font-weight: 600;
        }}
        .divider {{
            height: 1px;
            background: linear-gradient(90deg, transparent, rgba(0,0,0,0.08), transparent);
            margin: 24px 0;
        }}
        .btn {{
            display: block;
            width: 100%;
            padding: 16px 24px;
            border: none;
            border-radius: 14px;
            font-family: 'Inter', sans-serif;
            font-size: 16px;
            font-weight: 700;
            cursor: pointer;
            text-decoration: none;
            text-align: center;
            transition: all 0.2s ease;
            margin-bottom: 12px;
        }}
        .btn:active {{ transform: scale(0.97); }}
        .btn-primary {{
            background: {accent_color};
            color: white;
            box-shadow: 0 4px 14px {accent_color}40;
        }}
        .btn-primary:hover {{
            box-shadow: 0 6px 20px {accent_color}50;
            transform: translateY(-1px);
        }}
        .btn-secondary {{
            background: transparent;
            color: #666;
            border: 1.5px solid #e0e0e0;
        }}
        .btn-secondary:hover {{
            background: #f5f5f5;
            border-color: #ccc;
        }}
        .logo {{
            margin-top: 24px;
            text-align: center;
            opacity: 0.5;
        }}
        .logo span {{
            font-size: 14px;
            font-weight: 600;
            color: #999;
            letter-spacing: 1px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="icon-wrap">{icon_svg}</div>
            <div class="badge">{badge_text}</div>
            <h1 class="title">{title}</h1>
            <p class="subtitle">{subtitle}</p>

            {'<div style="background:#f8f9fa;border-radius:12px;padding:16px;margin-bottom:24px;"><div class="info-row"><span class="info-label">Mã đơn hàng</span><span class="info-value">' + order_id + '</span></div><div class="info-row"><span class="info-label">Trạng thái</span><span class="info-value" style="color:' + accent_color + '">Đã thanh toán</span></div></div>' if success and order_id else ''}

            <button class="btn btn-primary" onclick="goBackToApp()">
                ← Đóng và Quay lại
            </button>
        </div>
        <div class="logo"><span>⚡ DNGo Payment</span></div>
    </div>

    <script>
        function goBackToApp() {{
            // Cố gắng đóng tab hiện tại
            window.close();
            // Nếu không thể đóng tab tự động do bảo mật trình duyệt
            setTimeout(function() {{
                alert('Vui lòng đóng tab/trình duyệt này bằng tay để quay lại ứng dụng.');
            }}, 500);
        }}

        // Tự động thử quay lại sau 60 giây
        setTimeout(function() {{
            // Hiển thị gợi ý
            var hint = document.createElement('p');
            hint.style.cssText = 'text-align:center;color:#999;font-size:13px;margin-top:16px;';
            hint.textContent = 'Bạn có thể đóng tab này và quay lại ứng dụng.';
            document.querySelector('.container').appendChild(hint);
        }}, 5000);
    </script>
</body>
</html>'''


@router.post("/vnpay/checkout", response_model=VNPayCheckoutResponse)
def checkout_vnpay(
    payload: VNPayCheckoutRequest,
    request: Request,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
):
    return vnpay_checkout(
        db=db,
        request=request,
        user=current_user,
        payload=payload.model_dump(),
    )


@router.get("/vnpay/return", response_model=None)
def vnpay_return_route(request: Request, db: Session = Depends(get_db)):
    try:
        params = dict(request.query_params)
        
        from app.utils.vnpay import verify_signature_debug
        dbg = verify_signature_debug(params)
        print("[VNPAY RETURN DEBUG]", dbg)

        # 1. Verify signature
        if not verify_signature(params):
            return HTMLResponse(_build_return_html(
                success=False,
                message="Chữ ký xác thực không hợp lệ"
            ))

        payment_id = str(params.get("vnp_TxnRef", "")).strip()
        response_code = params.get("vnp_ResponseCode")

        if not payment_id:
            return HTMLResponse(_build_return_html(
                success=False,
                message="Thiếu mã giao dịch"
            ))

        # 2. Thanh toán thành công
        if response_code == "00":
            try:
                order_id = _mark_paid(db, payment_id, params)
                db.commit()
                return HTMLResponse(_build_return_html(
                    success=True,
                    message="Thanh toán thành công",
                    order_id=order_id
                ))
            except Exception as e:
                err = str(e)
                print("MARK PAID ERROR:", err)

                # Nếu đã thanh toán qua IPN rồi thì vẫn hiện thành công
                if "ORDER_LOCKED" in err:
                    # Lấy order_id từ vnp_OrderInfo
                    info = str(params.get("vnp_OrderInfo", ""))
                    import re
                    m = re.search(r"don\s+([A-Z0-9_-]+)", info, re.I)
                    order_id = m.group(1) if m else ""
                    return HTMLResponse(_build_return_html(
                        success=True,
                        message="Thanh toán thành công",
                        order_id=order_id
                    ))

                db.rollback()
                return HTMLResponse(_build_return_html(
                    success=False,
                    message=f"Lỗi xử lý giao dịch: {err}"
                ))

        # 3. Thanh toán thất bại
        try:
            db.execute(
                update(Payment)
                .where(Payment.payment_id == payment_id)
                .values(payment_status=PaymentStatus.chua_thanh_toan.value)
            )
            db.commit()
        except Exception as e:
            print("UPDATE FAIL ERROR:", e)
            db.rollback()

        return HTMLResponse(_build_return_html(
            success=False,
            message="Thanh toán không thành công",
            error_code=response_code or ""
        ))

    except Exception as e:
        import traceback
        print("[VNPAY RETURN ERROR]", e)
        traceback.print_exc()
        return HTMLResponse(_build_return_html(
            success=False,
            message=f"Đã xảy ra lỗi hệ thống: {str(e)}"
        ))



@router.get("/vnpay/ipn")
def vnp_ipn_get(request: Request, db: Session = Depends(get_db)):
    try:
        params = dict(request.query_params)
        print("VNPAY IPN:", params)

        return vnpay_ipn(db, params)

    except Exception as e:
        print("❌ VNPAY IPN ERROR:", str(e))
        return {"RspCode": "99", "Message": str(e)}



@router.post("/vnpay/ipn", response_model=VNPayIPNResponse)
def vnp_ipn_post(request: Request, db: Session = Depends(get_db)):
    return vnpay_ipn(db, dict(request.query_params))