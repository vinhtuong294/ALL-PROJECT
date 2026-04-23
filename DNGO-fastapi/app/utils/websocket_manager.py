import asyncio
from collections import defaultdict
from typing import Any, Dict, Optional, Set

import anyio
from fastapi import WebSocket


class ChatWebSocketManager:
    """Manage active websocket connections grouped by conversation."""

    def __init__(self) -> None:
        self._rooms: Dict[str, Set[WebSocket]] = defaultdict(set)
        self._lock = asyncio.Lock()

    async def connect(self, conversation_id: str, websocket: WebSocket) -> None:
        await websocket.accept()
        async with self._lock:
            self._rooms[conversation_id].add(websocket)

    async def disconnect(self, conversation_id: str, websocket: WebSocket) -> None:
        async with self._lock:
            room = self._rooms.get(conversation_id)
            if not room:
                return

            room.discard(websocket)
            if not room:
                self._rooms.pop(conversation_id, None)

    async def broadcast_json(
        self,
        conversation_id: str,
        payload: Dict[str, Any],
        exclude: Optional[WebSocket] = None,
    ) -> int:
        async with self._lock:
            connections = list(self._rooms.get(conversation_id, set()))

        if not connections:
            return 0

        disconnected: list[WebSocket] = []
        sent_count = 0

        for websocket in connections:
            if exclude is not None and websocket is exclude:
                continue

            try:
                await websocket.send_json(payload)
                sent_count += 1
            except Exception:
                disconnected.append(websocket)

        if disconnected:
            async with self._lock:
                room = self._rooms.get(conversation_id)
                if room:
                    for websocket in disconnected:
                        room.discard(websocket)
                    if not room:
                        self._rooms.pop(conversation_id, None)

        return sent_count

    def broadcast_from_sync(
        self,
        conversation_id: str,
        payload: Dict[str, Any],
    ) -> int:
        """Broadcast helper for sync FastAPI handlers (runs in threadpool)."""
        try:
            return anyio.from_thread.run(
                self.broadcast_json,
                conversation_id,
                payload,
            )
        except RuntimeError:
            return 0


chat_ws_manager = ChatWebSocketManager()
