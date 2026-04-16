"""
main.py – FastAPI Chatbot API Ẩm Thực
Tích hợp: Qwen2.5 (Ollama) + RAG (FAISS)

2 luồng chatbot:
  1. Đề xuất món ăn → user chọn nguyên liệu → xem gian hàng (luồng cũ)
  2. Chat hỏi trực tiếp gian hàng bán gì (luồng MỚI)
"""
import uuid
import random
import json
from fastapi.responses import JSONResponse
from typing import Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

import data_loader as dl
import vector_store as vs
import llama_service as llm
import intent_detector as id_mod


# ─── Startup ─────────────────────────────────────────────────────────────────

@asynccontextmanager
async def lifespan(app: FastAPI):
    print("=" * 55)
    print("  🍜  Chatbot Ẩm Thực API – Khởi động...")
    print("=" * 55)
    data = dl.get_data()
    vs.build_index(data["rag"])

    ollama_status = llm.check_ollama_connection()
    if ollama_status.get("ollama_running"):
        if ollama_status.get("model_ready"):
            print('[startup] ✅ Kết nối Ollama/Qwen: OK')
        else:
            print(f'[startup] ⚠️ Model chưa có: {ollama_status.get("hint")}')
    else:
        print('[startup] ❌ Cảnh báo: Không kết nối được Ollama!')

    print("[startup] ✅ Sẵn sàng phục vụ!\n")
    yield

class UTF8JSONResponse(JSONResponse):
    def render(self, content) -> bytes:
        return json.dumps(content, ensure_ascii=False, indent=None).encode("utf-8")

