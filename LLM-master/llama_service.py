"""
llama_service.py – Wrapper cho Ollama (Qwen2.5).
Tạo phản hồi tiếng Việt từ câu hỏi + context RAG.
Hỗ trợ cả context món ăn và context gian hàng.
"""
import ollama
from typing import Optional

MODEL = "qwen2.5:14b"

SYSTEM_PROMPT = """
/no_think
Bạn là **Trợ lý Ẩm thực** của một ứng dụng chợ online bán thực phẩm tươi sống và nguyên liệu nấu ăn.

Nhiệm vụ của bạn:
1. Tư vấn món ăn phù hợp với yêu cầu của khách hàng (thịt, cá, hải sản, rau củ...)
2. Gợi ý thực đơn theo mục tiêu sức khỏe (tăng cân, giảm cân, dinh dưỡng cân bằng)
3. Hướng dẫn cách nấu món ăn khi được hỏi
4. Khi trình bày danh sách món, hãy mô tả ngắn gọn và hấp dẫn
5. Gợi ý gian hàng uy tín bán nguyên liệu khi khách hỏi mua ở đâu
6. Luôn khuyến khích khách hàng mua nguyên liệu qua app

Quy tắc bắt buộc:
- Trả lời bằng **Tiếng Việt** tự nhiên, thân thiện
- Chỉ đề cập thông tin từ context được cung cấp, KHÔNG bịa đặt
- Khi có danh sách món/gian hàng: liệt kê ĐỦ tất cả, mỗi mục 1-2 dòng súc tích; tổng không quá 350 từ
- Nếu context có danh sách món hoặc gian hàng, BẮT BUỘC phải nhắc đến chúng trong câu trả lời
- KHÔNG được nói "không tìm thấy" khi context đã cung cấp dữ liệu
- Kết thúc bằng câu gợi ý hành động ngắn (ví dụ: "Đặt mua ngay qua app!")

Tuyệt đối cấm:
- KHÔNG được nói thông tin "không có", "không được cung cấp" khi context ĐÃ có dữ liệu đó
- KHÔNG được thêm bình luận cá nhân, phân tích ngôn ngữ, hay hỏi ngược lại người dùng
- KHÔNG được viết câu như "Một cách tiếp cận...", "Nói tự nhiên hơn...", hay bất kỳ meta-commentary nào
- KHÔNG được đặt câu hỏi cho người dùng ở cuối câu trả lời

Khi tư vấn gian hàng:
- Nêu tên gian hàng, rating, địa điểm (dùng đúng giá trị trong context, không được nói thiếu)
- Liệt kê nguyên liệu nổi bật gian hàng đang bán
- Ưu tiên gian hàng có rating cao và giá hợp lý
"""


def build_context_block(dishes: list[dict]) -> str:
    """Tạo context block từ danh sách món ăn. Trả về '' nếu rỗng."""
    if not dishes:
        return ""
    lines = [f"Hệ thống tìm được {len(dishes)} món. BẮT BUỘC liệt kê ĐỦ {len(dishes)} món sau trong câu trả lời:\n"]
    for i, d in enumerate(dishes, 1):
        recipe = d.get("recipe") or {}
        ingredients = recipe.get("ingredients") or []
        ingredients_str = ", ".join(ingredients[:8]) if ingredients else "không có"
        steps = (recipe.get("steps") or "").strip()
        prep = (recipe.get("preparation") or "").strip()
        detail_path = d.get("detail_path") or ""
        block = (
            f"{i}. **{d['dish_name']}** "
            f"({d.get('calories', 0):.0f} kcal | {d.get('cooking_time', 'N/A')} | {d.get('level', '')})\n"
            f"   Nguyên liệu chính: {ingredients_str}\n"
            f"   Mục tiêu: {d.get('health_goal', 'Dinh dưỡng cân bằng')}\n"
        )
        if prep:
            block += f"   Sơ chế: {prep[:220]}\n"
        if steps:
            block += f"   Cách làm: {steps[:320]}\n"
        if detail_path:
            block += f"   Đường dẫn chi tiết: {detail_path}\n"
        lines.append(block)
    return "\n".join(lines)


