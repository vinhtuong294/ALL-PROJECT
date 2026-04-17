import sys
sys.path.append('.')
from app.database import SessionLocal
from app.models.models import Shipper, User
db = SessionLocal()
users = db.query(Shipper).join(User, Shipper.user_id == User.user_id).all()
for s in users:
    print(getattr(s.user, 'login_name', None), getattr(s.user, 'password', None))
