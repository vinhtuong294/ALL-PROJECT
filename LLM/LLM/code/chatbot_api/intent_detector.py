"""
intent_detector.py – Nhận diện intent từ câu hỏi người dùng tiếng Việt.
Trả về intent name để main.py chọn đúng pipeline xử lý.
"""
import re

INTENT_RULES: list[tuple[str, list[str]]] = [
    # ── Chào hỏi / hội thoại ──────────────────────────────
    ("greeting", [
        "xin chào", "chào", "hello", "hi bạn", "chào bạn",
        "bạn là ai", "bạn có thể làm gì", "giới thiệu",
        "cảm ơn", "cám ơn", "thank", "bye", "tạm biệt",
    ]),

    # ── Tìm gian hàng (LUỒNG MỚI) ─────────────────────────
    ("search_shop", [
        "gian hàng", "cửa hàng", "shop", "quán bán",
        "nơi bán", "chỗ bán", "mua ở đâu", "bán ở đâu",
        "tìm quán", "tìm cửa hàng", "gợi ý quán",
        "đánh giá cao", "uy tín", "rating cao",
        "gian hàng nào", "shop nào", "hàng nào bán",
        "có bán không", "ai bán", "mua được không",
        "tìm gian", "gợi ý gian hàng",
    ]),
    
        # ── Tìm theo nguyên liệu chính (thịt/cá) ─────────────
    ("search_ingredient", [
        "thịt bò", "thịt heo", "thịt gà", "thịt vịt", "thịt dê",
        "cá hồi", "cá thu", "cá lóc", "cá chép", "cá ngừ",
        "tôm", "cua", "mực", "hải sản", "bạch tuộc", "nghêu", "sò",
        "thịt", "cá", "gà", "vịt", "heo",
    ]),

    # ── Lên thực đơn / menu planning ──────────────────────
    ("menu_planning", [
        "thực đơn", "menu", "lên thực đơn", "gợi ý thực đơn",
        "7 ngày", "3 ngày", "1 tuần", "cả tuần",
        "bữa sáng bữa trưa bữa tối", "sáng trưa tối",
        "kế hoạch ăn", "lịch ăn", "plan ăn uống",
    ]),

    # ── Tư vấn sức khỏe / dinh dưỡng ─────────────────────
    ("health_advice", [
        "tăng cân", "tăng cân nhanh", "gầy muốn tăng",
        "giảm cân", "ăn kiêng", "low calorie", "ít calo",
        "dinh dưỡng", "protein", "bổ sung", "năng lượng cao",
        "người già", "trẻ em", "phụ nữ mang thai", "bà bầu",
        "tiểu đường", "huyết áp", "tim mạch", "khỏe mạnh",
    ]),

    # ── Hỏi cách nấu / công thức ─────────────────────────
    ("cooking_instruction", [
        "cách nấu", "công thức", "làm thế nào", "nấu như thế nào",
        "dạy tôi", "hướng dẫn", "bước thực hiện",
        "sơ chế", "nguyên liệu cần gì", "cần những gì để nấu",
        "làm sao nấu", "nấu ra sao",
    ]),

    # ── Lọc thời gian / độ khó ───────────────────────────
    ("filter_quick", [
        "nấu nhanh", "nhanh", "dưới 15 phút", "dưới 20 phút",
        "dưới 30 phút", "15 phút", "20 phút",
        "dễ làm", "đơn giản", "người mới", "không cần kỹ năng",
        "không cần nấu", "không cần bếp",
    ]),


    # ── Tìm theo nhóm món (tên kiểu nấu) ─────────────────
    ("search_dish_type", [
        "canh", "súp", "lẩu", "gỏi", "salad",
        "xào", "chiên", "nướng", "hấp", "kho", "rim",
        "cuộn", "bánh", "cháo", "bún", "phở", "mì", "cơm",
        "pizza", "burger", "sandwich",
    ]),

    # ── Tiệc / dịp đặc biệt / số người ──────────────────
    ("special_occasion", [
        "tiệc", "tiệc gia đình", "đãi khách", "đám giỗ",
        "sinh nhật", "lễ tết", "giáng sinh",
        "4 người", "6 người", "nhiều người", "đông người",
        "lãng mạn", "hẹn hò", "bữa tối sang",
    ]),

    # ── Chế độ ăn đặc biệt ────────────────────────────────
    ("diet_type", [
        "chay", "thuần chay", "vegetarian", "vegan",
        "không thịt", "không cá", "gluten free",
        "keto", "eat clean",
    ]),

    # ── Mua hàng ──────────────────────────────────────────
    ("buy_action", [
        "mua", "đặt mua", "order", "thêm vào giỏ", "mua ngay",
        "đặt hàng", "tôi muốn mua", "cho tôi mua",
    ]),

    # ── Tìm kiếm chung ────────────────────────────────────
    ("search_general", [
        "gợi ý", "đề xuất", "cho tôi xem", "tìm món",
        "món gì ngon", "ăn gì", "hôm nay ăn gì",
        "muốn ăn", "thèm ăn", "không biết ăn gì",
        "có gì ngon", "gợi ý món", "món nào ngon",
    ]),

    # ── Nhóm gia đình ─────────────────────────────────────
    ("family_group", [
        "trẻ em", "con nít", "con nhỏ", "em bé", "bé",
        "người già", "người lớn tuổi", "ông bà",
        "bà bầu", "mang thai", "phụ nữ có thai",
        "cả nhà", "gia đình",
    ]),
]


