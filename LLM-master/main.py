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
import re
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
import query_understanding as qu


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

class MenuGenerateRequest(BaseModel):
    days: int = 1
    meals_per_day: int = 2
    health_goal: str = "Cân bằng"
    notes: list = []
    allergen_ingredients: list = []


# ─── Helpers ─────────────────────────────────────────────────────────────────

MEAL_LABELS = ["🌅 Sáng", "☀️ Trưa", "🌙 Tối"]
_SHOP_NOISE_WORDS = {
    "gian", "hàng", "cửa", "shop", "quán", "nơi", "chỗ",
    "bán", "mua", "ở", "đâu", "ai", "cho", "tôi", "có", "không", "nào",
}
_SESSION_CACHE: dict[str, dict] = {}
_COOKING_FOLLOWUP_WORDS = {
    "món đó", "món này", "nó", "cách làm", "cách nấu", "chế biến", "hướng dẫn",
}
_DISH_QUERY_NOISE_WORDS = {
    "cách", "làm", "nấu", "chế", "biến", "hướng", "dẫn", "món", "đó", "này",
    "cho", "tôi", "xin", "với", "giúp", "mình", "ăn", "thế", "nào",
}


def _rag_dishes(query: str, k: int = 8) -> list[dict]:
    ids = vs.semantic_search(query, k=k)
    results = [dl.get_dish_by_id(did) for did in ids]
    return [d for d in results if d is not None]

def _keyword_dishes(query: str, limit: int = 8) -> list[dict]:
    return dl.search_dishes(query=query, limit=limit)


def _remember_session_dishes(session_id: str, dishes: list[dict]) -> None:
    if not session_id or not dishes:
        return
    _SESSION_CACHE[session_id] = {
        "recent_dishes": dishes[:5],
        "last_dish": dishes[0],
    }


def _extract_dish_hint(message: str, qr: qu.QueryResult) -> str:
    raw = (qr.entities.get("ingredient") or qr.search_query or message or "").lower()
    cleaned_words = [w for w in re.findall(r"\w+", raw, flags=re.UNICODE) if w not in _DISH_QUERY_NOISE_WORDS]
    return " ".join(cleaned_words).strip()


def _reuse_session_dishes(session_id: str, message: str, qr: qu.QueryResult, dishes: list[dict]) -> list[dict]:
    if dishes:
        _remember_session_dishes(session_id, dishes)
        return dishes

    if qr.intent != "cooking_instruction" or not session_id:
        return dishes

    cached = _SESSION_CACHE.get(session_id) or {}
    recent_dishes = cached.get("recent_dishes") or []
    if not recent_dishes:
        return dishes

    text = (message or "").lower()
    hint = _extract_dish_hint(message, qr)
    if any(token in text for token in _COOKING_FOLLOWUP_WORDS) and not hint:
        last_dish = cached.get("last_dish")
        return [last_dish] if last_dish else recent_dishes[:1]

    if hint:
        matched = []
        for dish in recent_dishes:
            recipe = dish.get("recipe") or {}
            haystack = " ".join([
                dish.get("dish_name", ""),
                dish.get("rag_context", ""),
                " ".join(recipe.get("ingredients") or []),
            ]).lower()
            if hint in haystack:
                matched.append(dish)
        if matched:
            return matched

    last_dish = cached.get("last_dish")
    return [last_dish] if last_dish else recent_dishes[:1]


def _build_cooking_instruction_reply(dish: dict) -> str:
    recipe = dish.get("recipe") or {}
    prep = (recipe.get("preparation") or "").strip()
    steps = (recipe.get("steps") or "").strip()
    detail_url = dish.get("detail_url") or dish.get("detail_path") or ""

    parts = [f"Cách chế biến món {dish.get('dish_name', 'này')}:\n"]
    if prep:
        parts.append(f"• Sơ chế: {prep}")
    if steps:
        parts.append(f"• Thực hiện: {steps}")
    if detail_url:
        parts.append(f"• Xem chi tiết tại: {detail_url}")
    parts.append("Bạn có thể mở món trong app để xem nguyên liệu và mua ngay.")
    return "\n".join(parts)


