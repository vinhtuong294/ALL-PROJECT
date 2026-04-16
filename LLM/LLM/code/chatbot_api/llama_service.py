"""
llama_service.py – Wrapper cho Ollama (Qwen2.5).
Tạo phản hồi tiếng Việt từ câu hỏi + context RAG.
Hỗ trợ cả context món ăn và context gian hàng.
"""
import ollama
from typing import Optional

MODEL = "qwen2.5:1.5b"

SYSTEM_PROMPT = """Bạn là **Trợ lý Ẩm thực** của một ứng dụng chợ online bán thực phẩm tươi sống và nguyên liệu nấu ăn.

Nhiệm vụ của bạn:
1. Tư vấn món ăn phù hợp với yêu cầu của khách hàng (thịt, cá, hải sản, rau củ...)
2. Gợi ý thực đơn theo mục tiêu sức khỏe (tăng cân, giảm cân, dinh dưỡng cân bằng)
3. Hướng dẫn cách nấu món ăn khi được hỏi
4. Khi trình bày danh sách món, hãy mô tả ngắn gọn và hấp dẫn
5. Gợi ý gian hàng uy tín bán nguyên liệu khi khách hỏi mua ở đâu
6. Luôn khuyến khích khách hàng mua nguyên liệu qua app

Quy tắc:
- Trả lời bằng **Tiếng Việt** tự nhiên, thân thiện
- Chỉ đề cập thông tin từ context được cung cấp, KHÔNG bịa đặt
- Nếu không có context phù hợp, hãy thành thật nói không tìm thấy
- Giới hạn phản hồi trong khoảng 150-250 từ, súc tích
- Kết thúc lời khuyên bằng câu gợi ý hành động (ví dụ: "Hãy đặt mua ngay qua app!")

Khi tư vấn gian hàng:
- Nêu tên gian hàng, rating, địa điểm
- Liệt kê nguyên liệu nổi bật gian hàng đang bán
- Ưu tiên gian hàng có rating cao và giá hợp lý
"""


def build_context_block(dishes: list[dict]) -> str:
    """Tạo context block từ danh sách món ăn cho LLM."""
    if not dishes:
        return "Không tìm thấy món ăn phù hợp trong cơ sở dữ liệu."
    lines = ["Dưới đây là các món ăn tìm được:\n"]
    for i, d in enumerate(dishes[:6], 1):
        ingredients_str = ", ".join(d["recipe"]["ingredients"][:8]) if d["recipe"]["ingredients"] else "không có"
        lines.append(
            f"{i}. **{d['dish_name']}** "
            f"({d.get('calories', 0):.0f} kcal | {d.get('cooking_time', 'N/A')} | {d.get('level', '')})\n"
            f"   Nguyên liệu chính: {ingredients_str}\n"
            f"   Mục tiêu: {d.get('health_goal', 'Dinh dưỡng cân bằng')}\n"
        )
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

    # Câu hỏi hiện tại kèm context
    user_content = f"""Câu hỏi của khách hàng: {user_message}

--- Thông tin món ăn từ hệ thống ---
{dish_block}
---
{shop_block}

Hãy trả lời câu hỏi dựa vào thông tin trên, bằng tiếng Việt thân thiện."""

    messages.append({"role": "user", "content": user_content})

    try:
        response = ollama.chat(model=MODEL, messages=messages)
        return response["message"]["content"]
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
            "hint":           "Cài Ollama tại https://ollama.ai rồi chạy: ollama pull qwen2.5:1.5b",
        }