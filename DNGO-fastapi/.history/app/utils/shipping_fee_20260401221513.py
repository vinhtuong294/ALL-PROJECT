def calculate_shipping_fee(distance_km: float) -> int:
    if distance_km is None:
        return 0

    if distance_km <= 3:
        return 10000
    elif distance_km <= 5:
        return 15000
    else:
        extra_km = int(distance_km - 5)
        return 15000 + extra_km * 2000