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
from sqlalchemy import text

PUBLIC_API_BASE_URL = os.getenv("CHATBOT_PUBLIC_API_BASE_URL", "http://localhost:8001").rstrip("/")

from db_config import get_engine

APP_DIR = os.path.dirname(os.path.abspath(__file__))
LEGACY_DATA_DIR = os.path.dirname(APP_DIR)

# ─── Load từ PostgreSQL ──────────────────────────────────────────────────────
def _load_table(table_name: str) -> pd.DataFrame:
    try:
        engine = get_engine()
        df = pd.read_sql(f"SELECT * FROM {table_name}", engine)
        return df
    except Exception as e:
        return pd.DataFrame()

# ─── Load từ CSV (chỉ dùng cho rag_menu_final) ──────────────────────────────
def _load_csv(filename: str) -> pd.DataFrame:
    preferred_path = os.path.join(APP_DIR, filename)
    legacy_path = os.path.join(LEGACY_DATA_DIR, filename)
    path = preferred_path if os.path.exists(preferred_path) else legacy_path
    df = pd.read_csv(path, on_bad_lines='skip')
    return df

# ─── Load all ────────────────────────────────────────────────────────────────
def load_all_data():
    """Load và merge toàn bộ dữ liệu vào một dict dễ dùng."""
    dishes_df      = _load_table("dishes")
    recipes_df     = _load_table("recipes")
    ingredients_df = _load_table("ingredients")
    groups_df      = _load_table("dish_group")

    rag_df = _load_csv("rag_menu_final.csv")
    rag_df = rag_df.dropna(subset=['dish_id', 'rag_context'])
    rag_df = rag_df[rag_df['dish_id'].str.startswith('M', na=False)]
    rag_df = rag_df.drop_duplicates(subset='dish_id')

    dishes_df.columns = [c.strip() for c in dishes_df.columns]
    rag_df.columns    = [c.strip() for c in rag_df.columns]

    rag_cols = ['dish_id', 'health_goal', 'calories', 'rag_context']
    if 'dish_type' in rag_df.columns:
        rag_cols.append('dish_type')
    if 'is_vegetarian' in rag_df.columns:
        rag_cols.append('is_vegetarian')
    rag_fields = rag_df[rag_cols].copy()
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
    detail_path = f"/dishes/{dish_id}" if dish_id else ""
    return {
        "dish_id":      dish_id,
        "dish_name":    _safe_str(row.get('dish_name', '')),
        "image_url":    _safe_str(row.get('dish_image', '')),
        "calories":     _safe_float(row.get('kcal') or row.get('calories', 0)),
        "health_goal":  _safe_str(row.get('health_goal', 'Dinh dưỡng cân bằng')),
        "dish_type":    _safe_str(row.get('dish_type', '')),
        "rag_context":  _safe_str(row.get('rag_context', '')),
        "cooking_time": _safe_str(row.get('cooking_time', '')),
        "level":        _safe_str(row.get('level', '')),
        "servings":     _safe_str(row.get('servings', '')),
        "detail_path":  detail_path,
        "detail_url":   f"{PUBLIC_API_BASE_URL}{detail_path}" if detail_path else "",
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
        f = float(val)
        return f if not pd.isna(f) else 0.0
    except Exception:
        return 0.0

# ─── Search / Filter dishes ──────────────────────────────────────────────────
def search_dishes(
    query: str = "",
    exclude_terms: Optional[List[str]] = None,
    is_vegetarian: Optional[bool] = None,
    health_goal: str = "",
    max_calories: float = 0,
    min_calories: float = 0,
    level: str = "",
    max_time: int = 0,
    limit: int = 10,
) -> List[dict]:
    data = get_data()
    df = data["dishes"].copy()

    if is_vegetarian is not None and 'is_vegetarian' in df.columns:
        df = df[df['is_vegetarian'] == is_vegetarian]

    if query:
        q = query.lower()
        mask = (
            df['dish_name'].str.lower().str.contains(q, na=False) |
            df['rag_context'].astype(str).str.lower().str.contains(q, na=False)
        )
        df = df[mask]

    # Loại trừ các món chứa exclude_terms trong tên món
    for term in (exclude_terms or []):
        if term.strip():
            df = df[~df['dish_name'].str.lower().str.contains(term.lower(), na=False)]

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
                # Handle NaN in price by checking both fields
                price = row['final_price'] if not pd.isna(row['final_price']) else row['good_price']
                ingredients_available.append({
                    "ingredient_id":   row['ingredient_id'],
                    "ingredient_name": row['ingredient_name'],
                    "good_image":      row['good_image'] or "",
                    "price":           _safe_float(price),
                    "unit":            row['unit'] or "",
                    "inventory":       _safe_float(row['inventory']),
                    "discount":        _safe_float(row['discount']),
                })

            result.append({
                "stall_id":               stall_id,
                "stall_name":             stall_info['stall_name'],
                "stall_image":            stall_info['stall_image'] or "",
                "stall_location":         stall_info['stall_location'] or "",
                "avr_rating":             _safe_float(stall_info['avr_rating']),
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
            final_price = row['final_price'] if pd.notna(row['final_price']) else row['good_price']
            result.append({
                "stall_id":        row['stall_id'],
                "stall_name":      row['stall_name'],
                "stall_image":     row['stall_image'] or "",
                "stall_location":  row['stall_location'] or "",
                "avr_rating":      _safe_float(row['avr_rating']),
                "ingredient_name": row['ingredient_name'],
                "good_image":      row['good_image'] or "",
                "price":           _safe_float(final_price),
                "unit":            row['unit'] or "",
                "inventory":       _safe_float(row['inventory']),
                "discount":        _safe_float(row['discount']),
            })

        return result[:10]

    except Exception as e:
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

        where_parts = ["g.inventory > 0"]
        params = {"min_rating": min_rating, "limit": limit * 8}

        if keyword:
            search_pattern = f"%{keyword}%"
            where_parts.append(
                f"(unaccent(LOWER(i.ingredient_name)) LIKE unaccent(LOWER(:search_keyword)) "
                f"OR unaccent(LOWER(s.stall_name)) LIKE unaccent(LOWER(:search_keyword)))"
            )
            params["search_keyword"] = search_pattern

        if min_rating > 0:
            where_parts.append("s.avr_rating >= :min_rating")

        where_clause = " AND ".join(where_parts)
        order_by = "g.final_price ASC" if price_sort == "asc" else "g.final_price DESC"

        query_str = f"""
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
            WHERE {where_clause}
            ORDER BY s.avr_rating DESC, {order_by}
            LIMIT :limit
        """

        query = text(query_str)
        df = pd.read_sql(query, engine, params=params)

        if df.empty:
            return []

        result = []
        seen_stall_ids = set()
        df['stall_id'] = df['stall_id'].astype(str)

        for stall_id, group in df.groupby('stall_id', as_index=False):
            if stall_id in seen_stall_ids:
                continue
            seen_stall_ids.add(stall_id)

            stall_info = group.iloc[0]
            goods = []
            for _, row in group.iterrows():
                try:
                    final_price = row['final_price'] if pd.notna(row['final_price']) else row['good_price']
                    goods.append({
                        "ingredient_name": str(row['ingredient_name']),
                        "good_image":      str(row['good_image']) if pd.notna(row['good_image']) else "",
                        "price":           _safe_float(final_price),
                        "unit":            str(row['unit']) if pd.notna(row['unit']) else "",
                        "inventory":       _safe_float(row['inventory']),
                        "discount":        _safe_float(row['discount']),
                    })
                except Exception:
                    continue

            stall_obj = {
                "stall_id":       str(stall_id),
                "stall_name":     str(stall_info['stall_name']),
                "stall_image":    str(stall_info['stall_image']) if pd.notna(stall_info['stall_image']) else "",
                "stall_location": str(stall_info['stall_location']) if pd.notna(stall_info['stall_location']) else "",
                "avr_rating":     _safe_float(stall_info['avr_rating']),
                "goods":          goods,
                "total_goods":    len(goods),
            }
            result.append(stall_obj)

        result.sort(key=lambda x: (-x['avr_rating'], -x['total_goods']))
        return result[:limit]

    except Exception as e:
        import traceback
        traceback.print_exc()
        return []
    
# ─── Gợi ý thực đơn ──────────────────────────────────────────────────────────────────────────────────────────────────────────────
default_suggest_menu_exclude: list = []

def suggest_menu(
    days: int = 1,
    health_goal_ids: list = None,
    note_ids: list = None,
    meals_per_day: int = 3,
    exclude_terms: list = None,
) -> dict:
    """Gợi ý thực đơn theo ngày dựa trên dish_classification.
    
    Args:
        exclude_terms: Danh sách từ khóa nguyên liệu dị ứng cần loại bỏ khỏi thực đơn.
    """
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

        vegetarian_only = "DM30" in (note_ids or [])
        vegetarian_ids = set()
        if vegetarian_only:
            try:
                dishes_df = get_data().get("dishes", pd.DataFrame())
                if not dishes_df.empty and "is_vegetarian" in dishes_df.columns:
                    vegetarian_ids = set(
                        dishes_df[dishes_df["is_vegetarian"] == True]["dish_id"]
                        .astype(str)
                        .tolist()
                    )
            except Exception:
                vegetarian_ids = set()

        # ── Xay dung danh sach dish_id bi loai do di ung ────────────────────────────────────
        allergy_banned_ids: set = set()
        lower_excl = [t.lower() for t in (exclude_terms or []) if t.strip()]
        if lower_excl:
            try:
                # ── Danh sach tu khoa chi la gia vi thuong hieu, KHONG phai protein chinh ──
                # Neu ingredient_name BAT DAU bang mot trong cac cum tu nay → bo qua
                FLAVOR_PREFIXES_UNACCENTED = [
                    "hat nem", "gia vi", "bot canh", "bot nem", "vien nem",
                    "nuoc cot", "nuoc dung", "bot sup", "soup", "bouillon",
                    "muoi ot", "sa te", "tuong", "nuoc mam", "duoc kem",
                ]
                # Xay NOT LIKE dung unaccent() de match ca co/khong dau
                flavor_where = " AND ".join(
                    f"unaccent(LOWER(ingredient_name)) NOT LIKE '{pf}%'"
                    for pf in FLAVOR_PREFIXES_UNACCENTED
                )

                for term in lower_excl:
                    # Tang 1: loc theo TEN MON AN (su dung ILIKE de match case-insensitive)
                    try:
                        dish_q = text("""
                            SELECT dish_id, dish_name FROM dishes 
                            WHERE unaccent(LOWER(dish_name)) LIKE unaccent(LOWER(:pat))
                        """)
                        wb_df = pd.read_sql(dish_q, engine, params={"pat": f"%{term}%"})
                        allergy_banned_ids.update(wb_df['dish_id'].astype(str).tolist())
                        if not wb_df.empty:
                            print(f"[suggest_menu] Tang1 '{term}': {len(wb_df)} mon bi loai theo ten: {wb_df['dish_name'].tolist()}")
                    except Exception as e1:
                        print(f"[suggest_menu] Tang1 error: {e1}")
                        # Fallback: pandas string contains
                        ddf = get_data().get("dishes", pd.DataFrame())
                        if not ddf.empty:
                            mask = ddf['dish_name'].str.lower().str.contains(term, regex=False, na=False)
                            matched = ddf[mask]['dish_id'].astype(str).tolist()
                            allergy_banned_ids.update(matched)
                            if matched:
                                print(f"[suggest_menu] Tang1 fallback '{term}': {len(matched)} mon")

                    # Tang 2: loc NGUYEN LIEU chinh (su dung LIKE, bo gia vi phu)
                    try:
                        ing_q = text(f"""
                            SELECT DISTINCT dish_id FROM recipes
                            WHERE unaccent(LOWER(ingredient_name)) LIKE unaccent(LOWER(:pat))
                              AND {flavor_where}
                        """)
                        ing_df = pd.read_sql(ing_q, engine, params={"pat": f"%{term}%"})
                        if not ing_df.empty:
                            allergy_banned_ids.update(ing_df['dish_id'].astype(str).tolist())
                            print(f"[suggest_menu] Tang2 '{term}': {len(ing_df)} mon bi loai theo nguyen lieu")
                    except Exception as e2:
                        print(f"[suggest_menu] Tang2 SQL error: {e2} - dang dung pandas fallback")
                        # Fallback: pandas contains
                        try:
                            recipes_df = get_data().get("recipes", pd.DataFrame())
                            if not recipes_df.empty:
                                mask = recipes_df['ingredient_name'].str.lower().str.contains(term, regex=False, na=False)
                                # Bo qua gia vi phu
                                for prefix in ["hat nem", "gia vi", "bot canh", "tuong", "nuoc mam"]:
                                    mask = mask & ~recipes_df['ingredient_name'].str.lower().str.startswith(prefix, na=False)
                                matched_dish_ids = recipes_df[mask]['dish_id'].astype(str).tolist()
                                allergy_banned_ids.update(matched_dish_ids)
                                if matched_dish_ids:
                                    print(f"[suggest_menu] Tang2 fallback '{term}': {len(matched_dish_ids)} mon")
                        except Exception as e3:
                            print(f"[suggest_menu] Tang2 fallback error: {e3}")

                    if not ing_df.empty:
                        allergy_banned_ids.update(ing_df['dish_id'].astype(str).tolist())

                if allergy_banned_ids:
                    print(f"[suggest_menu] Loai bo {len(allergy_banned_ids)} mon do di ung {lower_excl}")
                    print(f"[suggest_menu] (Bo qua gia vi phu: hat nem, bot canh, gia vi...)")
            except Exception as exc:
                import traceback; traceback.print_exc()
                print(f"[suggest_menu] Loi loc di ung: {exc}")

        menu = []
        used_dish_ids = set()

        for day in range(1, days + 1):
            meals = []
            for meal_label, meal_group_id in MEALS:

                if all_group_ids:
                    ids_str = ", ".join([f"'{i}'" for i in all_group_ids])
                    query = f"""
                        SELECT d.dish_id, d.dish_name, d.dish_image,
                               d.cooking_time, d.level, d.servings,
                               d.steps, d.prep, d.serve, d.calories
                        FROM dish_classification dc1
                        JOIN dish_classification dc2 ON dc1.dish_id = dc2.dish_id
                        JOIN dishes d ON dc1.dish_id = d.dish_id
                        WHERE dc1.group_id = '{meal_group_id}'
                          AND dc2.group_id IN ({ids_str})
                        ORDER BY RANDOM()
                        LIMIT 40
                    """
                else:
                    query = f"""
                        SELECT d.dish_id, d.dish_name, d.dish_image,
                               d.cooking_time, d.level, d.servings,
                               d.steps, d.prep, d.serve, d.calories
                        FROM dish_classification dc
                        JOIN dishes d ON dc.dish_id = d.dish_id
                        WHERE dc.group_id = '{meal_group_id}'
                        ORDER BY RANDOM()
                        LIMIT 40
                    """

                df = pd.read_sql(query, engine)

                # –– Áp dụng bộ lọc dị ứng –––––––––––––––––––––––––––––––––––––––––––––––––
                if allergy_banned_ids:
                    df = df[~df['dish_id'].astype(str).isin(allergy_banned_ids)]

                if vegetarian_only and vegetarian_ids:
                    df = df[df['dish_id'].astype(str).isin(vegetarian_ids)]
                df = df[~df['dish_id'].isin(used_dish_ids)]

                if df.empty and all_group_ids:
                    # Fallback: thử lại không lọc vegetarian nếu cần
                    df = pd.read_sql(query, engine)
                    if allergy_banned_ids:
                        df = df[~df['dish_id'].astype(str).isin(allergy_banned_ids)]
                    if vegetarian_only and vegetarian_ids:
                        df = df[df['dish_id'].astype(str).isin(vegetarian_ids)]

                if df.empty and not all_group_ids:
                    fallback = f"""
                        SELECT d.dish_id, d.dish_name, d.dish_image,
                               d.cooking_time, d.level, d.servings,
                               d.steps, d.prep, d.serve, d.calories
                        FROM dish_classification dc
                        JOIN dishes d ON dc.dish_id = d.dish_id
                        WHERE dc.group_id = '{meal_group_id}'
                        ORDER BY RANDOM()
                        LIMIT 40
                    """
                    df = pd.read_sql(fallback, engine)
                    if allergy_banned_ids:
                        df = df[~df['dish_id'].astype(str).isin(allergy_banned_ids)]
                    if vegetarian_only and vegetarian_ids:
                        df = df[df['dish_id'].astype(str).isin(vegetarian_ids)]
                    df = df[~df['dish_id'].isin(used_dish_ids)]

                if not df.empty:
                    row = df.iloc[0]
                    used_dish_ids.add(row['dish_id'])
                    dish = build_dish_response(row)
                    meals.append({"meal": meal_label, "dish": dish})

            menu.append({"day": day, "meals": meals})

        return {"days": days, "meals_per_day": meals_per_day, "menu": menu}

    except Exception as e:
        return {"days": days, "menu": []}
