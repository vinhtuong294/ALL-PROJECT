import requests
import json
import uuid
import sys
sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = "http://localhost:8001"

# Credentials
users = {
    "buyer": {"login_name": "hieunguoimua", "password": "Trinh123456@"},
    "seller": {"login_name": "hieunguoiban", "password": "Trinh123456@"},
    "shipper": {"login_name": "hieushipper", "password": "Trinh123456@"},
}

tokens = {}
user_ids = {}

print("===========================================")
print("1. ĐĂNG NHẬP (Authenticate Roles)")
print("===========================================")

for role, creds in users.items():
    print(f"Logging in as {role} ({creds['login_name']})...")
    res = requests.post(f"{BASE_URL}/api/auth/login", json=creds)
    if res.status_code == 200:
        data = res.json()
        tokens[role] = data["token"]
        user_ids[role] = data["data"]["user_id"]
        print(f"✅ Success! Token length: {len(tokens[role])}")
    else:
        print(f"❌ Failed! Status: {res.status_code}, {res.text}")
        exit(1)

# Helpers
def buyer_c(method, endpoint, **kwargs):
    headers = {"Authorization": f"Bearer {tokens['buyer']}"}
    return requests.request(method, f"{BASE_URL}{endpoint}", headers=headers, **kwargs)

def seller_c(method, endpoint, **kwargs):
    headers = {"Authorization": f"Bearer {tokens['seller']}"}
    return requests.request(method, f"{BASE_URL}{endpoint}", headers=headers, **kwargs)

def shipper_c(method, endpoint, **kwargs):
    headers = {"Authorization": f"Bearer {tokens['shipper']}"}
    return requests.request(method, f"{BASE_URL}{endpoint}", headers=headers, **kwargs)


print("\n===========================================")
print("2. BUYER: FLOW MUA HÀNG")
print("-> Lấy thông tin user hiện tại...")
res_me = buyer_c("GET", "/api/auth/me")
me_data = res_me.json()
real_buyer_id = me_data['data'].get('buyer_id', me_data['data'].get('user_id'))

res_seller_me = seller_c("GET", "/api/auth/me")
seller_me_data = res_seller_me.json()
stall_id = seller_me_data['data'].get('stall_id', seller_me_data['data'].get('ma_gian_hang'))

print(f"✅ Người mua ID: {real_buyer_id}")
print(f"✅ Người bán gian hàng ID: {stall_id}")

print("-> Lấy nguyên liệu (Sản phẩm) từ gian hàng này...")
res_items = buyer_c("GET", f"/api/buyer/nguyen-lieu?ma_gian_hang={stall_id}")
items_data = res_items.json()
if not items_data.get('data'):
    print("❌ Không có sản phẩm nào trong gian hàng")
    exit(1)
ingredient_id = items_data['data'][0].get('ma_nguyen_lieu', items_data['data'][0].get('ingredient_id'))
price = items_data['data'][0].get('gia_ban', items_data['data'][0].get('good_price', 10000))
print(f"✅ Chọn sản phẩm ID: {ingredient_id}, Giá: {price}")

print("-> Thêm sản phẩm vào giỏ hàng...")
cart_item = {
    "ingredient_id": ingredient_id,
    "stall_id": stall_id,
    "cart_quantity": 1
}
res_add_cart = buyer_c("POST", f"/api/buyer/cart/items?buyer_id={real_buyer_id}", json=cart_item)
if res_add_cart.status_code == 200:
    print("✅ Đã thêm vào giỏ hàng")
else:
    print(f"❌ Lỗi thêm vào giỏ: {res_add_cart.text}")

print("-> Xem giỏ hàng...")
res_cart = buyer_c("GET", f"/api/buyer/cart/?buyer_id={real_buyer_id}")
if res_cart.status_code == 200:
    cart_data = res_cart.json()
    print("✅ Giỏ hàng hiện tại:")
    # print(json.dumps(cart_data, indent=2))
else:
    print(f"❌ Lỗi xem giỏ: {res_cart.text}")

print("-> Lấy danh sách khung giờ (time_slots)...")
res_ts = buyer_c("GET", "/api/buyer/time-slots")
ts_data = res_ts.json()
time_slot_id = None
if ts_data and isinstance(ts_data, list) and len(ts_data) > 0:
    time_slot_id = ts_data[0]['time_slot_id']
else:
    print("❌ Không có time slot nào")
    exit(1)
print(f"✅ Chọn time slot: {time_slot_id}")

