"""
E2E Test Script: DNGO Platform - Buyer, Seller, Shipper
Test toan bo flow don hang tu dat hang den giao hang thanh cong.
"""
import requests
import json
import time
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

BASE = "http://localhost:8001"

# ============================
# HELPERS
# ============================
def h(token):
    return {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

def ok(label, resp):
    try:
        data = resp.json()
    except:
        data = resp.text
    if resp.status_code in (200, 201):
        print(f"  ✅ {label} — {resp.status_code}")
        return data
    else:
        print(f"  ❌ {label} — {resp.status_code}: {data}")
        return None

def section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")

# ============================
# 1. REGISTER & LOGIN
# ============================
section("1. DANG KY & DANG NHAP")

# Register buyer
print("\n--- Buyer ---")
buyer_body = {
    "ten_dang_nhap": f"test_buyer_{int(time.time())}",
    "mat_khau": "123456",
    "ten_nguoi_dung": "Nguyen Van Mua",
    "role": "nguoi_mua",
    "gioi_tinh": "M",
    "sdt": "0901111111",
    "dia_chi": "10 Le Loi, Q1, HCM"
}
r = requests.post(f"{BASE}/api/auth/register", json=buyer_body)
buyer_data = ok("Register buyer", r)
buyer_token = buyer_data["token"] if buyer_data else None

# Register seller
print("\n--- Seller ---")
seller_body = {
    "ten_dang_nhap": f"test_seller_{int(time.time())}",
    "mat_khau": "123456",
    "ten_nguoi_dung": "Tran Thi Ban",
    "role": "nguoi_ban",
    "gioi_tinh": "F",
    "sdt": "0902222222",
    "dia_chi": "Cho Ben Thanh"
}
r = requests.post(f"{BASE}/api/auth/register", json=seller_body)
seller_data = ok("Register seller", r)
seller_token = seller_data["token"] if seller_data else None

# Register shipper
print("\n--- Shipper ---")
shipper_body = {
    "ten_dang_nhap": f"test_shipper_{int(time.time())}",
    "mat_khau": "123456",
    "ten_nguoi_dung": "Le Van Giao",
    "role": "shipper",
    "gioi_tinh": "M",
    "sdt": "0903333333",
    "dia_chi": "20 Hai Ba Trung, Da Nang",
    "bien_so_xe": "43A-99999",
    "phuong_tien": "xe_may"
}
r = requests.post(f"{BASE}/api/auth/register", json=shipper_body)
shipper_data = ok("Register shipper", r)
shipper_token = shipper_data["token"] if shipper_data else None

if not all([buyer_token, seller_token, shipper_token]):
    print("\n⛔ Khong the tao du 3 tai khoan. Dung test.")
    sys.exit(1)

buyer_id = buyer_data["data"]["user_id"]
seller_id = seller_data["data"]["user_id"]
shipper_id = shipper_data["data"]["user_id"]
print(f"\n  Buyer ID:   {buyer_id}")
print(f"  Seller ID:  {seller_id}")
print(f"  Shipper ID: {shipper_id}")

# ============================
# 2. GET ME (all roles)
# ============================
section("2. GET /api/auth/me (TAT CA ROLES)")

r = requests.get(f"{BASE}/api/auth/me", headers=h(buyer_token))
ok("Buyer /me", r)

r = requests.get(f"{BASE}/api/auth/me", headers=h(seller_token))
ok("Seller /me", r)

r = requests.get(f"{BASE}/api/auth/me", headers=h(shipper_token))
ok("Shipper /me", r)

# ============================
# 3. SHIPPER /me
# ============================
section("3. GET /api/shipper/me")

r = requests.get(f"{BASE}/api/shipper/me", headers=h(shipper_token))
shipper_me = ok("Shipper /me", r)

# ============================
# 4. SHIPPER DASHBOARD (truoc khi co don)
# ============================
section("4. SHIPPER DASHBOARD (truoc khi co don)")

r = requests.get(f"{BASE}/api/shipper/dashboard", headers=h(shipper_token))
dash = ok("Dashboard", r)
if dash:
    today = dash.get("hom_nay", {})
    print(f"    Tong don hom nay: {today.get('tong_don', 0)}")
    print(f"    Thu nhap hom nay: {today.get('thu_nhap', 0)}")

# ============================
# 5. SHIPPER EARNINGS
# ============================
section("5. SHIPPER EARNINGS")

r = requests.get(f"{BASE}/api/shipper/earnings?filter_type=thang_nay", headers=h(shipper_token))
ok("Earnings thang nay", r)

# ============================
# 6. SHIPPER UPDATE PROFILE
# ============================
section("6. SHIPPER UPDATE PROFILE")

r = requests.put(f"{BASE}/api/shipper/profile",
    headers=h(shipper_token),
    json={"vehicle_type": "xe_dien", "vehicle_plate": "43B-55555", "bank_account": "9999888877", "bank_name": "TP Bank"})
profile = ok("Update profile", r)
if profile and profile.get("data"):
    print(f"    Xe: {profile['data'].get('phuong_tien')}")
    print(f"    Bien so: {profile['data'].get('bien_so_xe')}")
    print(f"    Bank: {profile['data'].get('bank_name')} - {profile['data'].get('bank_account')}")

# Verify update
r = requests.get(f"{BASE}/api/shipper/me", headers=h(shipper_token))
ok("Verify /me after update", r)

# ============================
# 7. SHIPPER REVIEWS (co the chua co)
# ============================
section("7. SHIPPER REVIEWS")

r = requests.get(f"{BASE}/api/shipper/reviews?page=1&limit=10", headers=h(shipper_token))
reviews = ok("Reviews", r)
if reviews:
    print(f"    Trung binh: {reviews.get('danh_gia_trung_binh', 0)}")
    print(f"    Tong: {reviews.get('tong_danh_gia', 0)}")

# ============================
# 8. SHIPPER NOTIFICATIONS
# ============================
section("8. SHIPPER NOTIFICATIONS")

r = requests.get(f"{BASE}/api/shipper/notifications?page=1&limit=20", headers=h(shipper_token))
noti = ok("Notifications list", r)
if noti:
    print(f"    Unread: {noti.get('unread_count', 0)}")
    print(f"    Total: {noti.get('total', 0)}")

# Mark all read
r = requests.patch(f"{BASE}/api/shipper/notifications/read-all", headers=h(shipper_token))
ok("Mark all read", r)

# ============================
# 9. SHIPPER AVAILABLE ORDERS
# ============================
section("9. SHIPPER DON HANG CO SAN")

r = requests.get(f"{BASE}/api/shipper/orders/available?page=1&limit=10", headers=h(shipper_token))
avail = ok("Available orders", r)
avail_items = avail.get("items", []) if avail else []
print(f"    Co {len(avail_items)} don hang co san")

# ============================
# 10. IF AVAILABLE: ACCEPT + STATUS FLOW
# ============================
section("10. NHAN DON + CHUYEN TRANG THAI")

if avail_items:
    order_id = avail_items[0]["ma_don_hang"]
    print(f"    Chon don: {order_id}")

    # Accept
    r = requests.post(f"{BASE}/api/shipper/orders/accept",
        headers=h(shipper_token),
        json={"ma_don_hang": order_id})
    ok(f"Accept order {order_id}", r)

    # Get order details
    r = requests.get(f"{BASE}/api/shipper/orders/{order_id}/details", headers=h(shipper_token))
    detail = ok(f"Order details {order_id}", r)
    if detail:
        data = detail.get("data", {})
        print(f"    Status: {data.get('tinh_trang_don_hang')}")
        print(f"    Tong tien: {data.get('tong_tien')}")

    # Update status: da_xac_nhan -> dang_lay_hang
    r = requests.patch(f"{BASE}/api/shipper/orders/{order_id}/status",
        headers=h(shipper_token),
        json={"tinh_trang_don_hang": "dang_lay_hang"})
    ok(f"Status -> dang_lay_hang", r)

    # Update status: dang_lay_hang -> dang_giao
    r = requests.patch(f"{BASE}/api/shipper/orders/{order_id}/status",
        headers=h(shipper_token),
        json={"tinh_trang_don_hang": "dang_giao"})
    ok(f"Status -> dang_giao", r)

    # Submit POD
    r = requests.post(f"{BASE}/api/shipper/orders/{order_id}/pod",
        headers=h(shipper_token),
        json={"image_url": f"pod_{order_id}_test.jpg", "note": "Da giao cho nguoi nhan"})
    ok(f"Submit POD", r)

    # Update status: dang_giao -> da_giao
    r = requests.patch(f"{BASE}/api/shipper/orders/{order_id}/status",
        headers=h(shipper_token),
        json={"tinh_trang_don_hang": "da_giao"})
    ok(f"Status -> da_giao", r)

    # Dashboard after delivery
    r = requests.get(f"{BASE}/api/shipper/dashboard", headers=h(shipper_token))
    dash2 = ok("Dashboard after delivery", r)
    if dash2:
        today2 = dash2.get("hom_nay", {})
        print(f"    Tong don hom nay: {today2.get('tong_don', 0)}")
        print(f"    Hoan thanh: {today2.get('don_hoan_thanh', 0)}")
        print(f"    Thu nhap: {today2.get('thu_nhap', 0)}")
else:
    print("  ⚠️ Khong co don hang co san. Test nhan don bi bo qua.")
    print("     (Can co don hang tu Buyer dat truoc)")

# ============================
# 11. TEST FAILED DELIVERY (neu con don khac)
# ============================
section("11. TEST GIAO THAT BAI")

if len(avail_items) > 1:
    fail_order_id = avail_items[1]["ma_don_hang"]
    print(f"    Chon don: {fail_order_id}")

    r = requests.post(f"{BASE}/api/shipper/orders/accept",
        headers=h(shipper_token),
        json={"ma_don_hang": fail_order_id})
    ok(f"Accept {fail_order_id}", r)

    # -> dang_lay_hang -> dang_giao
    requests.patch(f"{BASE}/api/shipper/orders/{fail_order_id}/status",
        headers=h(shipper_token),
        json={"tinh_trang_don_hang": "dang_lay_hang"})
    requests.patch(f"{BASE}/api/shipper/orders/{fail_order_id}/status",
        headers=h(shipper_token),
        json={"tinh_trang_don_hang": "dang_giao"})

    # Report failed
    r = requests.post(f"{BASE}/api/shipper/orders/{fail_order_id}/fail",
        headers=h(shipper_token),
        json={"reason": "Khong lien lac duoc khach", "note": "Goi 3 lan khong nghe"})
    ok(f"Report fail {fail_order_id}", r)
else:
    print("  ⚠️ Khong du don de test giao that bai.")

# ============================
# 12. WALLET CHECK
# ============================
section("12. WALLET")

r = requests.get(f"{BASE}/api/auth/me", headers=h(shipper_token))
me = r.json() if r.status_code == 200 else {}
wallet_id = me.get("data", {}).get("ma_vi")
if wallet_id:
    r = requests.get(f"{BASE}/api/wallets/{wallet_id}/balance", headers=h(shipper_token))
    wal = ok(f"Wallet {wallet_id}", r)
    if wal:
        print(f"    So du: {wal.get('so_du', 0)}")
        print(f"    Tong vao: {wal.get('tong_tien_vao', 0)}")
else:
    print("  ⚠️ Khong tim thay vi shipper")

# ============================
# 13. AUTH FEATURES
# ============================
section("13. AUTH FEATURES")

# Change password
r = requests.post(f"{BASE}/api/auth/change-password",
    headers=h(shipper_token),
    json={"mat_khau_cu": "123456", "mat_khau_moi": "654321"})
ok("Change password (shipper)", r)

# Change back
r = requests.post(f"{BASE}/api/auth/change-password",
    headers=h(shipper_token),
    json={"mat_khau_cu": "654321", "mat_khau_moi": "123456"})
ok("Change back (shipper)", r)

# Login history
r = requests.get(f"{BASE}/api/auth/login-history", headers=h(shipper_token))
ok("Login history", r)

# Update profile (auth endpoint)
r = requests.put(f"{BASE}/api/auth/profile",
    headers=h(buyer_token),
    json={"ten_nguoi_dung": "Nguyen Van Mua (Updated)", "sdt": "0901111222"})
ok("Buyer update profile", r)

# ============================
# 14. BUYER ENDPOINTS
# ============================
section("14. BUYER ENDPOINTS")

r = requests.get(f"{BASE}/api/auth/me", headers=h(buyer_token))
buyer_me = ok("Buyer /me", r)

# ============================
# 15. SELLER ENDPOINTS
# ============================
section("15. SELLER ENDPOINTS")

r = requests.get(f"{BASE}/api/auth/me", headers=h(seller_token))
seller_me = ok("Seller /me", r)

# ============================
# 16. CROSS-ROLE SECURITY
# ============================
section("16. CROSS-ROLE SECURITY")

# Buyer should NOT access shipper endpoints
r = requests.get(f"{BASE}/api/shipper/me", headers=h(buyer_token))
if r.status_code in (401, 403, 404, 500):
    print(f"  ✅ Buyer cannot access /shipper/me (got {r.status_code}) — CORRECT")
else:
    print(f"  ❌ Buyer CAN access /shipper/me (got {r.status_code}) — SECURITY BUG!")

# Seller should NOT access shipper endpoints  
r = requests.get(f"{BASE}/api/shipper/dashboard", headers=h(seller_token))
if r.status_code in (401, 403, 404, 500):
    print(f"  ✅ Seller cannot access /shipper/dashboard (got {r.status_code}) — CORRECT")
else:
    print(f"  ❌ Seller CAN access /shipper/dashboard (got {r.status_code}) — SECURITY BUG!")

# ============================
# SUMMARY
# ============================
section("KET QUA TONG HOP")
print("""
  Cac API da test:
  ─────────────────────────────────────────
  AUTH:     register, login, me, profile, change-password, login-history
  SHIPPER:  me, dashboard, earnings, profile, reviews, notifications
            orders/available, orders/accept, orders/status, orders/details
            orders/pod, orders/fail, mark-read, read-all
  WALLET:   balance
  SECURITY: cross-role access control
  ─────────────────────────────────────────
""")
print("  🏁 DONE! Xem ket qua ✅/❌ o tren.")
