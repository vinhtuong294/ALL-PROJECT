# app/utils/vnpay.py


import hmac
import hashlib
import os




# =====================================================
# HELPER
# =====================================================


def _sort_object(obj: dict) -> dict:
    return dict(sorted(obj.items()))




def _make_sign_data(obj: dict) -> str:
    """
    Tạo chuỗi ký: sort key, join raw value (KHÔNG encode URL).
    VNPay ký trên chuỗi raw, không phải encoded.
    """
    from urllib.parse import quote_plus
    data = {
        k: v for k, v in obj.items()
        if k not in ("vnp_SecureHash", "vnp_SecureHashType")
    }
    sorted_data = _sort_object(data)
    return "&".join(f"{k}={quote_plus(str(v).strip())}" for k, v in sorted_data.items())




def _compute_hash(sign_data: str, secret: str, hash_type: str) -> str:
    ht = (hash_type or "").upper()


    if ht == "HMACSHA256":
        return hmac.new(
            secret.encode("utf-8"),
            sign_data.encode("utf-8"),
            hashlib.sha256,
        ).hexdigest().upper()


    if ht == "SHA256":
        return hashlib.sha256(
            (secret + sign_data).encode("utf-8")
        ).hexdigest().upper()


    # default: HMACSHA512
    return hmac.new(
        secret.encode("utf-8"),
        sign_data.encode("utf-8"),
        hashlib.sha512,
    ).hexdigest().upper()




def _get_secret() -> str:
    raw = os.getenv("VNP_HASH_SECRET") or os.getenv("VNP_HASHSECRET") or ""
    return raw.replace('"', "").replace("'", "").replace("\r", "").replace("\n", "").strip()




def _get_hash_type() -> str:
    return (os.getenv("VNP_SECURE_HASH_TYPE") or "HMACSHA512").upper()




# =====================================================
# VERIFY
# =====================================================


def verify_signature(obj: dict) -> bool:
    """
    Verify chữ ký VNPay dựa trên các param trả về (exclude vnp_SecureHash và vnp_SecureHashType)
    """
    secret = _get_secret()
    if not secret:
        raise Exception("Missing VNP_HASH_SECRET")

    # Lấy hash type từ VNPay trả về
    hash_type = obj.get("vnp_SecureHashType", "HMACSHA512").upper()
    client_hash = str(obj.get("vnp_SecureHash", "")).upper()

    from urllib.parse import quote_plus
    
    # Lọc param để tính hash: tất cả param bắt đầu bằng vnp_ trừ vnp_SecureHash và vnp_SecureHashType
    data = {k: v for k, v in obj.items() if k.startswith("vnp_") and k not in ("vnp_SecureHash", "vnp_SecureHashType")}
    
    # VNPay yêu cầu encodeURIComponent cho giá trị trước khi hash
    sign_data = "&".join(f"{k}={quote_plus(str(v).strip())}" for k, v in sorted(data.items()))

    expected = _compute_hash(sign_data, secret, hash_type)

    return expected == client_hash

def verify_signature_debug(obj: dict) -> dict:
    secret = _get_secret()
    hash_type = _get_hash_type()
    client_hash = str(obj.get("vnp_SecureHash", "")).upper()

    params = obj.copy()
    params.pop("vnp_SecureHash", None)

    sign_data = _make_sign_data(params)
    expected = _compute_hash(sign_data, secret, hash_type)

    return {
        "ok": expected == client_hash,
        "type": hash_type,
        "expected": expected,
        "client": client_hash,
        "sign_data": sign_data,
    }