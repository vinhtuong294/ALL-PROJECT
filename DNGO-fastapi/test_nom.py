import os
from app.utils.distance import _geocode_nominatim

address = "50, Đường Văn Tiến Dũng, Phường Hòa Xuân, Thành phố Đà Nẵng"
try:
    lat, lng = _geocode_nominatim(address)
    print(f"Nominatim Original: {lat}, {lng}")
except Exception as e:
    print(f"Nominatim Original failed: {e}")

try:
    lat, lng = _geocode_nominatim("Đường Văn Tiến Dũng, Phường Hòa Xuân, Thành phố Đà Nẵng")
    print(f"Nominatim Stripped: {lat}, {lng}")
except Exception as e:
    print(f"Nominatim Stripped failed: {e}")
