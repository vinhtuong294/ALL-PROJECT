import sys
import os

sys.path.append(os.getcwd())

from app.database import SessionLocal
from app.models.models import User, Stall

db = SessionLocal()

try:
    query = db.query(User).filter(
        User.role == "nguoi_ban"
    ).outerjoin(
        Stall, Stall.user_id == User.user_id
    ).filter(
        Stall.user_id == None
    )

    users = query.all()
    print("Found users without stall:", len(users))
    for u in users:
        print(f"- {u.user_id} | approval_status={u.approval_status}")

finally:
    db.close()
