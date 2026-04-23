import logging
from typing import Optional

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt

from app.config import settings
from app.database import SessionLocal
from app.models.models import Buyer, Conversation, Stall, User
from app.utils.websocket_manager import chat_ws_manager


logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/chat/ws", tags=["Chat WebSocket"])


def _get_user_from_token(token: str, db) -> Optional[dict]:
    try:
        payload = jwt.decode(
            token,
            settings.JWT_SECRET,
            algorithms=[settings.JWT_ALGORITHM],
        )
        user_id = payload.get("user_id") or payload.get("sub")
        if not user_id:
            return None

        role = payload.get("role")
        if role:
            return {"user_id": user_id, "role": role}

        user = db.query(User).filter(User.user_id == user_id).first()
        if not user:
            return None
        return {"user_id": user.user_id, "role": user.role}
    except JWTError:
        return None


def _can_access_conversation(db, conversation: Conversation, user_id: str, role: str) -> bool:
    if role == "nguoi_mua":
        buyer = db.query(Buyer).filter(Buyer.user_id == user_id).first()
        return bool(buyer and buyer.buyer_id == conversation.buyer_id)

    stall = (
        db.query(Stall)
        .filter(
            Stall.user_id == user_id,
            Stall.stall_id == conversation.stall_id,
        )
        .first()
    )
    return stall is not None


@router.websocket("/conversations/{conversation_id}")
async def chat_room_socket(
    websocket: WebSocket,
    conversation_id: str,
    token: Optional[str] = Query(None),
):
    if not token:
        await websocket.close(code=1008)
        return

    db = SessionLocal()
    user_id = None

    try:
        auth_user = _get_user_from_token(token, db)
        if not auth_user:
            await websocket.close(code=1008)
            return

        conversation = (
            db.query(Conversation)
            .filter(Conversation.conversation_id == conversation_id)
            .first()
        )
        if not conversation:
            await websocket.close(code=1008)
            return

        user_id = auth_user["user_id"]
        role = auth_user["role"]

        if not _can_access_conversation(db, conversation, user_id, role):
            await websocket.close(code=1008)
            return

        await chat_ws_manager.connect(conversation_id, websocket)

        await websocket.send_json(
            {
                "type": "connection.ready",
                "conversation_id": conversation_id,
            }
        )

        while True:
            payload = await websocket.receive_json()
            event_type = str(payload.get("type", "")).strip().lower()

            if event_type == "ping":
                await websocket.send_json({"type": "pong"})
                continue

            if event_type == "typing":
                await chat_ws_manager.broadcast_json(
                    conversation_id,
                    {
                        "type": "typing",
                        "conversation_id": conversation_id,
                        "sender_id": user_id,
                        "is_typing": bool(payload.get("is_typing", True)),
                    },
                    exclude=websocket,
                )
                continue

            if event_type == "message.read":
                await chat_ws_manager.broadcast_json(
                    conversation_id,
                    {
                        "type": "message.read",
                        "conversation_id": conversation_id,
                        "reader_id": user_id,
                    },
                    exclude=websocket,
                )
                continue

            await websocket.send_json(
                {
                    "type": "error",
                    "message": "Unsupported event type",
                }
            )

    except WebSocketDisconnect:
        pass
    except Exception as exc:
        logger.exception("WebSocket chat error: %s", exc)
        try:
            await websocket.send_json(
                {
                    "type": "error",
                    "message": "Internal websocket error",
                }
            )
            await websocket.close(code=1011)
        except Exception:
            pass
    finally:
        await chat_ws_manager.disconnect(conversation_id, websocket)
        db.close()
