# app/utils/shipping.py


import json




def determine_shipping_address(
    recipient: dict | None = None,
    legacy_fields: dict | None = None,
    saved_address: dict | None = None,
    user_profile: dict | None = None,
):
    recipient = recipient or {}
    legacy_fields = legacy_fields or {}
    saved_address = saved_address or {}
    user_profile = user_profile or {}


    name_final = (
        recipient.get("name")
        or legacy_fields.get("ten_nguoi_nhan")
        or saved_address.get("name")
        or user_profile.get("ten_nguoi_dung")
    )


    phone_final = (
        recipient.get("phone")
        or legacy_fields.get("sdt_nguoi_nhan")
        or saved_address.get("phone")
        or user_profile.get("sdt")
    )


    address_final = (
        recipient.get("address")
        or legacy_fields.get("dia_chi_giao_hang")
        or saved_address.get("address")
        or user_profile.get("dia_chi")
    )


    return {
        "name": name_final,
        "phone": phone_final,
        "address": address_final,
    }




def format_shipping_address(shipping_info: dict) -> str:
    return json.dumps({
        "name": str(shipping_info.get("name", "")).strip(),
        "phone": str(shipping_info.get("phone", "")).strip(),
        "address": str(shipping_info.get("address", "")).strip(),
    })




def parse_shipping_address(json_string: str | None):
    if not json_string:
        return None


    try:
        return json.loads(json_string)
    except Exception:
        return None

