import requests
import time

BASE_URL = "http://207.180.233.84:8000/api"

print("Logging in...")
loginUrl = f"{BASE_URL}/auth/login"
res = requests.post(loginUrl, json={"ten_dang_nhap": "hieunguoimua", "mat_khau": "Trinh123456@"})
token = res.json()["token"]
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

print("Fetching auth me...")
prof_res = requests.get(f"{BASE_URL}/auth/me", headers=headers)
buyer_id = prof_res.json()["data"]["buyer_id"]

print("Testing GET /api/orders/ ...")
start = time.time()
orders_res = requests.get(f"{BASE_URL}/orders/?buyer_id={buyer_id}&limit=10", headers=headers)
end = time.time()
print(f"Time taken for GET /api/orders/: {end-start:.2f} seconds. Status: {orders_res.status_code}")
if orders_res.status_code == 200:
    data = orders_res.json()
    if data.get("items"):
        order_id = data["items"][0]["ma_don_hang"]
        print(f"Found order: {order_id}")
        start = time.time()
        detail_res = requests.get(f"{BASE_URL}/orders/{order_id}", headers=headers)
        end = time.time()
        print(f"Time taken for GET /orders/{order_id}: {end-start:.2f} seconds. Status: {detail_res.status_code}")
        if detail_res.status_code == 500:
            print("Detail Error Response:", detail_res.text)
    else:
        print("No orders found in items list")

