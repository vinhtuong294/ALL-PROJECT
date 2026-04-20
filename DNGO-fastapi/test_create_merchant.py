#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Test POST /tieu-thuong với luồng tự sinh stall_id (Cách B)"""
import sys, json, urllib.request, urllib.error, time
sys.stdout.reconfigure(encoding='utf-8')

BASE = 'http://localhost:8000'

def req(method, path, data=None, token=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = f'Bearer {token}'
    body = json.dumps(data, ensure_ascii=False).encode('utf-8') if data else None
    r = urllib.request.Request(BASE + path, data=body, headers=headers, method=method)
    try:
        resp = urllib.request.urlopen(r, timeout=10)
        return json.loads(resp.read().decode('utf-8')), resp.status
    except urllib.error.HTTPError as e:
        return json.loads(e.read().decode('utf-8')), e.code

# Login
print("Đang login...")
r, s = req('POST', '/api/auth/login', {'login_name': 'quanlycho', 'password': '123456'})
TOKEN = r.get('token')
print(f"Login: {s} | token={'OK' if TOKEN else 'FAIL'}")

print()
print("=" * 55)
print("TEST 1: Tạo tiểu thương hợp lệ")
print("=" * 55)
import random
test_phone = f"09{''.join([str(random.randint(0,9)) for _ in range(8)])}"
r, s = req('POST', '/api/quan-ly-cho/tieu-thuong', {
    'ten_nguoi_dung': 'Trần Thị Test',
    'dia_chi': '123 Đường Test, Đà Nẵng',
    'so_dien_thoai': test_phone,
    'loai_hang_hoa': 'TH',
    'tien_thue_mac_dinh': 600000,
    'grid_col': 5,
    'grid_row': 3
}, TOKEN)
print(f"  Status: {s}")
if s == 200:
    d = r.get('data', {})
    print(f"  ✅ user_id     : {d.get('user_id')}")
    print(f"  ✅ login_name  : {d.get('login_name')} (= SĐT)")
    print(f"  ✅ password    : {d.get('default_password')}")
    print(f"  ✅ stall_id    : {d.get('stall_id')} (tự sinh)")
    print(f"  ✅ stall_name  : {d.get('stall_name')}")
    print(f"  ✅ loai_hang   : {d.get('loai_hang_hoa')}")
    print(f"  ✅ tien_thue   : {d.get('tien_thue_thang'):,.0f}đ/tháng")
    CREATED_PHONE = test_phone
else:
    print(f"  ❌ FAIL: {r}")
    CREATED_PHONE = None

print()
print("=" * 55)
print("TEST 2: Trùng số điện thoại (expect 400)")
print("=" * 55)
if CREATED_PHONE:
    r, s = req('POST', '/api/quan-ly-cho/tieu-thuong', {
        'ten_nguoi_dung': 'Người Khác',
        'dia_chi': '456 Đường Khác',
        'so_dien_thoai': CREATED_PHONE,  # Số đã dùng
        'loai_hang_hoa': 'RC',
        'tien_thue_mac_dinh': 400000,
    }, TOKEN)
    print(f"  Status: {s}")
    if s == 400:
        print(f"  ✅ Từ chối đúng: {r.get('detail')}")
    else:
        print(f"  ❌ Sai, expect 400, got {s}: {r}")

print()
print("=" * 55)
print("TEST 3: Loại hàng hóa không hợp lệ (expect 422)")
print("=" * 55)
r, s = req('POST', '/api/quan-ly-cho/tieu-thuong', {
    'ten_nguoi_dung': 'Test',
    'dia_chi': '789',
    'so_dien_thoai': '0999999991',
    'loai_hang_hoa': 'INVALID_TYPE',
    'tien_thue_mac_dinh': 100000,
}, TOKEN)
print(f"  Status: {s}")
if s == 422:
    print(f"  ✅ Validate đúng: {r.get('detail', r)[:150]}")
else:
    print(f"  ❌ Sai, expect 422, got {s}")

print()
print("=" * 55)
print("TEST 4: Tiền thuê = 0 (expect 422)")
print("=" * 55)
r, s = req('POST', '/api/quan-ly-cho/tieu-thuong', {
    'ten_nguoi_dung': 'Test',
    'dia_chi': '789',
    'so_dien_thoai': '0999999992',
    'loai_hang_hoa': 'TH',
    'tien_thue_mac_dinh': 0,
}, TOKEN)
print(f"  Status: {s}")
if s == 422:
    print(f"  ✅ Validate đúng: tiền thuê = 0 bị từ chối")
else:
    print(f"  ❌ Sai, expect 422, got {s}: {r}")

print()
print("=" * 55)
print("TEST 5: SĐT không hợp lệ (expect 422)")
print("=" * 55)
r, s = req('POST', '/api/quan-ly-cho/tieu-thuong', {
    'ten_nguoi_dung': 'Test',
    'dia_chi': '789',
    'so_dien_thoai': '123',   # Quá ngắn
    'loai_hang_hoa': 'TH',
    'tien_thue_mac_dinh': 300000,
}, TOKEN)
print(f"  Status: {s}")
if s == 422:
    print(f"  ✅ Validate đúng: SĐT ngắn bị từ chối")
else:
    print(f"  ❌ Sai, expect 422, got {s}")

print()
print("TEST 6: Đăng nhập bằng SĐT (login_name mới)")
print("=" * 55)
if CREATED_PHONE:
    r, s = req('POST', '/api/auth/login', {'login_name': CREATED_PHONE, 'password': '123456'})
    print(f"  Status: {s}")
    if s == 200:
        role = r.get('data', {}).get('role')
        name = r.get('data', {}).get('user_name')
        print(f"  ✅ Login OK: {name} | role={role}")
    else:
        print(f"  ❌ Không login được bằng SĐT: {r}")
