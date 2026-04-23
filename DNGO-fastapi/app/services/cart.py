# app/services/cart.py


from sqlalchemy.orm import Session
from sqlalchemy import and_
from app.models import Dish, Recipe, Goods, Stall
from app.repositories.cart import CartRepository




class CartService:


    @staticmethod
    def add_dish_to_cart(
        db: Session,
        buyer_id: str,
        dish_id: str,
        market_id: str
    ):


        # 1️⃣ Check dish tồn tại
        dish = db.query(Dish).filter(
            Dish.dish_id == dish_id
        ).first()


        if not dish:
            return None


        # 2️⃣ Lấy công thức món
        recipe_items = db.query(Recipe).filter(
            Recipe.dish_id == dish_id
        ).all()


        if not recipe_items:
            return None


        # 3️⃣ Lấy hoặc tạo cart
        cart = CartRepository.get_current_cart(db, buyer_id)
        if not cart:
            cart = CartRepository.create_cart(db, buyer_id)


        # 4️⃣ Loop từng nguyên liệu
        for item in recipe_items:


            # Nếu quantity_cook đang lưu số dạng string
            base_quantity = float(item.quantity_cook)


            actual_quantity = base_quantity 


            goods = (
                db.query(Goods)
                .join(Stall)
                .filter(
                    Goods.ingredient_id == item.ingredient_id,  
                    Stall.market_id == market_id
                )
                .first()
            )


            if not goods:
                continue


            cart_detail = CartRepository.get_cart_detail(
                db,
                cart.cart_id,
                item.ingredient_id,
                goods.stall_id
            )


            if cart_detail:
                cart_detail.cart_quantity += actual_quantity
            else:
                CartRepository.create_cart_detail(
                    db,
                    cart.cart_id,
                    item.ingredient_id,
                    goods.stall_id,
                    actual_quantity
                )


        db.commit()


        return CartRepository.view_cart(db, buyer_id)