def _build_dish_text_blob(dish: dict) -> str:
    recipe = dish.get("recipe") or {}
    ingredients = recipe.get("ingredients") or []
    return " ".join([
        dish.get("dish_type", ""),
        dish.get("dish_name", ""),
        dish.get("rag_context", ""),
        " ".join(ingredients),
        recipe.get("preparation", ""),
        recipe.get("steps", ""),
        recipe.get("serving_tips", ""),
    ]).lower()


def _prepare_history_for_llm(history_items: list, exclude_terms: list[str]) -> list[dict]:
    if exclude_terms:
        return []
    return [h.model_dump() for h in (history_items or [])]


def _apply_exclude_terms(dishes: list[dict], exclude_terms: list[str]) -> list[dict]:
    """Post-filter: loại bỏ món chứa bất kỳ term nào trong exclude_terms."""
    if not exclude_terms:
        return dishes
    lower_terms = [t.lower() for t in exclude_terms if t.strip()]
    if not lower_terms:
        return dishes
    return [
        d for d in dishes
        if not any(t in _build_dish_text_blob(d) for t in lower_terms)
    ]


def _filter_dishes_by_type(dishes: list[dict], dish_type: Optional[str]) -> list[dict]:
    if not dish_type:
        return dishes
    target = dish_type.lower().strip()
    if not target:
        return dishes

    filtered = []
    for dish in dishes:
        recipe = dish.get("recipe") or {}
        haystack = " ".join([
            dish.get("dish_type", ""),
            dish.get("dish_name", ""),
            dish.get("rag_context", ""),
            recipe.get("preparation", ""),
            recipe.get("steps", ""),
        ]).lower()
        if target in haystack:
            filtered.append(dish)
    return filtered


def _get_dishes_for_message(message: str, qr: qu.QueryResult) -> list[dict]:
    """Chọn strategy tìm kiếm món ăn phù hợp với intent từ QueryResult."""
    dishes = _raw_dishes_for_message(message, qr)
    print(f"[MAIN] raw: {len(dishes)} dishes  exclude_terms: {qr.exclude_terms}")
    filtered = _apply_exclude_terms(dishes, qr.exclude_terms)
    if len(filtered) != len(dishes):
        print(f"[MAIN] after exclude filter: {len(filtered)} dishes")
    return filtered