def detect_intent(message: str) -> str:
    text = message.lower().strip()

    if len(text) < 3:
        return "unknown"

    # ✅ Kiểm tra search_shop TRƯỚC và RIÊNG — không để bị override
    SHOP_KEYWORDS = [
        "gian hàng", "cửa hàng", "shop", "quán bán",
        "nơi bán", "chỗ bán", "mua ở đâu", "bán ở đâu",
        "tìm quán", "tìm cửa hàng", "đánh giá cao",
        "uy tín", "rating cao", "gian hàng nào", "shop nào",
        "có bán không", "ai bán", "mua được không",
    ]
    for kw in SHOP_KEYWORDS:
        if kw in text:
            return "search_shop"

    # Sau đó mới check các intent khác
    for intent, keywords in INTENT_RULES:
        if intent == "search_shop":
            continue  # đã check ở trên rồi
        for kw in keywords:
            if kw in text:
                return intent

    return "search_general"


def extract_health_goal(message: str) -> str:
    """Map câu hỏi → health_goal cụ thể trong DB."""
    text = message.lower()
    if any(kw in text for kw in ["tăng cân", "gầy", "năng lượng cao", "nhiều calo"]):
        return "Tăng cân / Năng lượng cao"
    if any(kw in text for kw in ["giảm cân", "ăn nhẹ", "ít calo", "kiêng"]):
        return "Giảm cân / Ăn nhẹ"
    return "Dinh dưỡng cân bằng"


def extract_time_limit(message: str) -> int:
    """Trích xuất giới hạn thời gian nấu từ câu hỏi. 0 = không giới hạn."""
    m = re.search(r"(\d+)\s*phút", message)
    if m:
        return int(m.group(1))
    if "nhanh" in message.lower():
        return 20
    return 0


def extract_keywords(message: str) -> str:
    """Trích keywords để search (bỏ stop words thừa)."""
    stop = {"cho", "tôi", "xem", "các", "món", "có", "gì", "là", "và",
        "một", "những", "của", "được", "không", "thì", "mà", "cần",
        "muốn", "hãy", "nhé", "đi", "ạ", "vậy", "thôi",
        # Chỉ giữ các từ thực sự vô nghĩa trong context tìm kiếm
        "nơi", "chỗ", "gợi", "ý", "nào", "đâu"}
    words = message.lower().split()
    filtered = [w for w in words if w not in stop and len(w) > 0]
    return " ".join(filtered)


def extract_shop_filters(message: str) -> dict:
    """Trích xuất bộ lọc gian hàng từ câu hỏi."""
    text = message.lower()
    filters = {}

    # Rating
    if any(kw in text for kw in ["uy tín", "đánh giá cao", "rating cao", "tốt nhất", "chất lượng"]):
        filters["min_rating"] = 4.0

    # Giá
    if any(kw in text for kw in ["rẻ", "bình dân", "giá thấp", "tiết kiệm", "giá rẻ"]):
        filters["price_sort"] = "asc"
    elif any(kw in text for kw in ["cao cấp", "sang", "chất lượng cao", "premium"]):
        filters["price_sort"] = "desc"
    else:
        filters["price_sort"] = "asc"  # mặc định giá thấp trước

    return filters

def remove_accents(text: str) -> str:
    """Chuyển tiếng Việt có dấu → không dấu để so sánh."""
    accents = {
        'à':'a','á':'a','ả':'a','ã':'a','ạ':'a',
        'ă':'a','ắ':'a','ằ':'a','ẳ':'a','ẵ':'a','ặ':'a',
        'â':'a','ấ':'a','ầ':'a','ẩ':'a','ẫ':'a','ậ':'a',
        'è':'e','é':'e','ẻ':'e','ẽ':'e','ẹ':'e',
        'ê':'e','ế':'e','ề':'e','ể':'e','ễ':'e','ệ':'e',
        'ì':'i','í':'i','ỉ':'i','ĩ':'i','ị':'i',
        'ò':'o','ó':'o','ỏ':'o','õ':'o','ọ':'o',
        'ô':'o','ố':'o','ồ':'o','ổ':'o','ỗ':'o','ộ':'o',
        'ơ':'o','ớ':'o','ờ':'o','ở':'o','ỡ':'o','ợ':'o',
        'ù':'u','ú':'u','ủ':'u','ũ':'u','ụ':'u',
        'ư':'u','ứ':'u','ừ':'u','ử':'u','ữ':'u','ự':'u',
        'ỳ':'y','ý':'y','ỷ':'y','ỹ':'y','ỵ':'y',
        'đ':'d',
    }
    result = text.lower()
    for k, v in accents.items():
        result = result.replace(k, v)
    return result