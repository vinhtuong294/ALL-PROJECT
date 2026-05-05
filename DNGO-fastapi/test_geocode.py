import re
from app.utils.distance import geocode

regex = r'^(Số|Lô|Kiệt|K|Ngõ|Hẻm)?\s*\d+[a-zA-Z]?((/|-)\d+[a-zA-Z]?)*\s*,?\s*'
address = "50, Đường Văn Tiến Dũng, Phường Hòa Xuân, Thành phố Đà Nẵng"
no_house = re.sub(regex, '', address, flags=re.IGNORECASE).strip()

print(f"Original: {address}")
print(f"Stripped: {no_house}")

try:
    lat, lng = geocode(address)
    print(f"Geocoded Original: {lat}, {lng}")
except Exception as e:
    print(f"Original Geocode failed: {e}")

try:
    lat, lng = geocode(no_house)
    print(f"Geocoded Stripped: {lat}, {lng}")
except Exception as e:
    print(f"Stripped Geocode failed: {e}")
