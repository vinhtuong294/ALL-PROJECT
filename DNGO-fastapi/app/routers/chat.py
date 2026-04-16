from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from pydantic import BaseModel
from app.database import get_db
from app.middlewares.auth import get_current_user, AuthUser
from app.models.models import Conversation, Message, Buyer, Stall
import uuid


router = APIRouter(prefix="/api/chat", tags=["Chat"])




class SendMessageBody(BaseModel):
    message_text: Optional[str] = None
    image_url: Optional[str] = None




# ================================
# Lấy hoặc tạo conversation
# ================================
@router.post("/conversations/{stall_id}")
def get_or_create_conversation(
    stall_id: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user)
):
    buyer = db.query(Buyer).filter(Buyer.user_id == current_user.user_id).first()
    if not buyer:
        raise HTTPException(404, "Không tìm thấy thông tin người mua")


    stall = db.query(Stall).filter(Stall.stall_id == stall_id).first()
    if not stall:
        raise HTTPException(404, "Không tìm thấy gian hàng")


    # Kiểm tra conversation đã tồn tại chưa
    conv = db.query(Conversation).filter(
        Conversation.buyer_id == buyer.buyer_id,
        Conversation.stall_id == stall_id
    ).first()


    if not conv:
        conv = Conversation(
            conversation_id=str(uuid.uuid4())[:10],
            buyer_id=buyer.buyer_id,
            stall_id=stall_id
        )
        db.add(conv)
        db.commit()
        db.refresh(conv)


    return {
        "success": True,
        "conversation_id": conv.conversation_id,
        "stall_id": stall_id,
        "ten_gian_hang": stall.stall_name,
        "buyer_id": buyer.buyer_id
    }




# ================================
# Lấy danh sách conversation
# ================================
@router.get("/conversations")
def list_conversations(
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user)
):
    # Kiểm tra role
    if current_user.role == "nguoi_mua":
        buyer = db.query(Buyer).filter(Buyer.user_id == current_user.user_id).first()
        if not buyer:
            raise HTTPException(404, "Không tìm thấy thông tin người mua")
        convs = db.query(Conversation).filter(
            Conversation.buyer_id == buyer.buyer_id
        ).order_by(Conversation.created_at.desc()).all()
        is_buyer = True
    else:
        stall = db.query(Stall).filter(Stall.user_id == current_user.user_id).first()
        if not stall:
            raise HTTPException(404, "Không tìm thấy gian hàng")
        convs = db.query(Conversation).filter(
            Conversation.stall_id == stall.stall_id
        ).order_by(Conversation.created_at.desc()).all()
        is_buyer = False

    data = []
    for c in convs:
        last_msg = db.query(Message).filter(
            Message.conversation_id == c.conversation_id
        ).order_by(Message.sent_at.desc()).first()

        unread = db.query(Message).filter(
            Message.conversation_id == c.conversation_id,
            Message.is_read == False,
            Message.sender_type == ("seller" if is_buyer else "buyer")
        ).count()

        data.append({
            "conversation_id": c.conversation_id,
            "stall_id": c.stall_id,
            "ten_gian_hang": c.stall.stall_name if c.stall else None,
            "buyer_id": c.buyer_id,
            "ten_nguoi_mua": c.buyer.user.user_name if c.buyer and c.buyer.user else None,
            "tin_nhan_cuoi": last_msg.message_text if last_msg else None,
            "thoi_gian_cuoi": str(last_msg.sent_at) if last_msg else None,
            "unread": unread
        })

    return {"success": True, "data": data}


# ================================
# Lấy tin nhắn trong conversation
# ================================
@router.get("/conversations/{conversation_id}/messages")
def get_messages(
    conversation_id: str,
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user)
):
    conv = db.query(Conversation).filter(
        Conversation.conversation_id == conversation_id
    ).first()
    if not conv:
        raise HTTPException(404, "Không tìm thấy cuộc trò chuyện")


    offset = (page - 1) * limit
    messages = db.query(Message).filter(
        Message.conversation_id == conversation_id
    ).order_by(Message.sent_at.desc()).offset(offset).limit(limit).all()


    total = db.query(Message).filter(
        Message.conversation_id == conversation_id
    ).count()


    # Đánh dấu đã đọc
    buyer = db.query(Buyer).filter(Buyer.user_id == current_user.user_id).first()
    sender_type = "seller" if not buyer else "buyer"
    db.query(Message).filter(
        Message.conversation_id == conversation_id,
        Message.sender_type != sender_type,
        Message.is_read == False
    ).update({"is_read": True})
    db.commit()


    return {
        "success": True,
        "data": [
            {
                "message_id": m.message_id,
                "sender_id": m.sender_id,
                "sender_type": m.sender_type,
                "message_text": m.message_text,
                "image_url": m.image_url,
                "is_read": m.is_read,
                "sent_at": str(m.sent_at)
            }
            for m in reversed(messages)
        ],
        "meta": {
            "page": page,
            "limit": limit,
            "total": total
        }
    }




# ================================
# Gửi tin nhắn
# ================================
@router.post("/conversations/{conversation_id}/messages")
def send_message(
    conversation_id: str,
    body: SendMessageBody,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user)
):
    if not body.message_text and not body.image_url:
        raise HTTPException(400, "Phải có nội dung hoặc hình ảnh")


    conv = db.query(Conversation).filter(
        Conversation.conversation_id == conversation_id
    ).first()
    if not conv:
        raise HTTPException(404, "Không tìm thấy cuộc trò chuyện")


    buyer = db.query(Buyer).filter(Buyer.user_id == current_user.user_id).first()
    sender_type = "buyer" if buyer else "seller"


    msg = Message(
        conversation_id=conversation_id,
        sender_id=current_user.user_id,
        sender_type=sender_type,
        message_text=body.message_text,
        image_url=body.image_url
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)


    return {
        "success": True,
        "data": {
            "message_id": msg.message_id,
            "sender_id": msg.sender_id,
            "sender_type": msg.sender_type,
            "message_text": msg.message_text,
            "image_url": msg.image_url,
            "sent_at": str(msg.sent_at)
        }
    }
