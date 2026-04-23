import requests
from app.config import settings


# ========================
# 1. Geocode (address -> lat, lng)
# ========================
def geocode(address: str):
    # ====== TRY 1: OpenRouteService ======
    try:
        url = "https://api.openrouteservice.org/geocode/search"
        params = {
            "api_key": settings.ORS_API_KEY,
            "text": address
        }

        res = requests.get(url, params=params, timeout=5).json()

        features = res.get("features", [])
        if features:
            coords = features[0]["geometry"]["coordinates"]
            lng, lat = coords
            return lat, lng
    except:
        pass

    # ====== TRY 2: Nominatim (FREE - mạnh hơn cho VN) ======
    try:
        url = "https://nominatim.openstreetmap.org/search"
        params = {
            "q": address,
            "format": "json",
            "limit": 1
        }

        headers = {
            "User-Agent": "dngo-app"
        }

        res = requests.get(url, params=params, headers=headers, timeout=5).json()

        if res:
            lat = float(res[0]["lat"])
            lng = float(res[0]["lon"])
            return lat, lng
    except:
        pass

    # ====== FAIL ======
    raise ValueError(f"Không tìm thấy tọa độ cho địa chỉ: {address}")


# ========================
# 2. Distance (real road)
# ========================
def get_distance_km(lat1, lng1, lat2, lng2):
    url = "https://api.openrouteservice.org/v2/directions/driving-car"

    headers = {
        "Authorization": settings.ORS_API_KEY,
        "Content-Type": "application/json"
    }

    body = {
        "coordinates": [[lng1, lat1], [lng2, lat2]]
    }

    res = requests.post(url, json=body, headers=headers, timeout=10).json()

    try:
        distance_m = res["features"][0]["properties"]["summary"]["distance"]
        return distance_m / 1000
    except:
        return None


# ========================
# 3. Main function
# ========================
def calculate_distance(address1: str, address2: str):
    try:
        lat1, lng1 = geocode(address1)
        lat2, lng2 = geocode(address2)

        distance = get_distance_km(lat1, lng1, lat2, lng2)

        if distance is None:
            return None

        return distance

    except Exception as e:
        print("Distance error:", e)
        return None


# ========================
# 4. Map name
# ========================
def map_name(ingredient_id, stall_id):
    if ingredient_id == "NLDQ01" and stall_id == "GH0000":
        return "Phí ship"
    return None