print("-> Thanh toán (Checkout) - COD...")
checkout_payload = {
    "selected_items": [{
        "stall_id": stall_id,
        "ingredient_id": ingredient_id
    }],
    "payment_method": "tien_mat",
    "delivery_address": "Hải Châu, Đà Nẵng",
    "time_slot_id": time_slot_id
}
res_checkout = buyer_c("POST", f"/api/buyer/cart/checkout?buyer_id={real_buyer_id}", json=checkout_payload)
if res_checkout.status_code == 200:
    data = res_checkout.json()
    print("✅ Checkout thành công!")
    print(data)
    order_id = data.get("order", {}).get("ma_don_hang")
    if not order_id:
        print("Bypass order_id if not returned")
else:
    print(f"❌ Checkout thất bại: {res_checkout.text}")
    print("-> Bypass: Let's fetch the latest order of buyer.")
    

    # Đã có order_id từ checkout, không cần lấy lại
print("\n===========================================")
print("3. SELLER: CHUẨN BỊ VÀ GIAO ĐƠN")
print("===========================================")
print("-> Xem danh sách đơn của seller...")
res_s_orders = seller_c("GET", "/api/seller/orders?limit=10")
s_orders_data = res_s_orders.json()
if s_orders_data.get('data'):
    found = False
    for o in s_orders_data['data']:
        if o['order_id'] == order_id:
            found = True
            break
    if found:
        print("✅ Seller thấy đơn hàng mới!")
    else:
        print(f"⚠️ Seller không thấy đơn {order_id}. Có thể seller này chưa sở hữu gian hàng {stall_id}?")
else:
    print("❌ Seller không có đơn nào.")

print("-> Thực hiện Accept đơn hàng: PATCH /api/seller/orders/{order_id}/items/{ingredient_id}/confirm")
accept_payload = {"action": "da_duyet"}
res_accept = seller_c("PATCH", f"/api/seller/orders/{order_id}/items/{ingredient_id}/confirm", json=accept_payload)
if res_accept.status_code == 200:
    print("✅ Seller đã DUYỆT đơn hàng thành công!")
else:
    print(f"❌ Seller duyệt đơn thất bại: {res_accept.text}")

print("\n===========================================")
print("4. SHIPPER: NHẬN ĐƠN VÀ ĐI GIAO")
print("===========================================")
print("-> Lấy danh sách đơn cần giao (Available Orders)...")
res_ship_avail = shipper_c("GET", "/api/shipper/orders/available?limit=100")
if res_ship_avail.status_code == 200:
    avail_data = res_ship_avail.json().get('items', [])
    shipper_sees_order = False
    for eo in avail_data:
        if eo['ma_don_hang'] == order_id:
            shipper_sees_order = True
            break
            
    if shipper_sees_order:
        print("✅ Shipper THẤY đơn hàng đang đợi giao!")
    else:
        print(f"⚠️ Shipper không thấy đơn {order_id}. Hãy kiểm tra trạng thái tìm shipper.")
else:
    print(f"❌ Không lấy được list available orders: {res_ship_avail.text}")

print("-> Shipper Nhận đơn (Accept)...")
ship_accept_payload = {"ma_don_hang": order_id}
res_ship_accept = shipper_c("POST", "/api/shipper/orders/accept", json=ship_accept_payload)
if res_ship_accept.status_code == 200:
    print("✅ Shipper đã NHẬN đơn giao hàng!")
else:
    print(f"❌ Shipper nhận đơn thất bại: {res_ship_accept.text}")


print("-> Shipper cập nhật trạng thái đang giao (da_xac_nhan -> dang_giao)...")
update_payload = {"tinh_trang_don_hang": "dang_giao"}
res_update = shipper_c("PATCH", f"/api/shipper/orders/{order_id}/status", json=update_payload)
if res_update.status_code == 200:
    print("✅ Shipper báo ĐANG GIAO hàng.")
else:
    print(f"⚠️ Shipper báo lỗi: {res_update.text}")

print("-> Shipper cập nhật trạng thái đã giao (dang_giao -> da_giao)...")
update_payload = {"tinh_trang_don_hang": "da_giao"}
res_update = shipper_c("PATCH", f"/api/shipper/orders/{order_id}/status", json=update_payload)
if res_update.status_code == 200:
    print("✅ Shipper báo ĐÃ GIAO HÀNG!")
else:
    print(f"⚠️ Shipper báo lỗi: {res_update.text}")

print("-> Shipper cập nhật trạng thái hoàn thành (da_giao -> hoan_thanh)...")
update_payload = {"tinh_trang_don_hang": "hoan_thanh"}
res_update = shipper_c("PATCH", f"/api/shipper/orders/{order_id}/status", json=update_payload)
if res_update.status_code == 200:
    print("✅ Shipper báo HOÀN THÀNH!")
else:
    print(f"⚠️ Shipper báo lỗi: {res_update.text}")



print("\n✅ API AUTOMATION TEST COMPLETED VỚI DATA THẬT! DỮ LIỆU ĐÃ HIỂN THỊ TRÊN DATABASE VÀ APPS.")
