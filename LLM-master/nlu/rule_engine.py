"""
nlu/rule_engine.py — FlashText-based Rule Engine cho Food Chatbot.

Kiến trúc:
  - Load từ điển từ config/food_dictionary.json (Singleton pattern)
  - Dùng FlashText O(N) thay vì regex/for-loop để dò từ khóa
  - Sliding Window phủ định: quét N token trước mỗi keyword match,
    nếu gặp negation trigger → đưa keyword vào excluded thay vì included

Output chuẩn:
  {"included": [], "excluded": [], "diets": [], "dish_types": [], "intent": str}
"""
from __future__ import annotations

import json
import logging
import os
import re
from dataclasses import dataclass, field
from typing import Dict, List, Optional

from flashtext import KeywordProcessor

logger = logging.getLogger(__name__)

# ── Paths ────────────────────────────────────────────────────────────────────

_THIS_DIR = os.path.dirname(os.path.abspath(__file__))
_CONFIG_PATH = os.path.join(_THIS_DIR, "..", "config", "food_dictionary.json")

# ── Singleton dictionary holder ──────────────────────────────────────────────

_dictionary: Optional[Dict] = None


def _load_dictionary() -> Dict:
    """Load food_dictionary.json một lần duy nhất (Singleton)."""
    global _dictionary
    if _dictionary is not None:
        return _dictionary

    config_path = os.path.normpath(_CONFIG_PATH)
    with open(config_path, "r", encoding="utf-8") as f:
        _dictionary = json.load(f)
    logger.info("Loaded food dictionary from %s", config_path)
    return _dictionary


def reload_dictionary() -> None:
    """Force reload dictionary (dùng khi hot-update config)."""
    global _dictionary
    _dictionary = None
    _load_dictionary()


# ── FlashText processors (lazy init) ────────────────────────────────────────

_kp_ingredients: Optional[KeywordProcessor] = None
_kp_diets: Optional[KeywordProcessor] = None
_kp_dish_types: Optional[KeywordProcessor] = None
_kp_negation: Optional[KeywordProcessor] = None
_kp_intents: Optional[Dict[str, KeywordProcessor]] = None


def _init_processors() -> None:
    """Build FlashText processors từ dictionary. Gọi 1 lần."""
    global _kp_ingredients, _kp_diets, _kp_dish_types, _kp_negation, _kp_intents

    d = _load_dictionary()

    # Ingredients processor
    _kp_ingredients = KeywordProcessor(case_sensitive=False)
    for surface, canonical in d["ingredients"].items():
        if surface.startswith("_"):
            continue
        _kp_ingredients.add_keyword(surface, canonical)

    # Diets processor
    _kp_diets = KeywordProcessor(case_sensitive=False)
    for surface, canonical in d["diets"].items():
        if surface.startswith("_"):
            continue
        _kp_diets.add_keyword(surface, canonical)

    # Dish types processor
    _kp_dish_types = KeywordProcessor(case_sensitive=False)
    for surface, canonical in d["dish_types"].items():
        if surface.startswith("_"):
            continue
        _kp_dish_types.add_keyword(surface, canonical)

    # Negation trigger processor
    _kp_negation = KeywordProcessor(case_sensitive=False)
    for trigger in d["negation_triggers"]:
        _kp_negation.add_keyword(trigger, trigger)

    # Intent processors — one per intent
    _kp_intents = {}
    for intent_name, keywords in d["intents"].items():
        if intent_name.startswith("_"):
            continue
        kp = KeywordProcessor(case_sensitive=False)
        for kw in keywords:
            kp.add_keyword(kw, intent_name)
        _kp_intents[intent_name] = kp


def _ensure_processors() -> None:
    if _kp_ingredients is None:
        _init_processors()


# ── Sliding Window Negation ──────────────────────────────────────────────────

# Số ký tự tối đa phía trước keyword để tìm negation trigger
_NEGATION_WINDOW_CHARS = 25


_CLAUSE_DELIMITERS = {",", ".", ";", "!", "?"}
_FREEFORM_EXCLUDE_STOPWORDS = {
    "với", "các", "những", "món", "loại", "thứ", "đồ", "thực", "phẩm",
}