def _raw_dishes_for_message(message: str, qr: qu.QueryResult) -> list[dict]:
    intent = qr.intent
    keywords = qr.search_query or id_mod.extract_keywords(message)
    text = message.lower()

    DISH_TYPES = [
        "canh", "súp", "lẩu", "gỏi", "salad", "xào", "chiên",
        "nướng", "hấp", "kho", "rim", "cuộn", "bánh", "cháo",
        "bún", "phở", "mì", "cơm", "pizza", "burger", "sandwich"
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

    # ── Nếu LLM extract được ingredient cụ thể (fix "cá mồi") ────────────
    ingredient = qr.entities.get("ingredient")
    dish_type = qr.entities.get("dish_type") or dish_type

    # Fallback: LLM biết intent nhưng không extract entities →
    # lấy search_query, cắt bỏ "nấu/làm/chế biến ..." để còn tên nguyên liệu thuần
    if not ingredient and intent == "search_ingredient":
        sq = qr.search_query or id_mod.extract_keywords(message)
        for sep in ["nấu", "làm", "chế biến"]:
            if sep in sq.lower():
                sq = sq[: sq.lower().index(sep)].strip()
                break
        ingredient = sq or id_mod.extract_keywords(message)

    if ingredient:
        data = dl.get_data()
        df = data["dishes"].copy()
        mask = df['dish_name'].str.lower().str.contains(ingredient.lower(), na=False)
        matched = df[mask]

        if dish_type and not matched.empty:
            type_text = matched['dish_name'].astype(str).str.lower()
            if 'dish_type' in matched.columns:
                type_text = type_text + ' ' + matched['dish_type'].astype(str).str.lower()
            if 'rag_context' in matched.columns:
                type_text = type_text + ' ' + matched['rag_context'].astype(str).str.lower()
            type_mask = type_text.str.contains(dish_type.lower(), na=False)
            matched = matched[type_mask]

        matched = matched.head(10)
        if not matched.empty:
            print(f"[MAIN] strategy: ingredient match ('{ingredient}' | type='{dish_type or '-'}')  found: {len(matched)}")
            return [dl.build_dish_response(row) for _, row in matched.iterrows()]

        # fallback: RAG với ingredient + dish_type để giữ đúng kiểu món user hỏi
        compound_query = " ".join(part for part in [ingredient, dish_type] if part).strip() or keywords
        print(f"[MAIN] strategy: ingredient RAG fallback ('{compound_query}')")
        results = _rag_dishes(compound_query)
        if not results:
            results = _keyword_dishes(compound_query)
        return _filter_dishes_by_type(results, dish_type) if dish_type else results

    if dish_type:
        print(f"[MAIN] strategy: dish_type ('{dish_type}')")
        results = dl.search_dishes(query=dish_type, limit=10)
        strict = _filter_dishes_by_type(results, dish_type)
        return strict if strict else results

    matched_groups = []
    for keyword, group_ids in FAMILY_GROUPS.items():
        if keyword in text:
            matched_groups.extend(group_ids)

    if matched_groups:
        print(f"[MAIN] strategy: family_group {matched_groups}")
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
        print(f"[MAIN] strategy: health_advice")
        goal = id_mod.extract_health_goal(message)
        return dl.get_dishes_by_health_goal(goal, limit=8)

    if intent == "filter_quick":
        max_time = id_mod.extract_time_limit(message)
        print(f"[MAIN] strategy: filter_quick (max_time={max_time}min)")
        return dl.search_dishes(query=keywords, max_time=max_time, limit=8)

    # Cover diet_type (rule-based) and search_dish with diet entity (LLM path)
    # Both map to vegetarian filter when "chay" is present
    is_diet_query = (intent == "diet_type") or (
        intent == "search_dish" and bool(qr.entities.get("diet"))
    )
    if is_diet_query:
        is_veg = "chay" in message.lower() or qr.entities.get("diet") == "chay"
        if is_veg:
            print(f"[MAIN] strategy: is_vegetarian=True  (diet='{qr.entities.get('diet', 'chay in msg')}')")
            return dl.search_dishes(is_vegetarian=True, limit=8)
        print(f"[MAIN] strategy: diet_query ('{qr.search_query}')")
        return dl.search_dishes(query=qr.search_query, limit=8)

    if intent == "greeting":
        print(f"[MAIN] strategy: greeting → no dishes")
        return []

    print(f"[MAIN] strategy: RAG/keyword ('{message[:60]}')")
    dishes = _rag_dishes(message)
    if not dishes:
        dishes = _keyword_dishes(keywords)
    return dishes



def _normalize_shop_text(text: str, *, strip_accents: bool = False) -> str:
    normalized = str(text or "").lower().strip()
    normalized = re.sub(r"\s+", " ", normalized)
    return id_mod.remove_accents(normalized) if strip_accents else normalized


def _contains_whole_phrase(text: str, phrase: str, *, strip_accents: bool = False) -> bool:
    source = _normalize_shop_text(text, strip_accents=strip_accents)
    target = _normalize_shop_text(phrase, strip_accents=strip_accents)
    if not source or not target:
        return False
    return re.search(rf"(?<!\w){re.escape(target)}(?!\w)", source) is not None


def _extract_shop_keyword(message: str, qr: qu.QueryResult) -> str:
    keyword = (
        qr.entities.get("ingredient")
        or (qr.search_query if qr.search_query != "món ngon" else "")
    )
    if keyword:
        return keyword.strip()

    raw = id_mod.extract_keywords(message)
    cleaned_words = [w for w in raw.split() if w not in _SHOP_NOISE_WORDS]
    cleaned = " ".join(cleaned_words).strip()
    return cleaned or raw.strip()


def _pick_shop_retry_token(keyword: str) -> str:
    tokens = [t.strip() for t in keyword.split() if len(t.strip()) >= 3]
    if not tokens:
        return ""
    return max(tokens, key=len)


def _filter_shops_by_keyword(shops: list[dict], keyword: str) -> list[dict]:
    if not shops or not keyword:
        return shops

    exact_matches = []
    normalized_matches = []

    for shop in shops:
        goods = shop.get("goods", []) or []
        exact_goods = [
            g for g in goods
            if _contains_whole_phrase(g.get("ingredient_name", ""), keyword)
        ]
        normalized_goods = [
            g for g in goods
            if _contains_whole_phrase(g.get("ingredient_name", ""), keyword, strip_accents=True)
        ]

        if exact_goods or _contains_whole_phrase(shop.get("stall_name", ""), keyword):
            exact_matches.append({**shop, "goods": exact_goods or goods, "total_goods": len(exact_goods or goods)})
        elif normalized_goods or _contains_whole_phrase(shop.get("stall_name", ""), keyword, strip_accents=True):
            normalized_matches.append({**shop, "goods": normalized_goods or goods, "total_goods": len(normalized_goods or goods)})

    return exact_matches or normalized_matches or shops


def _get_shops_for_message(message: str, filters: dict, qr: qu.QueryResult) -> list[dict]:
    keyword = _extract_shop_keyword(message, qr)

    print(f"[DEBUG] message='{message}' → keyword='{keyword}'")

    shops = dl.search_stalls(
        keyword=keyword,
        min_rating=filters.get("min_rating", 0),
        price_sort=filters.get("price_sort", "asc"),
        limit=5,
    )
    shops = _filter_shops_by_keyword(shops, keyword)

    # Fallback 1: multi-word keyword không match → thử token dài và có nghĩa hơn
    if not shops and keyword and " " in keyword:
        retry_token = _pick_shop_retry_token(keyword)
        if retry_token and retry_token != keyword:
            print(f"[DEBUG] multi-word miss → retry with token '{retry_token}'")
            shops = dl.search_stalls(
                keyword=retry_token,
                min_rating=filters.get("min_rating", 0),
                price_sort=filters.get("price_sort", "asc"),
                limit=5,
            )
            shops = _filter_shops_by_keyword(shops, retry_token)

    # Fallback 2: DB hoàn toàn miss → get_stalls_by_ingredient_name (recipes table)
    if not shops and keyword:
        search_term = _pick_shop_retry_token(keyword) or keyword.strip()
        print(f"[DEBUG] DB miss → ingredient name fallback (keyword='{search_term}')")
        raw = dl.get_stalls_by_ingredient_name(search_term)
        # Normalize flat schema → goods[] schema expected by build_shop_context_block
        for entry in raw:
            shops.append({
                "stall_id":       entry.get("stall_id", ""),
                "stall_name":     entry.get("stall_name", ""),
                "stall_image":    entry.get("stall_image", ""),
                "stall_location": entry.get("stall_location", ""),
                "avr_rating":     entry.get("avr_rating", 0),
                "goods": [{
                    "ingredient_name": entry.get("ingredient_name", ""),
                    "price":           entry.get("price", 0),
                    "unit":            entry.get("unit", ""),
                    "inventory":       entry.get("inventory", 0),
                }],
            })
        shops = _filter_shops_by_keyword(shops, keyword)

    return shops


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
    qr = qu.understand_query(req.message)
    intent = qr.intent

    dishes: list[dict] = []
    shops:  list[dict] = []

    if intent == "search_shop":
        # ── Luồng MỚI: user hỏi gian hàng trực tiếp ──────────────────────
        filters = id_mod.extract_shop_filters(req.message)
        shops   = _get_shops_for_message(req.message, filters, qr)
    else:
        # ── Luồng CŨ: đề xuất món ăn (giữ nguyên toàn bộ logic) ──────────
        dishes = _get_dishes_for_message(req.message, qr)
        dishes = _reuse_session_dishes(session_id, req.message, qr, dishes)

    # Gọi LLM với context phù hợp
    history_dicts = _prepare_history_for_llm(req.history or [], qr.exclude_terms)

    if intent == "cooking_instruction" and dishes:
        reply = _build_cooking_instruction_reply(dishes[0])
    else:
        # Intent không cần DB data (greeting) → gọi LLM trực tiếp
        _no_data_intents = {"greeting"}
        if intent not in _no_data_intents and not dishes and not shops:
            reply = (
                "Xin lỗi, mình không tìm thấy kết quả phù hợp với yêu cầu của bạn. "
                "Bạn có thể thử tìm với từ khóa khác hoặc mô tả cụ thể hơn nhé!"
            )
        else:
            reply = llm.chat_with_llama(
                user_message=req.message,
                context_dishes=dishes,
                context_shops=shops if shops else None,
                history=history_dicts,
            exclude_terms=qr.exclude_terms,
            )

    return {
        "session_id":  session_id,
        "intent":      intent,
        "reply":       reply,
        "dishes":      dishes,      # có data khi hỏi món ăn
        "shops":       shops,       # có data khi hỏi gian hàng
        "total_found": len(dishes) if dishes else len(shops),
        "query_analysis": {
            "search_query":   qr.search_query,
            "exclude_terms":  qr.exclude_terms,
            "entities":       qr.entities,
            "source":         qr.source,
            "confidence":     qr.confidence,
        },
    }


@app.get("/dishes/search", summary="Tìm kiếm món ăn đa tiêu chí (kèm công thức)")
def search_dishes(
    q: str = Query("", description="Từ khoá tìm kiếm (tên món, nguyên liệu)"),
    health_goal: str = Query("", description="Mục tiêu sức khoẻ"),
    max_calories: float = Query(0, description="Calo tối đa (0 = không giới hạn)"),
    min_calories: float = Query(0, description="Calo tối thiểu"),
    level: str = Query("", description="Độ khó: Dễ | Trung bình | Khó"),
    max_time: int = Query(0, description="Thời gian nấu tối đa (phút, 0 = không giới hạn)"),
    limit: int = Query(10, ge=1, le=1000, description="Số lượng kết quả"),
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
    limit: int = Query(5, ge=1, le=1000, description="Số gian hàng trả về"),
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
    # Trích xuất từ khóa dị ứng từ notes (VD: "Dị ứng: tôm, cá" → ["tôm", "cá"])
    allergy_exclude_terms = []
    for note in req.notes:
        if note.startswith("Dị ứng:"):
            raw_allergy = note[len("Dị ứng:"):].strip()
            terms = [t.strip() for t in re.split(r"[,、;]", raw_allergy) if t.strip()]
            allergy_exclude_terms.extend(terms)
        else:
            note_ids.extend(NOTE_GROUPS.get(note, []))

    # Thêm allergen_ingredients từ trường mới nếu có
    if hasattr(req, 'allergen_ingredients') and req.allergen_ingredients:
        allergen_items = [item.strip() for item in req.allergen_ingredients if item.strip()]
        allergy_exclude_terms.extend(allergen_items)

    if allergy_exclude_terms:
        print(f"[menu/generate] 🚫 Lọc dị ứng: {allergy_exclude_terms}")
        print(f"[menu/generate] Tổng cộng {len(allergy_exclude_terms)} nguyên liệu cần loại trừ")

    result = dl.suggest_menu(
        days=req.days,
        health_goal_ids=health_goal_ids,
        note_ids=note_ids,
        meals_per_day=req.meals_per_day,
        exclude_terms=allergy_exclude_terms,
    )

    return {
        "health_goal":   req.health_goal,
        "notes":         req.notes,
        "days":          req.days,
        "meals_per_day": req.meals_per_day,
        "menu":          result["menu"],
        "allergy_excluded": allergy_exclude_terms,
    }

