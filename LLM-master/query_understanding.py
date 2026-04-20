"""
query_understanding.py — Rule-based query understanding (FlashText).

Kiến trúc mới (thay thế LLM):
  - Lớp 1: FlashText NLU (nlu/rule_engine.py) dò từ khóa O(N)
    + Sliding Window phủ định → included/excluded/diets
  - Code build search_query từ intent + included + entities
  - Không cần LLM, không JSON parsing, zero hallucination

Interface giữ nguyên: understand_query(message) -> QueryResult
"""
import logging
import re
from dataclasses import dataclass, field

import intent_detector as id_mod
from nlu.rule_engine import extract_entities

logger = logging.getLogger(__name__)

VALID_INTENTS = {
    "greeting", "search_dish", "diet_type", "search_shop",
    "health_advice", "filter_quick", "menu_planning", "search_general",
    "search_ingredient", "special_occasion", "family_group", "buy_action",
    "cooking_instruction", "search_dish_type",
}

# Đồng nghĩa cần chuẩn hóa (lowercase → canonical)
_SYNONYMS: dict[str, str] = {
    "lợn": "heo",
}


@dataclass
class QueryResult:
    intent: str
    search_query: str
    exclude_terms: list[str] = field(default_factory=list)
    entities: dict[str, str] = field(default_factory=dict)
    raw_message: str = ""
    source: str = "rule"       # "rule" (luôn luôn rule-based giờ)
    confidence: float = 0.0


# ── Term processing (giữ nguyên interface cho tests + internal use) ──────────

def canonicalize_term(term: str) -> str:
    """Chuẩn hóa term: lowercase, trim, normalize synonym."""
    t = term.lower().strip()
    return _SYNONYMS.get(t, t)


def sanitize_include_exclude(
    include: list[str], exclude: list[str]
) -> tuple[list[str], list[str]]:
    """
    Chuẩn hóa include/exclude:
    - canonicalize + dedupe (giữ thứ tự)
    - xóa term khỏi include nếu trùng exclude (exclude luôn ưu tiên)
    """
    def _clean(terms: list[str]) -> list[str]:
        seen: set[str] = set()
        out = []
        for t in terms:
            c = canonicalize_term(t)
            if c and c not in seen:
                seen.add(c)
                out.append(c)
        return out

    clean_include = _clean(include)
    clean_exclude = _clean(exclude)
    exclude_set = set(clean_exclude)
    clean_include = [t for t in clean_include if t not in exclude_set]
    return clean_include, clean_exclude


def build_search_query(intent: str, include_terms: list[str], entities: dict) -> str:
    """
    Build search_query từ intent + include_terms + entities.
    """
    # search_ingredient / search_shop: ưu tiên ingredient entity
    if intent in ("search_ingredient", "search_shop"):
        raw = entities.get("ingredient", "").strip()
    else:
        raw = ""

    if not raw and include_terms:
        raw = " ".join(include_terms)

    if not raw:
        return "món ngon"

    return re.sub(r'^tìm\s+', '', raw)


# ── Main entry ────────────────────────────────────────────────────────────────

def understand_query(message: str) -> QueryResult:
    """
    Phân tích câu hỏi bằng FlashText rule-based NLU.

    Pipeline:
      1. extract_entities() → NLUResult (included, excluded, diets, dish_types, intent)
      2. Build entities dict cho main.py (ingredient, diet, dish_type)
      3. sanitize include/exclude
      4. build_search_query từ code
    """
    print(f"\n[QU] ── understand_query ─────────────────────────────────")
    print(f"[QU] input: '{message}'")

    nlu = extract_entities(message)

    # ── Validate intent ──────────────────────────────────────────────────
    intent = nlu.intent
    if intent not in VALID_INTENTS:
        intent = "search_general"

    # ── Build entities dict (backward compat với main.py) ────────────────
    entities: dict[str, str] = {}

    # Ingredient entity: main.py dùng qr.entities.get("ingredient")
    if nlu.included:
        entities["ingredient"] = nlu.included[0]

    # Diet entity
    if nlu.diets:
        entities["diet"] = nlu.diets[0]

    # Dish type entity
    if nlu.dish_types:
        entities["dish_type"] = nlu.dish_types[0]

    # ── Sanitize include/exclude ─────────────────────────────────────────
    clean_include, clean_exclude = sanitize_include_exclude(
        nlu.included, nlu.excluded
    )

    # ── Build search_query ───────────────────────────────────────────────
    search_query = build_search_query(intent, clean_include, entities)

    # Confidence: rule-based luôn 1.0 (deterministic, không phải LLM guess)
    confidence = 1.0

    result = QueryResult(
        intent=intent,
        search_query=search_query,
        exclude_terms=clean_exclude,
        entities=entities,
        raw_message=message,
        source="rule",
        confidence=confidence,
    )

    print(f"[QU] result: intent={result.intent}  src={result.source}")
    print(f"[QU] → search_query='{result.search_query}'  exclude={result.exclude_terms}  entities={result.entities}")
    return result