def _is_negated(text: str, keyword_start: int) -> bool:
    """
    Kiểm tra keyword tại vị trí `keyword_start` có bị phủ định không.

    Sliding Window có tôn trọng ranh giới mệnh đề:
      1. Từ keyword_start, lùi về tìm clause delimiter gần nhất
      2. Cửa sổ = text[clause_start : keyword_start], giới hạn N ký tự
      3. Chạy FlashText trên cửa sổ để tìm negation trigger
    """
    # Tìm ranh giới mệnh đề gần nhất phía trước keyword
    clause_start = max(0, keyword_start - _NEGATION_WINDOW_CHARS)
    for i in range(keyword_start - 1, clause_start - 1, -1):
        if text[i] in _CLAUSE_DELIMITERS:
            clause_start = i + 1
            break

    window = text[clause_start:keyword_start]
    if not window.strip():
        return False

    assert _kp_negation is not None
    matches = _kp_negation.extract_keywords(window)
    return len(matches) > 0


def _extract_freeform_excludes(text: str) -> List[str]:
    """Fallback: bắt cụm sau trigger phủ định/dị ứng ngay cả khi chưa có trong dictionary."""
    d = _load_dictionary()
    ingredient_map = {
        surface.lower(): canonical
        for surface, canonical in d["ingredients"].items()
        if not surface.startswith("_")
    }

    candidates: List[str] = []
    seen: set[str] = set()
    triggers = sorted(d["negation_triggers"], key=len, reverse=True)

    for trigger in triggers:
        pattern = re.compile(
            rf"{re.escape(trigger)}\s+(.*?)(?=(?:,|\.|;|!|\?|\bnhưng\b|\bvà\b|\bhoặc\b)|$)",
            flags=re.IGNORECASE,
        )
        for match in pattern.finditer(text):
            raw_term = match.group(1).strip()
            raw_term = re.sub(r"^(với|về)\s+", "", raw_term, flags=re.IGNORECASE)
            words = [w for w in raw_term.split() if w.lower() not in _FREEFORM_EXCLUDE_STOPWORDS]
            if not words:
                continue
            candidate = " ".join(words[:4]).strip().lower()
            candidate = ingredient_map.get(candidate, candidate)
            if candidate and candidate not in seen:
                seen.add(candidate)
                candidates.append(candidate)

    return candidates


# ── NLU Result ───────────────────────────────────────────────────────────────

@dataclass
class NLUResult:
    """Kết quả phân tích NLU rule-based."""
    included: List[str] = field(default_factory=list)
    excluded: List[str] = field(default_factory=list)
    diets: List[str] = field(default_factory=list)
    dish_types: List[str] = field(default_factory=list)
    intent: str = "search_general"


# ── Core extraction ──────────────────────────────────────────────────────────

def extract_entities(text: str) -> NLUResult:
    """
    Trích xuất entities từ text bằng FlashText + Sliding Window negation.

    Pipeline:
      1. FlashText extract ingredients với vị trí (start, end)
      2. Với mỗi match, kiểm tra sliding window phủ định
      3. Phân loại: negated → excluded, không negated → included
      4. Tách riêng diets và dish_types
      5. Detect intent từ keyword matching

    Returns:
        NLUResult với included, excluded, diets, dish_types, intent
    """
    _ensure_processors()
    assert _kp_ingredients is not None
    assert _kp_diets is not None
    assert _kp_dish_types is not None
    assert _kp_intents is not None

    text_lower = text.lower().strip()
    result = NLUResult()

    # ── Step 1+2+3: Extract ingredients với negation check ────────────────
    # extract_keywords_with_span_info returns: [(canonical, start, end), ...]
    ingredient_spans = _kp_ingredients.extract_keywords(
        text_lower, span_info=True
    )
    seen_included: set = set()
    seen_excluded: set = set()

    for canonical, start, end in ingredient_spans:
        if _is_negated(text_lower, start):
            if canonical not in seen_excluded:
                seen_excluded.add(canonical)
                result.excluded.append(canonical)
        else:
            if canonical not in seen_included:
                seen_included.add(canonical)
                result.included.append(canonical)

    # Fallback cho cụm phủ định tự do như 'dị ứng với mật ong'
    for candidate in _extract_freeform_excludes(text_lower):
        if candidate not in seen_excluded:
            seen_excluded.add(candidate)
            result.excluded.append(candidate)

    # Nếu một ingredient vừa included vừa excluded → exclude wins
    if seen_included & seen_excluded:
        overlap = seen_included & seen_excluded
        result.included = [t for t in result.included if t not in overlap]

    # ── Step 4: Extract diets ─────────────────────────────────────────────
    diet_matches = _kp_diets.extract_keywords(text_lower)
    seen_diets: set = set()
    for canonical in diet_matches:
        if canonical not in seen_diets:
            seen_diets.add(canonical)
            result.diets.append(canonical)

    # ── Step 4b: Extract dish types ───────────────────────────────────────
    dish_type_matches = _kp_dish_types.extract_keywords(text_lower)
    seen_dish_types: set = set()
    for canonical in dish_type_matches:
        if canonical not in seen_dish_types:
            seen_dish_types.add(canonical)
            result.dish_types.append(canonical)

    # ── Step 5: Detect intent ─────────────────────────────────────────────
    result.intent = detect_intent(text_lower)

    return result


