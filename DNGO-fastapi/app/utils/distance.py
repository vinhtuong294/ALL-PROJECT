import json
import os
import re
import requests
from functools import lru_cache

# ========================
# 1. Geocode (GraphHopper primary, Nominatim fallback)
# ========================
def _extract_address(raw: str) -> str:
    """Extract plain address string from either a plain string or a JSON blob
    like {"name": ..., "address": "..."}.  Also strips postal codes and
    country suffixes so GraphHopper gets a clean Vietnamese street address."""
    raw = raw.strip()
    # Parse JSON-encoded address objects
    if raw.startswith('{'):
        try:
            obj = json.loads(raw)
            raw = obj.get('address') or obj.get('dia_chi') or raw
        except (json.JSONDecodeError, AttributeError):
            pass
    # Strip country name (with its leading separator)
    raw = re.sub(r'[,\s]+(vi[eê]t\s*nam|viet\s*nam|vietnam)\s*$', '', raw.strip(), flags=re.IGNORECASE).strip()
    # Strip trailing 5-6 digit postal code (e.g. ", 02363")
    raw = re.sub(r',\s*\d{5,6}\s*$', '', raw).strip()
    return raw


import logging as _logging
_log = _logging.getLogger(__name__)

def geocode(address: str):
    clean = _extract_address(address)
    if not clean or clean.lower() in ('n/a', 'na', ''):
        raise ValueError(f"Địa chỉ không hợp lệ: {address}")
    gh_key = os.getenv("GRAPH_HOPPER_API_KEY", "")
    _log.info(f"[geocode] key={'SET' if gh_key else 'EMPTY'} clean={repr(clean[:50])}")
    if gh_key:
        return _geocode_graphhopper(clean, gh_key)
    return _geocode_nominatim(clean)


@lru_cache(maxsize=512)
def _geocode_graphhopper(address: str, key: str):
    import time as _t
    t0 = _t.time()
    url = "https://graphhopper.com/api/1/geocode"
    params = {"q": f"{address}, Vietnam", "locale": "vi", "limit": 1, "key": key}
    try:
        res = requests.get(url, params=params, timeout=10).json()
    except Exception as e:
        _log.error(f"[GH] FAIL {_t.time()-t0:.2f}s {repr(address[:50])}: {e}")
        raise ValueError(f"Không thể geocode địa chỉ: {address}")
    hits = res.get("hits", [])
    _log.info(f"[GH] {_t.time()-t0:.2f}s hits={len(hits)} {repr(address[:50])}")
    if not hits:
        raise ValueError(f"Không tìm thấy tọa độ: {address}")
    point = hits[0]["point"]
    return float(point["lat"]), float(point["lng"])


@lru_cache(maxsize=512)
def _geocode_nominatim(address: str):
    url = "https://nominatim.openstreetmap.org/search"
    params = {"q": f"{address}, Vietnam", "format": "json", "limit": 1}
    headers = {"User-Agent": "dngo-app"}
    try:
        res = requests.get(url, params=params, headers=headers, timeout=10).json()
    except Exception:
        raise ValueError(f"Không thể geocode địa chỉ: {address}")
    if not res:
        raise ValueError(f"Không tìm thấy tọa độ: {address}")
    return float(res[0]["lat"]), float(res[0]["lon"])

# ========================
# 2. Khoảng cách đường đi theo OSRM
# ========================
def get_distance_km(lat1, lng1, lat2, lng2):
    url = f"http://router.project-osrm.org/route/v1/driving/{lng1},{lat1};{lng2},{lat2}?overview=false"
    try:
        res = requests.get(url, timeout=10).json()
    except Exception:
        res = {}

    if "routes" in res and res["routes"]:
        distance_m = res["routes"][0]["distance"]
        return distance_m / 1000  # km
    else:
        # fallback: Haversine (không lệch quá)
        import math
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
# 3. Main function
# ========================
def calculate_distance(address1: str, address2: str):
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


# ========================
# 5. Tối ưu thứ tự giao hàng (TSP - Nearest Neighbor)
# ========================
def _haversine_km(lat1, lng1, lat2, lng2) -> float:
    """Haversine formula — no HTTP call, good enough for ordering stops."""
    import math
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lng2 - lng1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2))
        * math.sin(dlon / 2) ** 2
    )
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def optimize_delivery_route(market_address: str, delivery_addresses: list) -> dict:
    """
    Tối ưu thứ tự giao hàng cho shipper gom đơn.

    Input:
    - market_address: địa chỉ chợ (điểm xuất phát)
    - delivery_addresses: list dict {"order_id": ..., "address": ...}

    Output:
    - optimized_route: thứ tự giao hàng tối ưu
    - total_distance_km: tổng quãng đường
    """
    if not delivery_addresses:
        return {"optimized_route": [], "total_distance_km": 0}

    # Geocode tất cả địa chỉ — dùng Haversine cho khoảng cách (không gọi OSRM)
    try:
        start_lat, start_lng = geocode(market_address)
    except ValueError:
        raise ValueError(f"Không tìm thấy tọa độ chợ: {market_address}")

    # Geocode unique addresses only (dedup để tránh rate limit)
    addr_cache: dict = {}
    points = []
    for item in delivery_addresses:
        raw = item["address"]
        key = _extract_address(raw)
        if key not in addr_cache:
            try:
                addr_cache[key] = geocode(raw)
            except ValueError:
                addr_cache[key] = None
        coords = addr_cache[key]
        if coords is None:
            continue
        lat, lng = coords
        points.append({
            "order_id": item["order_id"],
            "address": raw,
            "lat": lat,
            "lng": lng
        })

    if not points:
        return {"optimized_route": [], "total_distance_km": 0}

    # Nearest Neighbor — dùng Haversine, không gọi OSRM
    current_lat, current_lng = start_lat, start_lng
    remaining = points.copy()
    route = []
    total_distance = 0

    while remaining:
        nearest = None
        nearest_dist = float("inf")
        for point in remaining:
            dist = _haversine_km(current_lat, current_lng, point["lat"], point["lng"])
            if dist < nearest_dist:
                nearest_dist = dist
                nearest = point

        route.append({
            "order_id": nearest["order_id"],
            "address": nearest["address"],
            "lat": nearest["lat"],
            "lng": nearest["lng"],
            "distance_from_prev_km": round(nearest_dist, 2)
        })

        total_distance += nearest_dist
        current_lat, current_lng = nearest["lat"], nearest["lng"]
        remaining.remove(nearest)

    return {
        "optimized_route": route,
        "total_distance_km": round(total_distance, 2),
        "market_lat": start_lat,
        "market_lng": start_lng,
    }