app = FastAPI(
    title="Chatbot Ẩm Thực API",
    default_response_class=UTF8JSONResponse, 
    description=(
        "API chatbot tư vấn món ăn và gian hàng dùng Qwen2.5 + RAG.\n\n"
        "**2 luồng chính:**\n"
        "- Hỏi món ăn → `dishes[]` + gợi ý mua nguyên liệu\n"
        "- Hỏi gian hàng → `shops[]` với rating, địa điểm, hàng hóa\n\n"
        "**Flutter**: Kiểm tra `intent` trong response để render UI phù hợp."
    ),
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Pydantic Schemas ─────────────────────────────────────────────────────────

class HistoryItem(BaseModel):
    role: str       # "user" | "assistant"
    content: str

class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None
    history: Optional[list[HistoryItem]] = []

class MenuRequest(BaseModel):
    health_goal: str = "Dinh dưỡng cân bằng"
    days: int = 3
    meals_per_day: int = 3

class MenuGenerateRequest(BaseModel):
    days: int = 1
    meals_per_day: int = 2
    health_goal: str = "Cân bằng"
    notes: list = []


# ─── Helpers ─────────────────────────────────────────────────────────────────

MEAL_LABELS = ["🌅 Sáng", "☀️ Trưa", "🌙 Tối"]

def _rag_dishes(query: str, k: int = 8) -> list[dict]:
    ids = vs.semantic_search(query, k=k)
    results = [dl.get_dish_by_id(did) for did in ids]
    return [d for d in results if d is not None]

def _keyword_dishes(query: str, limit: int = 8) -> list[dict]:
    return dl.search_dishes(query=query, limit=limit)

def _get_dishes_for_message(message: str, intent: str) -> list[dict]:
    """Chọn strategy tìm kiếm món ăn phù hợp với intent (luồng cũ — giữ nguyên)."""
    keywords = id_mod.extract_keywords(message)
    text = message.lower()

    DISH_TYPES = [
        "canh", "súp", "lẩu", "gỏi", "salad", "xào", "chiên",
        "nướng", "hấp", "kho", "rim", "cuộn", "bánh", "cháo",
        "bún", "phở", "mì", "cơm", "pizza", "burger", "sandwich"
    ]
    INGREDIENTS = [
        "thịt bò", "thịt heo", "thịt gà", "thịt vịt", "thịt dê",
        "cánh gà", "đùi gà", "ức gà", "chân gà",
        "sườn heo", "ba chỉ", "chân giò",
        "cá hồi", "cá thu", "cá lóc", "cá chép", "cá ngừ",
        "tôm", "cua", "mực", "hải sản", "bạch tuộc", "nghêu", "sò",
        "thịt", "cá", "gà", "vịt", "heo", "rau", "đậu", "trứng"
    ]
    FAMILY_GROUPS = {
        "trẻ em":         ["DM47"],
        "con nít":        ["DM47"],
        "con nhỏ":        ["DM47"],
        "em bé":          ["DM47"],
        " bé ":           ["DM47"],
        "người già":      ["DM39"],
        "người lớn tuổi": ["DM39"],
        "ông bà":         ["DM39"],
        "bà bầu":         ["DM36"],
        "mang thai":      ["DM36"],
        "gia đình":       ["DM44"],
        "cả nhà":         ["DM44"],
    }

    dish_type  = next((d for d in DISH_TYPES  if d in text), None)
    ingredient = next((i for i in INGREDIENTS if i in text), None)

    if dish_type and ingredient:
        combined_query = f"{dish_type} {ingredient}"
        results = dl.search_dishes(query=combined_query, limit=10)
        strict = [d for d in results if dish_type in d["dish_name"].lower()]
        return strict if strict else results

    if dish_type:
        results = dl.search_dishes(query=dish_type, limit=10)
        strict = [d for d in results if dish_type in d["dish_name"].lower()]
        return strict if strict else results

    if ingredient:
        data = dl.get_data()
        df = data["dishes"].copy()
        mask = df['dish_name'].str.lower().str.contains(ingredient.lower(), na=False)
        matched = df[mask].head(10)
        if not matched.empty:
            return [dl.build_dish_response(row) for _, row in matched.iterrows()]
        return dl.search_dishes(query=ingredient, limit=8)

    matched_groups = []
    for keyword, group_ids in FAMILY_GROUPS.items():
        if keyword in text:
            matched_groups.extend(group_ids)

    if matched_groups:
        result = dl.suggest_menu(
            days=1,
            health_goal_ids=matched_groups,
            note_ids=[],
            meals_per_day=3
        )
        dishes = []
        for day in result["menu"]:
            for meal in day["meals"]:
                dishes.append(meal["dish"])
        return dishes[:8]

    if intent == "health_advice":
        goal = id_mod.extract_health_goal(message)
        return dl.get_dishes_by_health_goal(goal, limit=8)

    if intent == "filter_quick":
        max_time = id_mod.extract_time_limit(message)
        return dl.search_dishes(query=keywords, max_time=max_time, limit=8)

    if intent == "diet_type":
        return dl.search_dishes(query="chay " + keywords, limit=8)

    if intent == "greeting":
        return []

    dishes = _rag_dishes(message)
    if not dishes:
        dishes = _keyword_dishes(keywords)
    return dishes


INGREDIENT_KEYWORDS = [
    "thịt bò", "thịt heo", "thịt gà", "thịt vịt", "thịt dê",
    "cá hồi", "cá thu", "cá lóc", "cá chép", "cá ngừ",
    "tôm tươi", "tôm", "cua", "mực", "hải sản", "bạch tuộc", "nghêu", "sò",
    "rau sạch", "rau củ", "rau", "đậu phụ", "trứng gà", "trứng",
    "nấm", "gạo", "bún", "phở", "heo", "gà", "vịt", "bò",
]

def _get_shops_for_message(message: str, filters: dict) -> list[dict]:
    text = message.lower()

    # Ưu tiên match cụm dài nhất trước
    matched = ""
    for kw in sorted(INGREDIENT_KEYWORDS, key=len, reverse=True):
        if kw in text:
            matched = kw
            break

    # Fallback: dùng extract_keywords nếu không match
    if not matched:
        matched = id_mod.extract_keywords(message)

    print(f"[DEBUG] message='{message}' → keyword='{matched}'")

    return dl.search_stalls(
        keyword=matched,
        min_rating=filters.get("min_rating", 0),
        price_sort=filters.get("price_sort", "asc"),
        limit=5,
    )

# ─── Endpoints ───────────────────────────────────────────────────────────────

@app.get("/health", summary="Kiểm tra trạng thái API và Ollama")
def health_check():
    ollama_status = llm.check_ollama_connection()
    data = dl.get_data()
    return {
        "status":       "ok",
        "total_dishes": len(data["dishes"]),
        "ollama":       ollama_status,
    }


@app.post("/chat", summary="Chat với trợ lý ẩm thực (Qwen2.5 + RAG)")
def chat(req: ChatRequest):
    """
    **Endpoint chính** cho Flutter app.

    **2 luồng tự động:**

    **Luồng 1 — Hỏi món ăn** (intent khác search_shop):
    - RAG search tìm món liên quan
    - Qwen2.5 tạo phản hồi
    - Response: `dishes[]` đầy đủ công thức + buy_action
    - `shops[]` = [] (Flutter dùng /dishes/{id}/stalls khi user chọn nguyên liệu)

    **Luồng 2 — Hỏi gian hàng** (intent = search_shop):
    - Tìm gian hàng theo keyword từ câu hỏi
    - Qwen2.5 tạo phản hồi giới thiệu gian hàng
    - Response: `shops[]` với rating, địa điểm, hàng hóa
    - `dishes[]` = []

    **Flutter**: Dùng field `intent` để quyết định render UI nào.
    """
    session_id = req.session_id or str(uuid.uuid4())
    intent     = id_mod.detect_intent(req.message)

    dishes: list[dict] = []
    shops:  list[dict] = []

    if intent == "search_shop":
        # ── Luồng MỚI: user hỏi gian hàng trực tiếp ──────────────────────
        filters = id_mod.extract_shop_filters(req.message)
        shops   = _get_shops_for_message(req.message, filters)
    else:
        # ── Luồng CŨ: đề xuất món ăn (giữ nguyên toàn bộ logic) ──────────
        dishes = _get_dishes_for_message(req.message, intent)

    # Gọi LLM với context phù hợp
    history_dicts = [h.model_dump() for h in (req.history or [])]
    reply = llm.chat_with_llama(
        user_message=req.message,
        context_dishes=dishes,
        context_shops=shops if shops else None,
        history=history_dicts,
    )

    return {
        "session_id":  session_id,
        "intent":      intent,
        "reply":       reply,
        "dishes":      dishes,      # có data khi hỏi món ăn
        "shops":       shops,       # có data khi hỏi gian hàng
        "total_found": len(dishes) if dishes else len(shops),
    }


@app.get("/dishes/search", summary="Tìm kiếm món ăn đa tiêu chí (kèm công thức)")
def search_dishes(
    q: str = Query("", description="Từ khoá tìm kiếm (tên món, nguyên liệu)"),
    health_goal: str = Query("", description="Mục tiêu sức khoẻ"),
    max_calories: float = Query(0, description="Calo tối đa (0 = không giới hạn)"),
    min_calories: float = Query(0, description="Calo tối thiểu"),
    level: str = Query("", description="Độ khó: Dễ | Trung bình | Khó"),
    max_time: int = Query(0, description="Thời gian nấu tối đa (phút, 0 = không giới hạn)"),
    limit: int = Query(10, ge=1, le=50, description="Số lượng kết quả"),
):
    results = dl.search_dishes(
        query=q,
        health_goal=health_goal,
        max_calories=max_calories,
        min_calories=min_calories,
        level=level,
        max_time=max_time,
        limit=limit,
    )
    return {
        "query": q,
        "filters": {
            "health_goal":  health_goal,
            "max_calories": max_calories,
            "min_calories": min_calories,
            "level":        level,
            "max_time":     max_time,
        },
        "total_found": len(results),
        "dishes":      results,
    }


@app.get("/dishes/{dish_id}", summary="Xem chi tiết một món ăn (đầy đủ công thức)")
def get_dish_detail(dish_id: str):
    dish = dl.get_dish_by_id(dish_id.upper())
    if not dish:
        raise HTTPException(status_code=404, detail=f"Không tìm thấy món: {dish_id}")
    return dish


@app.post("/menu/suggest", summary="Gợi ý thực đơn N ngày theo mục tiêu sức khoẻ")
def suggest_menu(req: MenuRequest):
    if req.days < 1 or req.days > 14:
        raise HTTPException(status_code=400, detail="days phải từ 1 đến 14")

    pool = dl.get_dishes_by_health_goal(req.health_goal, limit=60)
    if len(pool) < 6:
        pool = dl.search_dishes(limit=60)

    random.shuffle(pool)

    menu = []
    used = set()
    idx  = 0

    for day in range(1, req.days + 1):
        meals  = []
        labels = MEAL_LABELS[:req.meals_per_day]
        for label in labels:
            while idx < len(pool) and pool[idx]["dish_id"] in used:
                idx += 1
            if idx >= len(pool):
                idx = 0
            dish = pool[idx]
            used.add(dish["dish_id"])
            idx += 1
            meals.append({"meal": label, "dish": dish})
        menu.append({"day": day, "meals": meals})

    return {
        "health_goal":   req.health_goal,
        "days":          req.days,
        "meals_per_day": req.meals_per_day,
        "menu":          menu,
        "note":          "Thực đơn được gợi ý tự động. Nhấn 'Mua ngay' để đặt mua nguyên liệu.",
    }


@app.get("/health-goals", summary="Danh sách các mục tiêu sức khoẻ trong DB")
def get_health_goals():
    return {"health_goals": dl.get_all_health_goals()}


# ─── Endpoints gian hàng ─────────────────────────────────────────────────────

@app.get("/dishes/{dish_id}/stalls", summary="Gian hàng bán nguyên liệu của món ăn (luồng cũ)")
def get_stalls_for_dish(dish_id: str):
    """
    User chọn món ăn → Flutter gọi endpoint này để lấy gian hàng
    bán nguyên liệu của món đó.
    """
    stalls = dl.get_stalls_for_dish(dish_id.upper())
    if not stalls:
        return {
            "dish_id": dish_id,
            "message": "Không tìm thấy gian hàng bán nguyên liệu cho món này.",
            "stalls":  []
        }
    return {
        "dish_id":      dish_id,
        "total_stalls": len(stalls),
        "stalls":       stalls,
    }


@app.get("/ingredients/stalls", summary="Gian hàng bán theo tên nguyên liệu (luồng cũ)")
def get_stalls_by_ingredient_name(name: str = Query(...)):
    """
    User chọn nguyên liệu cụ thể → Flutter gọi endpoint này.
    """
    stalls = dl.get_stalls_by_ingredient_name(name)
    if not stalls:
        return {
            "ingredient_name": name,
            "message":         "Không tìm thấy gian hàng.",
            "stalls":          []
        }
    return {
        "ingredient_name": name,
        "total_stalls":    len(stalls),
        "stalls":          stalls,
    }


@app.get("/stalls/search", summary="Tìm gian hàng theo keyword (luồng MỚI)")
def search_stalls(
    q: str = Query("", description="Từ khoá tìm kiếm (tên nguyên liệu, tên gian hàng)"),
    min_rating: float = Query(0, description="Rating tối thiểu (0 = không lọc)"),
    price_sort: str = Query("asc", description="Sắp xếp giá: asc (thấp→cao) | desc (cao→thấp)"),
    limit: int = Query(5, ge=1, le=20, description="Số gian hàng trả về"),
):
    """
    Endpoint riêng cho Flutter khi muốn hiển thị danh sách gian hàng
    theo từ khoá bất kỳ (không cần qua chatbot).
    """
    stalls = dl.search_stalls(
        keyword=q,
        min_rating=min_rating,
        price_sort=price_sort,
        limit=limit,
    )
    return {
        "query":        q,
        "total_stalls": len(stalls),
        "stalls":       stalls,
    }


@app.post("/menu/generate", summary="Gợi ý thực đơn theo ngày/tuần")
def generate_menu(req: MenuGenerateRequest):
    if req.days < 1 or req.days > 7:
        raise HTTPException(status_code=400, detail="days phải từ 1 đến 7")

    HEALTH_GROUPS = {
        "Cân bằng":     ["DM13", "DM44"],
        "Giảm cân":     ["DM16", "DM52"],
        "Tăng cân":     ["DM48", "DM26"],
        "Tăng cơ":      ["DM26", "DM48"],
        "Sức đề kháng": ["DM24", "DM21"],
    }
    NOTE_GROUPS = {
        "Món chay":       ["DM30"],
        "Ăn kiêng":       ["DM52"],
        "Miền Bắc":       ["DM02"],
        "Miền Trung":     ["DM45"],
        "Miền Nam":       ["DM37"],
        "Trẻ em":         ["DM47"],
        "Người lớn tuổi": ["DM39"],
    }

    health_goal_ids = HEALTH_GROUPS.get(req.health_goal, [])
    note_ids = []
    for note in req.notes:
        note_ids.extend(NOTE_GROUPS.get(note, []))

    result = dl.suggest_menu(
        days=req.days,
        health_goal_ids=health_goal_ids,
        note_ids=note_ids,
        meals_per_day=req.meals_per_day,
    )

    return {
        "health_goal":   req.health_goal,
        "notes":         req.notes,
        "days":          req.days,
        "meals_per_day": req.meals_per_day,
        "menu":          result["menu"],
    }