# ── Intent detection ─────────────────────────────────────────────────────────

# Thứ tự ưu tiên intent (cao → thấp)
_INTENT_PRIORITY = [
    "search_shop",
    "greeting",
    "diet_type",
    "menu_planning",
    "health_advice",
    "cooking_instruction",
    "filter_quick",
    "special_occasion",
    "buy_action",
    "family_group",
    "search_general",
]


def detect_intent(text: str) -> str:
    """
    Detect intent bằng FlashText keyword matching theo thứ tự ưu tiên.

    Nếu text chứa ingredient/dish_type nhưng không match intent cụ thể
    → trả về search_ingredient hoặc search_dish_type.
    """
    _ensure_processors()
    assert _kp_intents is not None
    assert _kp_ingredients is not None
    assert _kp_dish_types is not None

    text_lower = text.lower().strip()
    if len(text_lower) < 2:
        return "search_general"

    # Diet check sớm — "chay", "keto" là tín hiệu mạnh, ưu tiên hơn search_general
    diets = _kp_diets.extract_keywords(text_lower)

    # Check theo priority order
    for intent_name in _INTENT_PRIORITY:
        if intent_name not in _kp_intents:
            continue
        matches = _kp_intents[intent_name].extract_keywords(text_lower)
        if matches:
            # Nếu match search_general nhưng có diet → diet_type thắng
            if intent_name == "search_general" and diets:
                return "diet_type"
            return intent_name

    # Fallback: nếu có diet keyword → diet_type
    diets = _kp_diets.extract_keywords(text_lower)
    if diets:
        return "diet_type"

    # Fallback: nếu có ingredient keyword → search_ingredient
    ingredients = _kp_ingredients.extract_keywords(text_lower)
    if ingredients:
        return "search_ingredient"

    # Fallback: nếu có dish_type keyword → search_dish_type
    dish_types = _kp_dish_types.extract_keywords(text_lower)
    if dish_types:
        return "search_dish_type"

    return "search_general"