def build_shop_context_block(shops: list[dict]) -> str:
    """Tạo context block từ danh sách gian hàng cho LLM."""
    if not shops:
        return "Không tìm thấy gian hàng phù hợp."
    lines = ["Dưới đây là các gian hàng tìm được:\n"]
    for i, s in enumerate(shops[:5], 1):
        # Hỗ trợ cả 2 format: search_stalls (goods) và get_stalls_for_dish (ingredients_available)
        items = s.get("goods") or s.get("ingredients_available") or []
        goods_preview = ", ".join(
            g.get("ingredient_name", "") for g in items[:4] if g.get("ingredient_name")
        )
        location = s.get("stall_location") or "N/A"
        rating   = s.get("avr_rating", 0)
        lines.append(
            f"{i}. **{s['stall_name']}** "
            f"(⭐ {rating:.1f} | 📍 {location})\n"
            f"   Đang bán: {goods_preview or 'nhiều nguyên liệu tươi'}\n"
        )
    return "\n".join(lines)


def chat_with_llama(
    user_message: str,
    context_dishes: list[dict],
    context_shops: Optional[list[dict]] = None,
    history: Optional[list[dict]] = None,
    exclude_terms: Optional[list[str]] = None,
) -> str:
    """
    Gọi Ollama để tạo phản hồi.

    Args:
        user_message:   Câu hỏi của người dùng
        context_dishes: Danh sách món ăn đã RAG search được
        context_shops:  Danh sách gian hàng (None nếu không có)
        history:        Lịch sử hội thoại [{role, content}, ...]
    Returns:
        Chuỗi phản hồi từ LLM
    """
    # Xây dựng context block
    dish_block = build_context_block(context_dishes)

    shop_block = ""
    if context_shops:
        shop_block = f"""
--- Thông tin gian hàng từ hệ thống ---
{build_shop_context_block(context_shops)}
---"""

    messages = [{"role": "system", "content": SYSTEM_PROMPT}]

    # Thêm history (tối đa 6 lượt gần nhất)
    if history:
        messages.extend(history[-6:])

    # Dish data takes priority; shop data is shown only when no dishes found.
    # When both exist, dishes are shown (shops are accessible via /dishes/{id}/stalls).
    if dish_block:
        context_section = f"--- Thông tin món ăn từ hệ thống ---\n{dish_block}\n---"
    elif shop_block:
        context_section = shop_block.strip()
    else:
        context_section = "Không tìm thấy kết quả phù hợp từ hệ thống."

    exclusion_note = ""
    if exclude_terms:
        banned = ", ".join(t for t in exclude_terms if t)
        if banned:
            exclusion_note = f"\n\nLưu ý bắt buộc: KHÔNG gợi ý món chứa: {banned}. Chỉ dùng các món an toàn trong context ở trên."

    user_content = f"""Câu hỏi của khách hàng: {user_message}

{context_section}{exclusion_note}

Hãy trả lời câu hỏi dựa vào thông tin trên, bằng tiếng Việt thân thiện."""

    messages.append({"role": "user", "content": user_content})

    print(f"\n[LLM] ── chat_with_llama ─────────────────────────────────")
    print(f"[LLM] context: {len(context_dishes)} dishes, {len(context_shops or [])} shops")
    print(f"[LLM] → {user_content[:300]}")

    try:
        response = ollama.chat(model=MODEL, messages=messages)
        reply = response["message"]["content"]
        print(f"[LLM] ← '{reply[:200]}'")
        return reply
    except Exception as e:
        return f"Xin lỗi, tôi đang gặp sự cố kết nối. Vui lòng thử lại sau. (Lỗi: {str(e)[:80]})"


def check_ollama_connection() -> dict:
    """Kiểm tra Ollama đang chạy và model có sẵn."""
    try:
        models = ollama.list()
        available = [m.get("name", str(m)) for m in models.get("models", [])]
        model_ready = any(MODEL in m for m in available)
        return {
            "ollama_running":   True,
            "model_ready":      model_ready,
            "available_models": available,
            "required_model":   MODEL,
            "hint": "" if model_ready else f"Chạy: ollama pull {MODEL}",
        }
    except Exception as e:
        return {
            "ollama_running": False,
            "model_ready":    False,
            "error":          str(e),
            "hint":           f"Cài Ollama tại https://ollama.ai rồi chạy: ollama pull {MODEL}",
        }