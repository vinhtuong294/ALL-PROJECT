with open('test_allergen_fixed.py', 'w', encoding='utf-8') as f:
    f.write("""#!/usr/bin/env python3
import sys
import pandas as pd
from data_loader import get_data, suggest_menu

def test_allergen_filter():
    print("=" * 60)
    print("TEST: Allergen Filter in suggest_menu()")
    print("=" * 60)
    
    data = get_data()
    dishes_df = data.get("dishes", pd.DataFrame())
    recipes_dict = data.get("recipes", {})
    
    if dishes_df.empty:
        print("Error: No dishes data")
        return False
    
    # Test 1: Find dishes with tom in name
    print("\\nTest 1: Dishes with tom in name")
    tom_dishes = dishes_df[
        dishes_df["dish_name"].str.lower().str.contains("tom", na=False, regex=True)
    ]
    print(f"   Found: {len(tom_dishes)} dishes")
    if not tom_dishes.empty:
        print(f"   Examples: {tom_dishes['dish_name'].head(3).tolist()}")
    
    # Test 2: Find dishes with tom in ingredients
    print(f"\\nTest 2: Dishes with tom in ingredients")
    tom_recipe_dishes = []
    for dish_id, ingredients in recipes_dict.items():
        if isinstance(ingredients, list):
            has_tom = any("tom" in ing.lower() for ing in ingredients)
            if has_tom:
                tom_recipe_dishes.append(dish_id)
    
    tom_recipe_dishes_info = dishes_df[dishes_df["dish_id"].isin(tom_recipe_dishes)]
    print(f"   Found: {len(tom_recipe_dishes_info)} dishes")
    if not tom_recipe_dishes_info.empty:
        print(f"   Examples: {tom_recipe_dishes_info['dish_name'].head(3).tolist()}")
    
    # Test 3: Call suggest_menu with exclude_terms
    print(f"\\nTest 3: suggest_menu with exclude_terms=['tom']")
    print(f"   Creating menu with tom excluded...")
    result = suggest_menu(
        days=1,
        health_goal_ids=[],
        note_ids=[],
        meals_per_day=3,
        exclude_terms=["tom"]
    )
    
    print(f"\\n   Results:")
    menu = result.get("menu", [])
    all_dishes_in_menu = []
    for day in menu:
        for meal in day.get("meals", []):
            dish = meal.get("dish", {})
            all_dishes_in_menu.append({
                "name": dish.get("dish_name"),
                "id": dish.get("dish_id")
            })
            print(f"     - {dish.get('dish_name')}")
    
    # Verify
    print(f"\\nVerification: Do these dishes contain tom?")
    has_tom = False
    for dish_info in all_dishes_in_menu:
        dish_name = dish_info["name"].lower() if dish_info["name"] else ""
        if "tom" in dish_name:
            print(f"   YES: {dish_info['name']}")
            has_tom = True
    
    if not has_tom:
        print(f"   NO - Allergen filter works correctly!")
        return True
    else:
        print(f"   ERROR - Filter did not exclude tom")
        return False

if __name__ == "__main__":
    success = test_allergen_filter()
    sys.exit(0 if success else 1)
""")
print('File created successfully')
