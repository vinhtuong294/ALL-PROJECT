"""
data_loader.py – Load và index tất cả dữ liệu cho chatbot.
- dishes, recipes, ingredients, dish_group: từ PostgreSQL
- rag_menu_final: từ CSV (giữ nguyên)
"""
from __future__ import annotations
from typing import Optional, List
import pandas as pd
import psycopg2
import os
import re

from db_config import get_engine

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ─── Load từ PostgreSQL ──────────────────────────────────────────────────────
def _load_table(table_name: str) -> pd.DataFrame:
    try:
        engine = get_engine()
        df = pd.read_sql(f"SELECT * FROM {table_name}", engine)
        print(f"[data_loader] ✅ Loaded '{table_name}' — {len(df)} rows")
        return df
    except Exception as e:
        print(f"[data_loader] ❌ Lỗi load bảng '{table_name}': {e}")
        return pd.DataFrame()

# ─── Load từ CSV (chỉ dùng cho rag_menu_final) ──────────────────────────────
def _load_csv(filename: str) -> pd.DataFrame:
    path = os.path.join(BASE_DIR, filename)
    return pd.read_csv(path, on_bad_lines='skip')

# ─── Load all ────────────────────────────────────────────────────────────────
def load_all_data():
    """Load và merge toàn bộ dữ liệu vào một dict dễ dùng."""

    print("[data_loader] Loading dishes...")
    dishes_df = _load_table("dishes")

    print("[data_loader] Loading recipes...")
    recipes_df = _load_table("recipes")

    print("[data_loader] Loading ingredients...")
    ingredients_df = _load_table("ingredients")

    print("[data_loader] Loading dish groups...")
    groups_df = _load_table("dish_group")

    print("[data_loader] Loading rag_menu_final...")
    rag_df = _load_csv("rag_menu_final.csv")
    rag_df = rag_df.dropna(subset=['dish_id', 'rag_context'])
    rag_df = rag_df[rag_df['dish_id'].str.startswith('M', na=False)]
    rag_df = rag_df.drop_duplicates(subset='dish_id')

    dishes_df.columns = [c.strip() for c in dishes_df.columns]
    rag_df.columns    = [c.strip() for c in rag_df.columns]

    rag_fields = rag_df[['dish_id', 'health_goal', 'calories', 'rag_context']].copy()
    rag_fields = rag_fields.rename(columns={'calories': 'kcal'})
    merged = pd.merge(dishes_df, rag_fields, on='dish_id', how='left')

    if 'ingredient_id' in recipes_df.columns:
        recipe_map = (
            recipes_df.dropna(subset=['dish_id', 'ingredient_name'])
            .groupby('dish_id')['ingredient_name']
            .apply(list)
            .to_dict()
        )
    else:
        recipe_map = {}

    return {
        "dishes":      merged,
        "rag":         rag_df,
        "recipes":     recipe_map,
        "ingredients": ingredients_df,
        "groups":      groups_df,
    }

# ── Singleton ─────────────────────────────────────────────────────────────────
_DATA = None

def get_data():
    global _DATA
    if _DATA is None:
        _DATA = load_all_data()
    return _DATA

# ─── Helper: Build full dish response dict ───────────────────────────────────
def build_dish_response(row) -> dict:
    data = get_data()
    dish_id = str(row.get('dish_id', ''))
    ingredients = data["recipes"].get(dish_id, [])
    steps = _safe_str(row.get('steps', ''))
    prep  = _safe_str(row.get('prep',  ''))
    serve = _safe_str(row.get('serve', ''))
    return {
        "dish_id":      dish_id,
        "dish_name":    _safe_str(row.get('dish_name', '')),
        "image_url":    _safe_str(row.get('dish_image', '')),
        "calories":     _safe_float(row.get('kcal') or row.get('calories', 0)),
        "health_goal":  _safe_str(row.get('health_goal', 'Dinh dưỡng cân bằng')),
        "cooking_time": _safe_str(row.get('cooking_time', '')),
        "level":        _safe_str(row.get('level', '')),
        "servings":     _safe_str(row.get('servings', '')),
        "recipe": {
            "ingredients":  ingredients,
            "preparation":  prep,
            "steps":        steps,
            "serving_tips": serve,
        },
        "buy_action": {
            "dish_id": dish_id,
            "label":   "🛒 Mua ngay",
        },
    }

def _safe_str(val) -> str:
    if val is None or (isinstance(val, float) and pd.isna(val)):
        return ""
    return str(val).strip()

def _safe_float(val) -> float:
    try:
        return float(val)
    except Exception:
        return 0.0

