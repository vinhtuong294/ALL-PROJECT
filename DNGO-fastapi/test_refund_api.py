import requests
import json

BASE_URL = "http://127.0.0.1:8000"

def test():
    # Login
    print("Logging in...")
    login_data = {
        "sdt": "0987654321",
        "mat_khau": "123456"
    }
    r = requests.post(f"{BASE_URL}/api/auth/login", json=login_data)
    print("Login response:", r.status_code, r.text)
    if r.status_code != 200:
        return
    token = r.json()["access_token"]
    buyer_id = r.json()["user_id"]
    
    # Get orders
    headers = {"Authorization": f"Bearer {token}"}
    r = requests.get(f"{BASE_URL}/api/orders/?buyer_id={buyer_id}", headers=headers)
    orders = r.json().get("items", [])
    
    order_id = "3579d7f2-7"  # from subagent
    # Or find one
    for o in orders:
        if o["tinh_trang_don_hang"] == "da_giao":
            order_id = o["ma_don_hang"]
            break
            
    print(f"Testing refund for order {order_id}...")
    # Get order details
    r = requests.get(f"{BASE_URL}/api/orders/{order_id}", headers=headers)
    if r.status_code != 200:
        print("Failed to get order details", r.text)
        return
        
    details = r.json()["data"]
    items = []
    for item in details["items"]:
        if item["detail_status"] not in ["cho_duyet", "da_duyet", "hoan_hang", "tu_choi"]:
            items.append({
                "ingredient_id": item["ma_nguyen_lieu"],
                "stall_id": item["ma_gian_hang"],
                "reason": "Sản phẩm không giống mô tả"
            })
            
    if not items:
        print("No eligible items found")
        return
        
    # Request refund
    payload = {
        "order_id": order_id,
        "items": items
    }
    print("Payload:", json.dumps(payload, indent=2))
    r = requests.post(f"{BASE_URL}/api/buyer/refund", json=payload, headers=headers)
    print("Refund response:", r.status_code, r.text)

if __name__ == "__main__":
    test()