# ══════════════════════════════════════════════════════════════════════════════
# UNIT TESTS — chạy: python -m nlu.rule_engine
# ══════════════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    import sys

    passed = 0
    failed = 0
    total = 0

    def assert_eq(test_name: str, got, expected) -> None:
        global passed, failed, total
        total += 1
        if got == expected:
            passed += 1
            print(f"  PASS: {test_name}")
        else:
            failed += 1
            print(f"  FAIL: {test_name}")
            print(f"    expected: {expected}")
            print(f"    got:      {got}")

    print("=" * 60)
    print("Unit Tests — nlu/rule_engine.py")
    print("=" * 60)

    # ── Test 1: Basic ingredient extraction ──────────────────────────────
    print("\n[Test 1] Basic ingredient extraction")
    r = extract_entities("tôi muốn nấu thịt bò xào rau")
    assert_eq("included has 'thịt bò'", "thịt bò" in r.included, True)
    assert_eq("included has 'rau'", "rau" in r.included, True)
    assert_eq("excluded is empty", r.excluded, [])

    # ── Test 2: Negation — dị ứng ────────────────────────────────────────
    print("\n[Test 2] Negation — dị ứng tôm")
    r = extract_entities("tôi bị dị ứng tôm, cho tôi món thịt gà")
    assert_eq("excluded has 'tôm'", "tôm" in r.excluded, True)
    assert_eq("included has 'thịt gà'", "thịt gà" in r.included, True)
    assert_eq("tôm NOT in included", "tôm" not in r.included, True)

    # ── Test 3: Negation — không có ──────────────────────────────────────
    print("\n[Test 3] Negation — không có thịt heo")
    r = extract_entities("cho tôi các món không có thịt heo")
    assert_eq("excluded has 'thịt heo'", "thịt heo" in r.excluded, True)
    assert_eq("thịt heo NOT in included", "thịt heo" not in r.included, True)

    # ── Test 4: Diet extraction ──────────────────────────────────────────
    print("\n[Test 4] Diet extraction")
    r = extract_entities("tìm món chay ngon")
    assert_eq("diets has 'chay'", "chay" in r.diets, True)
    assert_eq("intent is diet_type", r.intent, "diet_type")

    # ── Test 5: Dish type extraction ─────────────────────────────────────
    print("\n[Test 5] Dish type extraction")
    r = extract_entities("tôi muốn ăn phở bò")
    assert_eq("dish_types has 'phở'", "phở" in r.dish_types, True)
    assert_eq("included has 'bò'", "bò" in r.included, True)

    # ── Test 6: Synonym normalization — lợn → heo ────────────────────────
    print("\n[Test 6] Synonym normalization — lợn → heo")
    r = extract_entities("thịt lợn kho tiêu")
    assert_eq("included has 'thịt heo' (normalized)", "thịt heo" in r.included, True)

    # ── Test 7: Intent — search_shop ─────────────────────────────────────
    print("\n[Test 7] Intent — search_shop")
    r = extract_entities("tìm gian hàng bán thịt bò gần đây")
    assert_eq("intent is search_shop", r.intent, "search_shop")

    # ── Test 8: Intent — greeting ────────────────────────────────────────
    print("\n[Test 8] Intent — greeting")
    r = extract_entities("xin chào bạn")
    assert_eq("intent is greeting", r.intent, "greeting")

    # ── Test 9: Mixed negation + inclusion ───────────────────────────────
    print("\n[Test 9] Mixed — excluded and included")
    r = extract_entities("tôi không ăn hải sản, cho tôi món gà nướng")
    assert_eq("excluded has 'hải sản'", "hải sản" in r.excluded, True)
    assert_eq("included has 'gà'", "gà" in r.included, True)
    assert_eq("dish_types has 'nướng'", "nướng" in r.dish_types, True)

    # ── Test 10: Complex sentence ────────────────────────────────────────
    print("\n[Test 10] Complex — multiple constraints")
    r = extract_entities("tôi muốn ăn cá hồi nhưng dị ứng với đậu phộng")
    assert_eq("included has 'cá hồi'", "cá hồi" in r.included, True)
    assert_eq("excluded has 'đậu phộng'", "đậu phộng" in r.excluded, True)

    # ── Test 11: Empty/short input ───────────────────────────────────────
    print("\n[Test 11] Edge case — short input")
    r = extract_entities("hi")
    assert_eq("included is empty", r.included, [])
    assert_eq("intent is search_general", r.intent, "search_general")

    # ── Test 12: Dedup — same ingredient mentioned twice ─────────────────
    print("\n[Test 12] Dedup — same ingredient twice")
    r = extract_entities("tôm chiên và tôm hấp")
    assert_eq("tôm appears once in included", r.included.count("tôm"), 1)

    # ── Summary ──────────────────────────────────────────────────────────
    print("\n" + "=" * 60)
    print(f"Results: {passed}/{total} passed, {failed} failed")
    if failed > 0:
        print("SOME TESTS FAILED!")
        sys.exit(1)
    else:
        print("ALL TESTS PASSED!")
        sys.exit(0)
