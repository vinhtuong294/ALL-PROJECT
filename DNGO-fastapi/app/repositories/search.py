from sqlalchemy.orm import Session
from sqlalchemy import text


def search_all(db: Session, query: str):
    search_term = f"%{query}%"

    stalls = db.execute(text("""
        SELECT stall_id as id, stall_name as name, 'stall' as type, stall_image as image
        FROM stall
        WHERE stall_name ILIKE :q
        LIMIT 5
    """), {"q": search_term}).fetchall()

    dishes = db.execute(text("""
        SELECT dish_id as id, dish_name as name, 'dish' as type, dish_image as image
        FROM dishes
        WHERE dish_name ILIKE :q
        LIMIT 5
    """), {"q": search_term}).fetchall()

    ingredients = db.execute(text("""
        SELECT ingredient_id as id, ingredient_name as name, 'ingredient' as type, NULL as image
        FROM ingredients
        WHERE ingredient_name ILIKE :q
        LIMIT 5
    """), {"q": search_term}).fetchall()

    return {
        "stalls": [dict(r._mapping) for r in stalls],
        "dishes": [dict(r._mapping) for r in dishes],
        "ingredients": [dict(r._mapping) for r in ingredients],
    }