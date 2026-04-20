from __future__ import annotations

from pathlib import Path
from typing import Iterable

import pandas as pd


APP_DIR = Path(__file__).resolve().parent
DATA_DIR = APP_DIR.parent
DEFAULT_OUTPUT = APP_DIR / "rag_menu_final.csv"

ANIMAL_INGREDIENT_TERMS = [
    "thịt", "bò", "heo", "lợn", "gà", "vịt", "dê", "giò", "chả",
    "cá", "tôm", "cua", "mực", "nghêu", "sò", "hàu", "hải sản",
    "cồi điệp", "cồi sò điệp", "trứng", "sữa", "nước mắm",
]

DISH_TYPE_KEYWORDS = [
    "canh", "súp", "lẩu", "gỏi", "salad", "xào", "chiên", "nướng",
    "hấp", "kho", "rim", "cuộn", "bánh", "cháo", "bún", "phở", "mì",
    "cơm", "pizza", "burger", "sandwich",
]


def clean_text(value) -> str:
    if value is None or (isinstance(value, float) and pd.isna(value)):
        return ""
    return str(value).strip()


def is_vegetarian_dish(ingredients: Iterable[str], dish_name: str = "") -> bool:
    parts = [clean_text(item).lower() for item in ingredients]
    if dish_name:
        parts.append(clean_text(dish_name).lower())
    text = " ".join(parts)
    return not any(term in text for term in ANIMAL_INGREDIENT_TERMS)


def infer_dish_type(dish_name: str) -> str:
    text = clean_text(dish_name).lower()
    for keyword in DISH_TYPE_KEYWORDS:
        if keyword in text:
            return keyword
    return "khác"


def build_short_highlight(dish_type: str, ingredients: list[str], is_vegetarian: bool) -> str:
    ingredient_text = ", ".join(ingredients[:4])
    vegetarian_text = "món chay" if is_vegetarian else "món không chay"
    if dish_type and dish_type != "khác":
        return f"{vegetarian_text} kiểu {dish_type}, nổi bật với {ingredient_text}"
    return f"{vegetarian_text}, nổi bật với {ingredient_text}"


def build_rag_context(row, ingredients: list[str], is_vegetarian: bool, dish_type: str) -> str:
    dish_name = clean_text(row.get("dish_name", ""))
    health_goal = clean_text(row.get("health_goal", "Dinh dưỡng cân bằng"))
    calories = clean_text(row.get("calories", ""))
    cooking_time = clean_text(row.get("cooking_time", ""))
    level = clean_text(row.get("level", ""))
    ingredient_text = ", ".join(ingredients)
    classification = "Ăn chay được" if is_vegetarian else "Không chay"
    highlight = build_short_highlight(dish_type, ingredients, is_vegetarian)

    return (
        f"Tên món: {dish_name}. "
        f"Phân loại: {classification}. "
        f"Kiểu món: {dish_type}. "
        f"Mục tiêu: {health_goal}. "
        f"Calo: {calories} kcal. "
        f"Thời gian: {cooking_time}. "
        f"Độ khó: {level}. "
        f"Nguyên liệu chính: {ingredient_text}. "
        f"Đặc điểm nổi bật: {highlight}."
    )


OUTPUT_COLUMNS = [
    "dish_id",
    "dish_name",
    "health_goal",
    "calories",
    "main_ingredients",
    "is_vegetarian",
    "dish_type",
    "rag_context",
]


def build_recipe_map(recipes_df: pd.DataFrame) -> dict[str, list[str]]:
    if recipes_df.empty or not {"dish_id", "ingredient_name"}.issubset(recipes_df.columns):
        return {}
    return (
        recipes_df.dropna(subset=["dish_id", "ingredient_name"])
        .groupby("dish_id")["ingredient_name"]
        .apply(lambda items: [clean_text(item) for item in items if clean_text(item)])
        .to_dict()
    )


def build_rag_dataframe(
    dishes_df: pd.DataFrame,
    recipes_df: pd.DataFrame,
    existing_rag_df: pd.DataFrame,
) -> pd.DataFrame:
    recipe_map = build_recipe_map(recipes_df)
    rag_meta = existing_rag_df[["dish_id", "health_goal", "calories"]].copy()
    rag_meta = rag_meta.drop_duplicates(subset="dish_id")
    merged = pd.merge(dishes_df, rag_meta, on="dish_id", how="left", suffixes=("_dish", ""))

    rows = []
    for _, row in merged.iterrows():
        dish_id = clean_text(row.get("dish_id", ""))
        dish_name_raw = clean_text(row.get("dish_name", ""))
        ingredients = recipe_map.get(dish_id, [])
        is_vegetarian = is_vegetarian_dish(ingredients, dish_name=dish_name_raw)
        dish_type = infer_dish_type(dish_name_raw)
        calories = row.get("calories", row.get("calories_dish", ""))
        context_row = row.copy()
        context_row["calories"] = calories
        rag_context = build_rag_context(context_row, ingredients, is_vegetarian, dish_type)

        rows.append({
            "dish_id": dish_id,
            "dish_name": clean_text(row.get("dish_name", "")),
            "health_goal": clean_text(row.get("health_goal", "Dinh dưỡng cân bằng")),
            "calories": calories,
            "main_ingredients": ", ".join(ingredients),
            "is_vegetarian": is_vegetarian,
            "dish_type": dish_type,
            "rag_context": rag_context,
        })

    return pd.DataFrame(rows, columns=OUTPUT_COLUMNS)


DEFAULT_DISHES = DATA_DIR / "dishes_202603071642.csv"
DEFAULT_RECIPES = DATA_DIR / "recipes_202603071648.csv"


def build_csv(
    dishes_path: Path = DEFAULT_DISHES,
    recipes_path: Path = DEFAULT_RECIPES,
    existing_rag_path: Path = DEFAULT_OUTPUT,
    output_path: Path = DEFAULT_OUTPUT,
) -> pd.DataFrame:
    dishes_df = pd.read_csv(dishes_path, on_bad_lines="skip")
    recipes_df = pd.read_csv(recipes_path, on_bad_lines="skip")
    existing_rag_df = pd.read_csv(existing_rag_path, on_bad_lines="skip")

    result = build_rag_dataframe(dishes_df, recipes_df, existing_rag_df)

    output_path = Path(output_path)
    backup_path = output_path.with_name(f"{output_path.stem}.backup{output_path.suffix}")
    if output_path.exists() and not backup_path.exists():
        output_path.replace(backup_path)

    result.to_csv(output_path, index=False, encoding="utf-8")
    return result


def main() -> None:
    result = build_csv()
    print(f"Built {DEFAULT_OUTPUT} with {len(result)} rows")
    print("Delete chatbot_api/.vector_cache before restarting the API.")


if __name__ == "__main__":
    main()
