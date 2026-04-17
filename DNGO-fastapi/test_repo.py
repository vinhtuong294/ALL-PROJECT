import sys
import traceback
sys.path.append('.')
from app.database import SessionLocal
from app.repositories import shipper

db = SessionLocal()
try:
    print("Testing list_available_orders...")
    res = shipper.list_available_orders(db, page=1, limit=10)
    print("Available count:", res['total'])
    print("Available success!")

    print("Testing list_my_orders for shipper_1776097303...")
    res2 = shipper.list_my_orders(db, "shipper_1776097303", page=1, limit=10)
    print("My count:", res2['total'])
    print("My success!")

except Exception as e:
    print("Error occurred!")
    traceback.print_exc()
