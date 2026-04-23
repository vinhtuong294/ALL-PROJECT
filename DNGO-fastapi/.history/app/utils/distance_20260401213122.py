# utils/distance.py
import requests
from app.config import settings

# ========================
# 1. Geocode (address -> lat, lng)
# ========================
def geocode(address: str):
    url = "https://graphhopper.com/api/1/geocode"
    params = {
        "q": address,
        "locale": "vi",
        "limit": 1,
        "key": settings.GRAPH_HOPPER_API_KEY
    }

    res = requests.get(url, params=params).json()
    hits = res.get("hits", [])

    if not hits:
        raise ValueError(f"Không tìm thấy tọa độ cho địa chỉ: {address}")

    lat = hits[0]["point"]["lat"]
    lng = hits[0]["point"]["lng"]
    return lat, lng

# ========================
# 2. Distance (real road)
# ========================
def get_distance_km(lat1, lng1, lat2, lng2):
    url = "https://graphhopper.com/api/1/route"
    params = {
        "point": [f"{lat1},{lng1}", f"{lat2},{lng2}"],
        "vehicle": "car",
        "locale": "vi",
        "calc_points": False,
        "key": settings.GRAPH_HOPPER_API_KEY
    }

    res = requests.get(url, params=params).json()

    paths = res.get("paths", [])
    if not paths:
        raise ValueError("Không thể tính đường đi giữa 2 địa chỉ")

    distance_m = paths[0]["distance"]
    return distance_m / 1000  # km

# ========================
# 3. Main function
# ========================
def calculate_distance(address1: str, address2: str):
    try:
        lat1, lng1 = geocode(address1)
        lat2, lng2 = geocode(address2)
        return get_distance_km(lat1, lng1, lat2, lng2)
    except ValueError as e:
        print("Geocode error:", e)
        return None

# ========================
# 4. Map name for special IDs
# ========================
def map_name(ingredient_id, stall_id):
    if ingredient_id == "NLDQ01" and stall_id == "GH0000":
        return "Phí ship"
    return None