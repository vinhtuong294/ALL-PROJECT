import requests, sys, json
sys.stdout.reconfigure(encoding='utf-8')
BASE = 'http://127.0.0.1:8001'

# Dang nhap Shipper
r = requests.post(f'{BASE}/api/auth/login', json={'login_name': 'hieushipper', 'password': 'Trinh123456@'})
token = r.json().get('token')
if not token:
    print("LOGIN FAIL:", r.text)
    sys.exit(1)
headers = {'Authorization': f'Bearer {token}'}
print("Dang nhap Shipper thanh cong!")

# Goi API wallet balance cua Shipper
r2 = requests.get(f'{BASE}/api/wallets/WH00000003/balance', headers=headers)
print(f'HTTP Status: {r2.status_code}')

if r2.status_code != 200:
    print("Loi:", r2.text)
    sys.exit(1)

data = r2.json()
print(f'so_du        : {data.get("so_du")} VND')
print(f'tong_tien_vao: {data.get("tong_tien_vao")} VND  (phi ship nhan duoc)')
print(f'tong_tien_ra : {data.get("tong_tien_ra")} VND  (phi giao that bai)')
print()
chi_tiet = data.get('chi_tiet', [])
print(f'Chi tiet ({len(chi_tiet)} giao dich):')
for item in chi_tiet:
    print(f'  [{item.get("loai")}] {item.get("huong")} | order={item.get("order_id")} | so_tien={item.get("so_tien")} VND')

if not chi_tiet:
    print("=> CHUA CO GIAO DICH NAO TRONG VI")
    print()
    print("Kiem tra thu cong don co trang thai da_giao...")
    from app.database import SessionLocal
    from app.models.models import Order, OrderDetail, Consolidation, Shipper
    db = SessionLocal()
    shipper = db.query(Shipper).filter(Shipper.shipper_id == 'SP7SUENE').first()
    cons = db.query(Consolidation).filter(Consolidation.shipper_id == shipper.shipper_id).all()
    con_ids = [c.consolidation_id for c in cons]
    orders_da_giao = db.query(Order).filter(
        Order.consolidation_id.in_(con_ids),
        Order.order_status == 'da_giao'
    ).all()
    print(f"Don hang co status=da_giao: {len(orders_da_giao)}")
    for o in orders_da_giao:
        phi_ship = db.query(OrderDetail).filter(
            OrderDetail.order_id == o.order_id,
            OrderDetail.ingredient_id == 'NLQD01'
        ).first()
        print(f"  OrderID={o.order_id} | phi_ship={phi_ship.final_price if phi_ship else 'KHONG CO'} VND")
    db.close()