# ─── Search / Filter dishes ──────────────────────────────────────────────────
def search_dishes(
    query: str = "",
    health_goal: str = "",
    max_calories: float = 0,
    min_calories: float = 0,
    level: str = "",
    max_time: int = 0,
    limit: int = 10,
) -> List[dict]:
    data = get_data()
    df = data["dishes"].copy()

    if query:
        q = query.lower()
        mask = (
            df['dish_name'].str.lower().str.contains(q, na=False) |
            df['rag_context'].astype(str).str.lower().str.contains(q, na=False)
        )
        df = df[mask]

    if health_goal:
        df = df[df['health_goal'].astype(str).str.contains(health_goal, na=False)]

    cal_col = 'kcal' if 'kcal' in df.columns else 'calories'
    if max_calories > 0:
        df = df[pd.to_numeric(df[cal_col], errors='coerce').fillna(0) <= max_calories]
    if min_calories > 0:
        df = df[pd.to_numeric(df[cal_col], errors='coerce').fillna(0) >= min_calories]

    if level:
        df = df[df['level'].astype(str).str.lower().str.contains(level.lower(), na=False)]

    if max_time > 0:
        def parse_time(t):
            m = re.search(r'(\d+)', str(t))
            return int(m.group(1)) if m else 9999
        df = df[df['cooking_time'].apply(parse_time) <= max_time]

    df = df.head(limit)
    return [build_dish_response(row) for _, row in df.iterrows()]

def get_dish_by_id(dish_id: str) -> Optional[dict]:
    data = get_data()
    df = data["dishes"]
    rows = df[df['dish_id'] == dish_id]
    if rows.empty:
        return None
    return build_dish_response(rows.iloc[0])

def get_dishes_by_health_goal(health_goal: str, limit: int = 20) -> List[dict]:
    return search_dishes(health_goal=health_goal, limit=limit)

def get_all_health_goals() -> List[str]:
    data = get_data()
    goals = data["rag"]['health_goal'].dropna().unique().tolist()
    return [g for g in goals if g]

# ─── Gian hàng theo món ăn (luồng cũ — giữ nguyên) ─────────────────────────
def get_stalls_for_dish(dish_id: str) -> list[dict]:
    """Tìm gian hàng bán nguyên liệu của một món ăn."""
    try:
        engine = get_engine()

        recipes_df = pd.read_sql(
            f"SELECT ingredient_id FROM recipes WHERE dish_id = '{dish_id}'",
            engine
        )

        if recipes_df.empty:
            return []

        ingredient_ids = recipes_df['ingredient_id'].dropna().tolist()
        if not ingredient_ids:
            return []

        ids_str = ", ".join([f"'{i}'" for i in ingredient_ids])

        query = f"""
            SELECT
                s.stall_id,
                s.stall_name,
                s.stall_image,
                s.stall_location,
                s.avr_rating,
                i.ingredient_id,
                i.ingredient_name,
                g.good_image,
                g.good_price,
                g.final_price,
                g.unit,
                g.inventory,
                g.discount
            FROM goods g
            JOIN stall s ON g.stall_id = s.stall_id
            JOIN ingredients i ON g.ingredient_id = i.ingredient_id
            WHERE g.ingredient_id IN ({ids_str})
              AND g.inventory > 0
            ORDER BY s.avr_rating DESC, g.final_price ASC
        """

        df = pd.read_sql(query, engine)
        if df.empty:
            return []

        result = []
        for stall_id, group in df.groupby('stall_id'):
            stall_info = group.iloc[0]
            ingredients_available = []
            for _, row in group.iterrows():
                ingredients_available.append({
                    "ingredient_id":   row['ingredient_id'],
                    "ingredient_name": row['ingredient_name'],
                    "good_image":      row['good_image'] or "",
                    "price":           float(row['final_price'] or row['good_price'] or 0),
                    "unit":            row['unit'] or "",
                    "inventory":       float(row['inventory'] or 0),
                    "discount":        float(row['discount'] or 0),
                })

            result.append({
                "stall_id":               stall_id,
                "stall_name":             stall_info['stall_name'],
                "stall_image":            stall_info['stall_image'] or "",
                "stall_location":         stall_info['stall_location'] or "",
                "avr_rating":             float(stall_info['avr_rating'] or 0),
                "ingredients_available":  ingredients_available,
                "total_ingredients_sold": len(ingredients_available),
            })

        total_ingredients_needed = len(ingredient_ids)
        for stall in result:
            stall['total_price']    = sum(i['price'] for i in stall['ingredients_available'])
            stall['coverage_ratio'] = stall['total_ingredients_sold'] / total_ingredients_needed

        result.sort(key=lambda x: (
            -x['coverage_ratio'],
             x['total_price'],
            -x['avr_rating'],
        ))

        return result[:5]

    except Exception as e:
        print(f"[data_loader] ❌ Lỗi get_stalls_for_dish: {e}")
        return []

