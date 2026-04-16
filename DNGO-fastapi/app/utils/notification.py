import json
from sqlalchemy.orm import Session
from app.models.models import Notification

def create_notification(db: Session, user_id: str, title: str, body: str, data: dict = {}):
    notif = Notification(
        user_id=user_id,
        title=title,
        body=body,
        data=data
    )
    db.add(notif)