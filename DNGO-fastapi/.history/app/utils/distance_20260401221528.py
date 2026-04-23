import requests
import math


# ========================
# 1. Geocode (ổn định hơn)
# ========================
def geocode(address: str):
    url = "https://nominatim.openstreetmap.org/search"

    params = {
        "q": address,
        "format": "json",
        "limit": 1
    }

    headers = {
        "User-Agent": "dngo-app"  # bắt buộc
    }

    res = requests.get(url, params=params, headers=headers).json()

    if not res:
        raise ValueError(f"Không tìm thấy tọa độ: {address}")

    lat = float(res[0]["lat"])
    lng = float(res[0]["lon"])

    return lat, lng


# ========================
# 2. Haversine (KHÔNG phụ thuộc API)
# ========================
def get_distance_km(lat1, lng1, lat2, lng2):
    R = 6371

    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lng2 - lng1)

    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlon / 2) ** 2
    )

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


# ========================
# 3. Main
# ========================
def normalize(addr: str):
    return f"{addr}, Vietnam"


def calculate_distance(address1: str, address2: str):
    address1 = normalize(address1)
    address2 = normalize(address2)

    lat1, lng1 = geocode(address1)
    lat2, lng2 = geocode(address2)

    return get_distance_km(lat1, lng1, lat2, lng2)


# ========================
# 4. Map name
# ========================
def map_name(ingredient_id, stall_id):
    if ingredient_id == "NLDQ01" and stall_id == "GH0000":
        return "Phí ship"
    return None