# ─── Gian hàng theo tên nguyên liệu (luồng cũ — giữ nguyên) ────────────────
def get_stalls_by_ingredient_name(ingredient_name: str) -> list[dict]:
    """Tìm gian hàng bán nguyên liệu theo tên."""
    try:
        engine = get_engine()

        id_query = f"""
            SELECT DISTINCT ingredient_id
            FROM recipes
            WHERE LOWER(ingredient_name) = LOWER('{ingredient_name}')
            LIMIT 1
        """
        id_df = pd.read_sql(id_query, engine)

        if id_df.empty:
            id_query = f"""
                SELECT DISTINCT ingredient_id
                FROM recipes
                WHERE LOWER(ingredient_name) LIKE LOWER('%{ingredient_name}%')
                LIMIT 1
            """
            id_df = pd.read_sql(id_query, engine)

        if id_df.empty:
            return []

        ingredient_id = id_df.iloc[0]['ingredient_id']

        query = f"""
            SELECT
                s.stall_id,
                s.stall_name,
                s.stall_image,
                s.stall_location,
                s.avr_rating,
                i.ingredient_name,
                g.good_image,
                g.good_price,
                g.final_price,
                g.unit,
                g.inventory,
                g.discount
            FROM goods g
            JOIN stall s ON g.stall_id = s.stall_id
            JOIN ingredients i ON g.ingredient_id = i.ingredient_id
            WHERE g.ingredient_id = '{ingredient_id}'
              AND g.inventory > 0
            ORDER BY g.final_price ASC, s.avr_rating DESC
        """

        df = pd.read_sql(query, engine)
        if df.empty:
            return []

        result = []
        for _, row in df.iterrows():
            result.append({
                "stall_id":        row['stall_id'],
                "stall_name":      row['stall_name'],
                "stall_image":     row['stall_image'] or "",
                "stall_location":  row['stall_location'] or "",
                "avr_rating":      float(row['avr_rating'] or 0),
                "ingredient_name": row['ingredient_name'],
                "good_image":      row['good_image'] or "",
                "price":           float(row['final_price'] or row['good_price'] or 0),
                "unit":            row['unit'] or "",
                "inventory":       float(row['inventory'] or 0),
                "discount":        float(row['discount'] or 0),
            })

        return result[:10]

    except Exception as e:
        print(f"[data_loader] ❌ Lỗi get_stalls_by_ingredient_name: {e}")
        return []

# ─── Gian hàng theo keyword (luồng MỚI — chat hỏi gian hàng) ───────────────
def search_stalls(
    keyword: str = "",
    min_rating: float = 0,
    price_sort: str = "asc",
    limit: int = 5,
) -> list[dict]:
    """
    Tìm gian hàng theo keyword tự do (tên nguyên liệu, tên gian hàng...).
    Dùng khi user chat hỏi trực tiếp về gian hàng.
    """
    try:
        engine = get_engine()
        where_clauses = ["g.inventory > 0"]

        if keyword:
            words = [w.strip() for w in keyword.split() if len(w.strip()) > 1]
            if words:
                full_phrase = keyword.strip()
                conds = []

                # Tìm cụm đầy đủ trước (VD: "thịt bò")
                conds.append(
                    f"(unaccent(LOWER(i.ingredient_name)) LIKE unaccent(LOWER('%{full_phrase}%')) "
                    f"OR unaccent(LOWER(s.stall_name)) LIKE unaccent(LOWER('%{full_phrase}%')))"
                )

                # Fallback từng từ riêng
                for word in words:
                    conds.append(
                        f"(unaccent(LOWER(i.ingredient_name)) LIKE unaccent(LOWER('%{word}%')) "
                        f"OR unaccent(LOWER(s.stall_name)) LIKE unaccent(LOWER('%{word}%')))"
                    )

                where_clauses.append(f"({' OR '.join(conds)})")

        if min_rating > 0:
            where_clauses.append(f"s.avr_rating >= {min_rating}")

        where_sql = " AND ".join(where_clauses)
        order_price = "g.final_price ASC" if price_sort == "asc" else "g.final_price DESC"

        query = f"""
            SELECT
                s.stall_id,
                s.stall_name,
                s.stall_image,
                s.stall_location,
                s.avr_rating,
                i.ingredient_name,
                g.good_image,
                g.good_price,
                g.final_price,
                g.unit,
                g.inventory,
                g.discount
            FROM goods g
            JOIN stall s ON g.stall_id = s.stall_id
            JOIN ingredients i ON g.ingredient_id = i.ingredient_id
            WHERE {where_sql}
            ORDER BY s.avr_rating DESC, {order_price}
            LIMIT {limit * 8}
        """

        df = pd.read_sql(query, engine)
        if df.empty:
            return []

        result = []
        seen_stall_ids = set()

        for stall_id, group in df.groupby('stall_id'):
            if stall_id in seen_stall_ids:
                continue
            seen_stall_ids.add(stall_id)

            stall_info = group.iloc[0]
            goods = []
            for _, row in group.iterrows():
                goods.append({
                    "ingredient_name": row['ingredient_name'],
                    "good_image":      row['good_image'] or "",
                    "price":           float(row['final_price'] or row['good_price'] or 0),
                    "unit":            row['unit'] or "",
                    "inventory":       float(row['inventory'] or 0),
                    "discount":        float(row['discount'] or 0),
                })

            result.append({
                "stall_id":       stall_id,
                "stall_name":     stall_info['stall_name'],
                "stall_image":    stall_info['stall_image'] or "",
                "stall_location": stall_info['stall_location'] or "",
                "avr_rating":     float(stall_info['avr_rating'] or 0),
                "goods":          goods,
                "total_goods":    len(goods),
            })

        result.sort(key=lambda x: (-x['avr_rating'], -x['total_goods']))
        return result[:limit]

    except Exception as e:
        print(f"[data_loader] ❌ Lỗi search_stalls: {e}")
        return []
    
