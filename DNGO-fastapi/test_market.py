#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Test toàn diện Market Management - Backend API + Logic
"""
import sys, json, urllib.request, urllib.error
sys.stdout.reconfigure(encoding='utf-8')

BASE = 'http://localhost:8000'
TOKEN = None
ISSUES = []
PASSES = []
FAIL = 0

def make_req(method, path, data=None, token=None, label=None):
    global ISSUES, PASSES, FAIL
    url = BASE + path
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    body = json.dumps(data).encode() if data else None
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        resp = urllib.request.urlopen(req, timeout=10)
        result = json.loads(resp.read().decode('utf-8'))
        print(f"  ✅ PASS [{resp.status}] {label or path}")
        PASSES.append(label or path)
        return result, resp.status
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8')
        print(f"  ❌ FAIL [{e.code}] {label or path}")
        print(f"         => {body[:150]}")
        FAIL += 1
        ISSUES.append({"label": label or path, "code": e.code, "body": body[:150]})
        return None, e.code
    except Exception as e:
        print(f"  💥 ERROR {label or path} => {e}")
        FAIL += 1
        ISSUES.append({"label": label or path, "error": str(e)})
        return None, 0

def section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print('='*60)

# ─────────────────────────────────────────────────────────────
# 1. SECURITY: Unauthenticated Access
# ─────────────────────────────────────────────────────────────
section("1. BẢO MẬT: Endpoint không cần token (phải reject)")

protected_endpoints = [
    ('GET', '/api/quan-ly-cho/dashboard'),
    ('GET', '/api/quan-ly-cho/dashboard-v2'),
    ('GET', '/api/quan-ly-cho/tieu-thuong'),
    ('GET', '/api/quan-ly-cho/thu-thue'),
    ('GET', '/api/quan-ly-cho/loai-hang-hoa'),
    ('GET', '/api/quan-ly-cho/pending-sellers'),
]
for method, path in protected_endpoints:
    r, s = make_req(method, path, label=f"{method} {path} (no auth)")
    if s not in (401, 403):
        ISSUES.append({"bug": f"SECURITY: {path} không bảo vệ (got {s})"})
    else:
        # Override as PASS for security test
        ISSUES.pop()  # Remove from issues since fail IS expected here
        PASSES.append(f"Security: {path} → {s} ✓")
        FAIL -= 1

# Public endpoint - should be accessible
r, s = make_req('GET', '/api/quan-ly-cho/stalls/map', label="GET /stalls/map (public, no auth)")
if s != 200:
    ISSUES.append({"bug": "Map stalls nên public nhưng không trả 200"})

# ─────────────────────────────────────────────────────────────
# 2. LOGIN
# ─────────────────────────────────────────────────────────────
section("2. LOGIN - Lấy token quản lý chợ")

# Login response: {"data": {...}, "token": "..."}
candidates = ['quanlycho', '905123734', 'hieuquanly', '777352787']
for login_name in candidates:
    r, s = make_req('POST', '/api/auth/login',
        data={'login_name': login_name, 'password': '123456'},
        label=f"Login [{login_name}]")
    if r:
        TOKEN = r.get('token') or r.get('access_token')
        role = r.get('data', {}).get('role') or r.get('role')
        user_name = r.get('data', {}).get('user_name') or r.get('user_name')
        print(f"     → role={role}, user={user_name}, token={'OK' if TOKEN else 'MISSING!'}")
        if not TOKEN:
            ISSUES.append({"bug": "Login OK nhưng 'token' field không có trong response", "got_keys": list(r.keys())})
        elif role != 'quan_ly_cho':
            ISSUES.append({"bug": f"Login OK nhưng role={role}, expect quan_ly_cho"})
        break

if not TOKEN:
    print("  💥 Không login được - dừng test authenticated endpoints")
    section("📊 KẾT QUẢ SỚM")
    print(f"  ✅ PASS: {len(PASSES)}")
    print(f"  ❌ FAIL: {FAIL}")
    sys.exit(1)

# ─────────────────────────────────────────────────────────────
# 3. DASHBOARD
# ─────────────────────────────────────────────────────────────
section("3. DASHBOARD")
r, s = make_req('GET', '/api/quan-ly-cho/dashboard', token=TOKEN, label="GET /dashboard")
if r:
    required = ['manager_name', 'market_name', 'district_name', 'active_merchants',
                'total_stalls', 'orders_today', 'monthly_tax_revenue', 'pending_tax_stalls']
    missing = [k for k in required if k not in r]
    if missing:
        ISSUES.append({"bug": "Dashboard thiếu fields", "missing": missing})
        print(f"     ⚠️  Thiếu fields: {missing}")
    else:
        print(f"     → market={r['market_name']}, district={r['district_name']}")
        print(f"     → stalls={r['total_stalls']}, merchants={r['active_merchants']}")
        print(f"     → orders_today={r['orders_today']}, tax={r['monthly_tax_revenue']:,.0f}đ")
        print(f"     → pending_tax={r['pending_tax_stalls']}")
        # Logic check: pending_tax <= total_stalls
        if r['pending_tax_stalls'] > r['total_stalls']:
            ISSUES.append({"bug": "pending_tax_stalls > total_stalls - không hợp lý!"})

r2, s2 = make_req('GET', '/api/quan-ly-cho/dashboard-v2', token=TOKEN, label="GET /dashboard-v2")
if r2:
    required2 = ['total_stalls', 'open_stalls', 'closed_stalls', 'categories', 'stalls']
    missing2 = [k for k in required2 if k not in r2]
    if missing2:
        ISSUES.append({"bug": "Dashboard-v2 thiếu fields", "missing": missing2})
    else:
        print(f"     → total={r2['total_stalls']}, open={r2['open_stalls']}, closed={r2['closed_stalls']}")
        print(f"     → categories={len(r2['categories'])}, stall_list={len(r2['stalls'])}")
        # Logic: open + closed == total
        if r2['open_stalls'] + r2['closed_stalls'] != r2['total_stalls']:
            ISSUES.append({
                "bug": f"open({r2['open_stalls']}) + closed({r2['closed_stalls']}) != total({r2['total_stalls']})"
            })

# ─────────────────────────────────────────────────────────────
# 4. DANH MỤC HÀNG HÓA
# ─────────────────────────────────────────────────────────────
section("4. DANH MỤC LOẠI HÀNG HÓA")
r, s = make_req('GET', '/api/quan-ly-cho/loai-hang-hoa', token=TOKEN, label="GET /loai-hang-hoa")
if r and r.get('data'):
    cats = r['data']
    print(f"     → {len(cats)} categories: {[c.get('ma') for c in cats]}")
    expected = {'TH', 'RC', 'HS', 'GV', 'KH'}
    actual = {c.get('ma') for c in cats}
    if expected != actual:
        ISSUES.append({"bug": f"Categories mismatch: expected={expected}, got={actual}"})
    # Check each has 'ma' and 'ten'
    for c in cats:
        if 'ma' not in c or 'ten' not in c:
            ISSUES.append({"bug": f"Category item thiếu 'ma'/'ten': {c}"})
            break

# ─────────────────────────────────────────────────────────────
# 5. TIỂU THƯƠNG
# ─────────────────────────────────────────────────────────────
section("5. DANH SÁCH TIỂU THƯƠNG")
r, s = make_req('GET', '/api/quan-ly-cho/tieu-thuong?limit=5', token=TOKEN, label="GET /tieu-thuong")
merchant_id = None
stall_id_from_merchant = None
if r:
    meta = r.get('meta', {})
    print(f"     → total={meta.get('total')}, pages={meta.get('total_pages')}")
    data = r.get('data', [])
    if data:
        first = data[0]
        merchant_id = first.get('ma_nguoi_dung')
        stall_id_from_merchant = first.get('ma_gian_hang')
        print(f"     → 1st: id={first.get('ma_nguoi_dung')} | stall={first.get('ma_gian_hang')} | trang_thai={first.get('tinh_trang')} | fee={first.get('fee_status')}")
        
        required_fields = ['ma_nguoi_dung', 'ten_nguoi_dung', 'ma_gian_hang',
                           'ten_gian_hang', 'vi_tri_gian_hang', 'tinh_trang', 'fee_status']
        missing = [k for k in required_fields if k not in first]
        if missing:
            ISSUES.append({"bug": "Tieu thuong item thiếu field", "missing": missing})

        # Logic check: tinh_trang values
        valid_tinh_trang = {'hoat_dong', 'tam_nghi', 'chua_co_gian_hang'}
        for m in data:
            tt = m.get('tinh_trang')
            if tt not in valid_tinh_trang:
                ISSUES.append({"bug": f"tinh_trang '{tt}' không hợp lệ (allow: {valid_tinh_trang})"})
                break
        
        # Logic check: fee_status values
        valid_fee = {'da_nop', 'chua_nop', None}
        for m in data:
            fs = m.get('fee_status')
            if fs not in valid_fee:
                ISSUES.append({"bug": f"fee_status '{fs}' không hợp lệ"})
                break

# Search test
r, s = make_req('GET', '/api/quan-ly-cho/tieu-thuong?search=nguyen&limit=5',
                token=TOKEN, label="GET /tieu-thuong?search=nguyen")
if r and r.get('data') is not None:
    print(f"     → search='nguyen' found {r.get('meta', {}).get('total')} results")

# Status filter
r_hd, s_hd = make_req('GET', '/api/quan-ly-cho/tieu-thuong?status=hoat_dong',
                       token=TOKEN, label="GET /tieu-thuong?status=hoat_dong")
r_tn, s_tn = make_req('GET', '/api/quan-ly-cho/tieu-thuong?status=tam_nghi',
                       token=TOKEN, label="GET /tieu-thuong?status=tam_nghi")
if r_hd and r_tn:
    print(f"     → hoat_dong={r_hd.get('meta', {}).get('total')}, tam_nghi={r_tn.get('meta', {}).get('total')}")

# ─────────────────────────────────────────────────────────────
# 6. CHI TIẾT TIỂU THƯƠNG
# ─────────────────────────────────────────────────────────────
section("6. CHI TIẾT TIỂU THƯƠNG")
if merchant_id:
    r, s = make_req('GET', f'/api/quan-ly-cho/tieu-thuong/{merchant_id}',
                    token=TOKEN, label=f"GET /tieu-thuong/{merchant_id}")
    if r and r.get('data'):
        d = r['data']
        required = ['ma_nguoi_dung', 'ten_dang_nhap', 'ten_nguoi_dung',
                    'gioi_tinh', 'sdt', 'dia_chi', 'tinh_trang']
        missing = [k for k in required if k not in d]
        if missing:
            ISSUES.append({"bug": "Tieu thuong detail thiếu field", "missing": missing})
        else:
            print(f"     → {d['ten_nguoi_dung']} | sdt={d['sdt']} | gioi_tinh={d['gioi_tinh']}")
            if d.get('gian_hang'):
                gh = d['gian_hang']
                print(f"     → stall={gh.get('ma_gian_hang')} | vi_tri={gh.get('vi_tri')}")
                if gh.get('vi_tri_gian_hang'):
                    print(f"     → grid: col={gh['vi_tri_gian_hang'].get('cot')}, row={gh['vi_tri_gian_hang'].get('hang')}")

# 404 test  
r, s = make_req('GET', '/api/quan-ly-cho/tieu-thuong/NONEXISTENT99',
                token=TOKEN, label="GET /tieu-thuong/NONEXISTENT (expect 404)")
if s != 404:
    ISSUES.append({"bug": f"Tieu thuong invalid ID phải 404, got {s}"})
else:
    FAILS_before = FAIL
    FAIL -= 1  # This "fail" is expected

# ─────────────────────────────────────────────────────────────
# 7. THU THUẾ
# ─────────────────────────────────────────────────────────────
section("7. THU THUẾ GIAN HÀNG")
r, s = make_req('GET', '/api/quan-ly-cho/thu-thue', token=TOKEN, label="GET /thu-thue (tháng hiện tại)")
fee_id = None
fee_id_chua_nop = None
if r:
    meta = r.get('meta', {})
    print(f"     → month={meta.get('month')}, total={meta.get('total')}, collected={r.get('total_collected', 0):,.0f}đ")
    data = r.get('data', [])
    if data:
        for item in data:
            if item.get('fee_id') and item.get('fee_status') == 'da_nop' and not fee_id:
                fee_id = item['fee_id']
            if item.get('fee_id') and item.get('fee_status') == 'chua_nop' and not fee_id_chua_nop:
                fee_id_chua_nop = item['fee_id']

        first = data[0]
        print(f"     → 1st: stall={first.get('stall_id')} | user={first.get('user_name')} | fee={first.get('fee'):,.0f}đ | status={first.get('fee_status')}")
        
        required = ['stall_id', 'stall_name', 'user_name', 'fee', 'fee_status', 'fee_id']
        missing = [k for k in required if k not in first]
        if missing:
            ISSUES.append({"bug": "StallFee item thiếu field", "missing": missing})
        
        # Logic check: total_collected chỉ tính da_nop
        paid_sum = sum(float(i.get('fee', 0)) for i in data if i.get('fee_status') == 'da_nop')
        if abs(paid_sum - r.get('total_collected', 0)) > 0.01 and meta.get('total') <= len(data):
            ISSUES.append({
                "bug": f"total_collected ({r['total_collected']}) != sum of da_nop ({paid_sum:.2f})"
            })

# Filter by status
r_paid, s = make_req('GET', '/api/quan-ly-cho/thu-thue?status=da_nop',
                     token=TOKEN, label="GET /thu-thue?status=da_nop")
r_unpaid, s = make_req('GET', '/api/quan-ly-cho/thu-thue?status=chua_nop',
                       token=TOKEN, label="GET /thu-thue?status=chua_nop")
if r_paid and r_unpaid:
    paid_c = r_paid.get('meta', {}).get('total', 0)
    unpaid_c = r_unpaid.get('meta', {}).get('total', 0)
    print(f"     → da_nop={paid_c}, chua_nop={unpaid_c}")
    # Logic: Verify filters work
    if r_paid.get('data'):
        bad = [i for i in r_paid['data'] if i.get('fee_status') != 'da_nop']
        if bad:
            ISSUES.append({"bug": f"Filter da_nop trả about item không đúng status: {len(bad)} items"})
    if r_unpaid.get('data'):
        bad = [i for i in r_unpaid['data'] if i.get('fee_status') == 'da_nop']
        if bad:
            ISSUES.append({"bug": f"Filter chua_nop trả item đã nộp: {len(bad)} items"})

# Month filter
r, s = make_req('GET', '/api/quan-ly-cho/thu-thue?month=2025-01',
                token=TOKEN, label="GET /thu-thue?month=2025-01")
if r:
    print(f"     → 2025-01: total={r.get('meta', {}).get('total')}")

# ─────────────────────────────────────────────────────────────
# 8. CHI TIẾT PHÍ
# ─────────────────────────────────────────────────────────────
section("8. CHI TIẾT PHÍ GIAN HÀNG")
if fee_id:
    r, s = make_req('GET', f'/api/quan-ly-cho/thu-thue/{fee_id}',
                    token=TOKEN, label=f"GET /thu-thue/{fee_id} (da_nop)")
    if r and r.get('data'):
        d = r['data']
        required = ['fee_id', 'stall_id', 'stall_name', 'user_name', 'address', 'fee', 'fee_status', 'month']
        missing = [k for k in required if k not in d]
        if missing:
            ISSUES.append({"bug": "StallFee detail thiếu field", "missing": missing})
        else:
            print(f"     → {d['stall_name']} | user={d['user_name']} | fee={d['fee']:,.0f}đ | month={d['month']}")
else:
    print("  ⚠️  Không có fee_id da_nop (skip detail test)")

# Invalid fee_id
r, s = make_req('GET', '/api/quan-ly-cho/thu-thue/FE_INVALID_0000',
                token=TOKEN, label="GET /thu-thue/INVALID (expect 404)")
if s != 404:
    ISSUES.append({"bug": f"Fee detail invalid ID phải 404, got {s}"})
else:
    FAIL -= 1

# ─────────────────────────────────────────────────────────────
# 9. XÁC NHẬN THU THUẾ
# ─────────────────────────────────────────────────────────────
section("9. XÁC NHẬN THU THUẾ")
if fee_id_chua_nop:
    print(f"  Testing confirm for fee_id={fee_id_chua_nop} (chua_nop)...")
    r, s = make_req('POST', f'/api/quan-ly-cho/thu-thue/{fee_id_chua_nop}/xac-nhan',
        data={'payment_method': 'Tiền mặt', 'amount': 500000.0, 'note': 'Test payment'},
        token=TOKEN, label=f"POST /thu-thue/{fee_id_chua_nop}/xac-nhan")
    if r and r.get('success'):
        print(f"     → success: {r.get('message')}")
        # Verify it's now da_nop
        r2, s2 = make_req('GET', f'/api/quan-ly-cho/thu-thue/{fee_id_chua_nop}',
                          token=TOKEN, label=f"Verify fee after confirm (expect da_nop)")
        if r2 and r2.get('data', {}).get('fee_status') != 'da_nop':
            ISSUES.append({"bug": "Sau khi confirm, fee_status vẫn không phải da_nop"})
        # Restore to chua_nop if needed (skip for now)
else:
    print("  ⚠️  Không có chua_nop fee để test confirm")

# Confirm invalid fee
r, s = make_req('POST', '/api/quan-ly-cho/thu-thue/INVALID_FEE/xac-nhan',
    data={'payment_method': 'Tiền mặt', 'amount': 1000, 'note': ''},
    token=TOKEN, label="POST /thu-thue/INVALID/xac-nhan (expect 404)")
if s != 404:
    ISSUES.append({"bug": f"Confirm invalid fee_id phải 404, got {s}"})
else:
    FAIL -= 1

# ─────────────────────────────────────────────────────────────
# 10. PENDING SELLERS
# ─────────────────────────────────────────────────────────────
section("10. PENDING SELLERS")
r, s = make_req('GET', '/api/quan-ly-cho/pending-sellers', token=TOKEN, label="GET /pending-sellers")
pending_user_id = None
if r:
    meta = r.get('meta', {})
    print(f"     → total pending = {meta.get('total')}")
    if r.get('data'):
        pending_user_id = r['data'][0].get('user_id')
        first = r['data'][0]
        required = ['user_id', 'user_name', 'phone', 'address', 'approval_status']
        missing = [k for k in required if k not in first]
        if missing:
            ISSUES.append({"bug": "Pending seller thiếu field", "missing": missing})
        # Logic: approval_status phải là 0 (chưa duyệt)
        bad = [u for u in r['data'] if u.get('approval_status') != 0]
        if bad:
            ISSUES.append({"bug": f"{len(bad)} pending sellers có approval_status != 0"})

# Approve invalid user
r, s = make_req('PATCH', '/api/quan-ly-cho/approve-seller/INVALID_ID',
                token=TOKEN, label="PATCH /approve-seller/INVALID (expect 404)")
if s != 404:
    ISSUES.append({"bug": f"Approve invalid user phải 404, got {s}"})
else:
    FAIL -= 1

# ─────────────────────────────────────────────────────────────
# 11. BẢN ĐỒ GIAN HÀNG
# ─────────────────────────────────────────────────────────────
section("11. BẢN ĐỒ GIAN HÀNG")
r, s = make_req('GET', '/api/quan-ly-cho/stalls/map', label="GET /stalls/map (public)")
stall_id = None
if r and r.get('data'):
    stalls = r['data']
    print(f"     → {len(stalls)} gian hàng trên bản đồ")
    if stalls:
        stall_id = stalls[0].get('stall_id')
        first = stalls[0]
        required = ['stall_id', 'ten_gian_hang', 'nguoi_ban', 'x_col', 'y_row', 'loai_hang', 'trang_thai', 'sdt']
        missing = [k for k in required if k not in first]
        if missing:
            ISSUES.append({"bug": "Map stall thiếu field", "missing": missing})
        else:
            print(f"     → 1st: {first.get('ten_gian_hang')} | ({first.get('x_col')},{first.get('y_row')}) | {first.get('trang_thai')}")
        
        # Logic: trang_thai chỉ có thể là 'mo_cua' / 'dong_cua'
        valid_status = {'mo_cua', 'dong_cua'}
        bad_status = [s for s in stalls if s.get('trang_thai') not in valid_status]
        if bad_status:
            ISSUES.append({"bug": f"{len(bad_status)} stalls có trang_thai không hợp lệ"})

# ─────────────────────────────────────────────────────────────
# 12. CẬP NHẬT TRẠNG THÁI GIAN HÀNG
# ─────────────────────────────────────────────────────────────
section("12. CẬP NHẬT TRẠNG THÁI GIAN HÀNG")
if stall_id:
    # Get current status
    current_status = None
    if r and r.get('data'):
        for s_data in r['data']:
            if s_data['stall_id'] == stall_id:
                current_status = s_data.get('trang_thai')
                break
    
    print(f"  Stall {stall_id}: trạng thái hiện tại = {current_status}")
    
    # Toggle to dong_cua
    r2, s2 = make_req('POST', f'/api/quan-ly-cho/stalls/{stall_id}/status',
        data={'status': 'dong_cua', 'note': 'Test dong cua'},
        token=TOKEN, label=f"POST /stalls/{stall_id}/status (dong_cua)")
    
    if r2 and r2.get('success'):
        # Verify change in map
        r3, _ = make_req('GET', '/api/quan-ly-cho/stalls/map', label="Verify stall status after update")
        if r3 and r3.get('data'):
            updated = next((s for s in r3['data'] if s['stall_id'] == stall_id), None)
            if updated and updated.get('trang_thai') != 'dong_cua':
                ISSUES.append({"bug": f"Sau khi update dong_cua, stall vẫn là {updated.get('trang_thai')}"})
            else:
                print(f"     → Verify OK: stall {stall_id} = dong_cua")
        
        # Restore
        if current_status:
            r4, _ = make_req('POST', f'/api/quan-ly-cho/stalls/{stall_id}/status',
                data={'status': current_status, 'note': 'Restore'},
                token=TOKEN, label=f"Restore stall to {current_status}")

# Invalid status value
r, s = make_req('POST', f'/api/quan-ly-cho/stalls/{stall_id or "GH000001"}/status',
    data={'status': 'invalid_status', 'note': ''},
    token=TOKEN, label="POST /stalls/status (invalid status value)")
if s == 200:
    ISSUES.append({"bug": "Backend chấp nhận status không hợp lệ 'invalid_status' mà không báo lỗi"})
elif s in (400, 422):
    FAIL -= 1  # Expected failure

# ─────────────────────────────────────────────────────────────
# 13. LOGIC ISSUES - CROSS-CHECK
# ─────────────────────────────────────────────────────────────
section("13. KIỂM TRA LOGIC CHUYÊN SÂU")

# Check: auth middleware cho map stalls test
print("  [A] Kiểm tra /stalls/map không cần auth...")
r, s = make_req('GET', '/api/quan-ly-cho/stalls/map', label="Map no auth (must be 200)")
if s != 200:
    ISSUES.append({"bug": "GET /stalls/map không public - nhưng shipper app cần gọi!"})

# Check: /loai-hang-hoa cần auth
print("  [B] Kiểm tra /loai-hang-hoa cần auth...")
r, s = make_req('GET', '/api/quan-ly-cho/loai-hang-hoa', label="Loai hang hoa (no auth)")
if s not in (401, 403):
    ISSUES.append({"bug": f"/loai-hang-hoa không protected! (got {s})"})
else:
    FAIL -= 1

# Check: approve_seller raises ValueError vs HTTPException
print("  [C] Kiểm tra approve user đã duyệt (approval_status=1)...")
if merchant_id:
    # merchant_id đã có approval_status=1 (đã có gian hàng)
    r, s = make_req('PATCH', f'/api/quan-ly-cho/approve-seller/{merchant_id}',
                    token=TOKEN, label=f"PATCH approve đã duyệt user {merchant_id}")
    # Issue: approve_seller raises ValueError nhưng router không catch!
    if s == 500:
        ISSUES.append({
            "bug": "CRITICAL: approve_seller raises ValueError cho user đã duyệt nhưng router không bắt (500 Internal Error)",
            "fix": "Thêm try/except ValueError trong router /approve-seller/{user_id}"
        })
    elif s == 400:
        print(f"     → Handled correctly: 400")
    else:
        print(f"     → Got {s}")

# ─────────────────────────────────────────────────────────────
# TỔNG KẾT
# ─────────────────────────────────────────────────────────────
section("📊 KẾT QUẢ CUỐI CÙNG")
print(f"\n  ✅ ENDPOINTS HOẠT ĐỘNG ĐÚNG : {len(PASSES)}")
print(f"  ❌ THẤT BẠI (không mong đợi): {FAIL}")
print(f"  🐛 ISSUES LOGIC PHÁT HIỆN   : {len(ISSUES)}")

if ISSUES:
    print("\n  ─── DANH SÁCH ISSUES ───────────────────────────────────")
    for i, issue in enumerate(ISSUES, 1):
        issue_str = json.dumps(issue, ensure_ascii=False)
        print(f"\n  [{i:02d}] {issue_str}")
else:
    print("\n  🎉 Không phát hiện issue logic!")

print()
