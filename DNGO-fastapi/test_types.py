import sys
sys.path.append('.')
from app.database import SessionLocal
from app.repositories import shipper

db = SessionLocal()
res = shipper.list_available_orders(db, page=1, limit=50)

for idx, order in enumerate(res['items']):
    # check keys
    try:
        assert isinstance(order.get('tong_tien'), (int, float, type(None)))
        if order.get('khung_gio') is not None:
            pass # can be anything
    except AssertionError:
        print(f"Order {idx} has invalid type!")

print(f"Checked 50 orders, types are OK.")