# ─── Gợi ý thực đơn ──────────────────────────────────────────────────────────
def suggest_menu(days: int = 1, health_goal_ids: list = None, note_ids: list = None, meals_per_day: int = 3) -> dict:
    """Gợi ý thực đơn theo ngày dựa trên dish_classification."""
    try:
        engine = get_engine()

        MEAL_GROUPS = {
            "🌅 Sáng": "DM05",
            "☀️ Trưa": "DM06",
            "🌙 Tối":  "DM07",
        }
        MEALS = list(MEAL_GROUPS.items())[:meals_per_day]

        all_group_ids = []
        if health_goal_ids:
            all_group_ids.extend(health_goal_ids)
        if note_ids:
            all_group_ids.extend(note_ids)

        menu = []
        used_dish_ids = set()

        for day in range(1, days + 1):
            meals = []
            for meal_label, meal_group_id in MEALS:

                if all_group_ids:
                    ids_str = ", ".join([f"'{i}'" for i in all_group_ids])
                    query = f"""
                        SELECT DISTINCT d.dish_id, d.dish_name, d.dish_image,
                               d.cooking_time, d.level, d.servings,
                               d.steps, d.prep, d.serve, d.calories
                        FROM dish_classification dc1
                        JOIN dish_classification dc2 ON dc1.dish_id = dc2.dish_id
                        JOIN dishes d ON dc1.dish_id = d.dish_id
                        WHERE dc1.group_id = '{meal_group_id}'
                          AND dc2.group_id IN ({ids_str})
                        ORDER BY RANDOM()
                        LIMIT 20
                    """
                else:
                    query = f"""
                        SELECT DISTINCT d.dish_id, d.dish_name, d.dish_image,
                               d.cooking_time, d.level, d.servings,
                               d.steps, d.prep, d.serve, d.calories
                        FROM dish_classification dc
                        JOIN dishes d ON dc.dish_id = d.dish_id
                        WHERE dc.group_id = '{meal_group_id}'
                        ORDER BY RANDOM()
                        LIMIT 20
                    """

                df = pd.read_sql(query, engine)
                df = df[~df['dish_id'].isin(used_dish_ids)]

                if df.empty:
                    fallback = f"""
                        SELECT DISTINCT d.dish_id, d.dish_name, d.dish_image,
                               d.cooking_time, d.level, d.servings,
                               d.steps, d.prep, d.serve, d.calories
                        FROM dish_classification dc
                        JOIN dishes d ON dc.dish_id = d.dish_id
                        WHERE dc.group_id = '{meal_group_id}'
                        ORDER BY RANDOM()
                        LIMIT 20
                    """
                    df = pd.read_sql(fallback, engine)
                    df = df[~df['dish_id'].isin(used_dish_ids)]

                if not df.empty:
                    row = df.iloc[0]
                    used_dish_ids.add(row['dish_id'])
                    dish = build_dish_response(row)
                    meals.append({"meal": meal_label, "dish": dish})

            menu.append({"day": day, "meals": meals})

        return {"days": days, "meals_per_day": meals_per_day, "menu": menu}

    except Exception as e:
        print(f"[data_loader] ❌ Lỗi suggest_menu: {e}")
        return {"days": days, "menu": []}