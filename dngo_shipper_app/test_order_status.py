import requests, json, sys

sys.stdout.reconfigure(encoding='utf-8')

login_res = requests.post('http://207.180.233.84:8000/api/auth/login', json={'ten_dang_nhap': 'hieushipper', 'mat_khau': '1'})
if login_res.status_code != 200:
    print('Login failed:', login_res.text)
    sys.exit(1)

token = login_res.json().get('token')
headers = {'Authorization': f'Bearer {token}', 'Content-Type': 'application/json'}

order_id_test = "DH000002"
detail_res = requests.get(f'http://207.180.233.84:8000/api/shipper/orders/{order_id_test}/details', headers=headers)
print(f'Order {order_id_test} details:', json.dumps(detail_res.json(), ensure_ascii=False, indent=2))

res = requests.get('http://207.180.233.84:8000/api/shipper/orders/available', headers=headers)
data = res.json()

if data.get('items'):
    order = data['items'][0]
    order_id = order['ma_don_hang']
    print(f'\nTrying to test another order: {order_id}, initial status: {order.get("tinh_trang_don_hang")}')
    
    accept_res = requests.post(f'http://207.180.233.84:8000/api/shipper/orders/accept', json={'ma_don_hang': order_id}, headers=headers)
    print('Accept response:', accept_res.status_code, accept_res.text)
    
    detail_res = requests.get(f'http://207.180.233.84:8000/api/shipper/orders/{order_id}/details', headers=headers)
    detail_data = detail_res.json()
    print(f'Order detail after accept: {detail_data.get("data", {}).get("tinh_trang_don_hang")}')
else:
    print('\nNo available orders to test.')
