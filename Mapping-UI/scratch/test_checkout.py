import requests
import json
import uuid

BASE_URL = "http://207.180.233.84:8000/api"

def main():
    print("Logging in user...")
    loginUrl = f"{BASE_URL}/auth/login"
    res = requests.post(loginUrl, json={
        "ten_dang_nhap": "hieunguoimua",
        "mat_khau": "Trinh123456@"
    }, headers={"Content-Type": "application/json", "Accept": "application/json"})
    
    if res.status_code not in (200, 201):
        print("Login failed:", res.text)
        return
        
    res_data = res.json()
    token = res_data["token"]
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    print("Token fetched")
    
    print("Fetching auth me...")
    prof_res = requests.get(f"{BASE_URL}/auth/me", headers=headers)
    print("Profile fetched")
    user_id = prof_res.json()["data"]["buyer_id"]

    print("Fetching products...")
    prod_res = requests.get(f"{BASE_URL}/buyer/nguyen-lieu?limit=5", headers=headers)
    if prod_res.status_code != 200:
        print("Fetch products failed", prod_res.text)
        return
    prods = prod_res.json()
    if not prods:
        print("No products found")
        return
    
    ingredient = prods["data"][0]
    ingredient_id = ingredient["ma_nguyen_lieu"]
    
    det_res = requests.get(f"{BASE_URL}/buyer/nguyen-lieu/{ingredient_id}", headers=headers)
    det = det_res.json()
    
    if "sellers" not in det or len(det["sellers"]["data"]) == 0:
        print("No stall for this ingredient")
        return
        
    stall_id = det["sellers"]["data"][0]["ma_gian_hang"]

    add_res = requests.post(f"{BASE_URL}/buyer/cart/items?buyer_id={user_id}", headers=headers, json={
        "ingredient_id": ingredient_id,
        "stall_id": stall_id,
        "cart_quantity": 1
    })
    print("Add to cart done")

    custom_address = "Số 42 Đường Hạnh Phúc, Quận 9"
    
    print("Checking out...")
    import time
    start_time = time.time()
    checkout_res = requests.post(f"{BASE_URL}/buyer/cart/checkout?buyer_id={user_id}", headers=headers, json={
        "selected_items": [
            {"ingredient_id": ingredient_id, "stall_id": stall_id}
        ],
        "payment_method": "tien_mat",
        "recipient": {
            "name": "Test User",
            "phone": "0912345678",
            "address": custom_address,
            "notes": ""
        },
        "delivery_address": custom_address,
        "time_slot_id": "KG10"
    })
    end_time = time.time()
    print(f"Checkout response time: {end_time - start_time:.2f} seconds")
    
    if checkout_res.status_code not in (200, 201):
         print("Checkout failed with status:", checkout_res.status_code)
         print(checkout_res.text)
         return
         
    checkout_data = checkout_res.json()
    # It might have ma_don_hang in root or data list
    ma_don_hang = None
    if "ma_don_hang" in checkout_data:
         ma_don_hang = checkout_data["ma_don_hang"]
    elif "data" in checkout_data and len(checkout_data["data"]) > 0:
         ma_don_hang = checkout_data["data"][0].get("ma_don_hang", "")
    elif "orders" in checkout_data and len(checkout_data["orders"]) > 0:
         ma_don_hang = checkout_data["orders"][0].get("ma_don_hang", "")
         
    if not ma_don_hang:
         print("No ma_don_hang found")
         return
         
    print(f"Fetching order details for {ma_don_hang}...")
    order_res = requests.get(f"{BASE_URL}/buyer/orders/{ma_don_hang}", headers=headers)
    print("Order details:", order_res.text)
    
if __name__ == '__main__':
    main()
