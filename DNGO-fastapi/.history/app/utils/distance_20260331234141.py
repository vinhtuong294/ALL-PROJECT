import requests
from app.config import settings


# ========================
# 1. Geocode (address -> lat, lng)
# ========================
def geocode(address: str):
    url = "https://api.openrouteservice.org/geocode/search"

    params = {
        "api_key": settings.ORS_API_KEY,
        "text": address
    }

    res = requests.get(url, params=params).json()

    coords = res["features"][0]["geometry"]["coordinates"]
    lng, lat = coords

    return lat, lng


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

    res = requests.post(url, json=body, headers=headers).json()

    distance_m = res["features"][0]["properties"]["summary"]["distance"]

    return distance_m / 1000  # km


# ========================
# 3. Main function
# ========================
def calculate_distance(address1: str, address2: str):
    lat1, lng1 = geocode(address1)
    lat2, lng2 = geocode(address2)

    return get_distance_km(lat1, lng1, lat2, lng2)

def map_name(ingredient_id, stall_id):
    if ingredient_id == "NLDQ01" and stall_id == "GH0000":
        return "Phí ship"
    return None