import sys
import os
sys.path.append(os.getcwd())
from app.db.database import SessionLocal
from app.repositories.shipper import list_available_orders

db = SessionLocal()
orders = list_available_orders(db)
print(f"Total available: {orders['total']}")
for o in orders['items']:
    print(f" - {o['ma_don_hang']}")
