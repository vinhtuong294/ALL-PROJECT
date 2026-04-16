import uuid
from sqlalchemy.orm import Session
from sqlalchemy import desc, and_, tuple_
from datetime import datetime
from app.models import Cart, CartDetail, Ingredient, Stall, Goods, Order, OrderDetail, Payment, Market
from fastapi import HTTPException
from app.schemas.cart import CheckoutBody
from app.models.models import TimeSlot
from datetime import datetime, date
from fastapi import BackgroundTasks
from app.services.auto_confirm import auto_confirm_order


class CartRepository:
    @staticmethod
    def get_cart_detail(
        db: Session,
        cart_id: str,
        ingredient_id: str,
        stall_id: str
    ):
        return db.query(CartDetail).filter(
            CartDetail.cart_id == cart_id,
            CartDetail.ingredient_id == ingredient_id,
            CartDetail.stall_id == stall_id
        ).first()


    @staticmethod
    def create_cart_detail(
        db: Session,
        cart_id: str,
        ingredient_id: str,
        stall_id: str,
        quantity: float
    ):
        new_detail = CartDetail(
            cart_id=cart_id,
            ingredient_id=ingredient_id,
            stall_id=stall_id,
            cart_quantity=quantity
        )
        db.add(new_detail)


    @staticmethod
    def get_current_cart(db: Session, buyer_id: str):
        return (
            db.query(Cart)
            .filter(Cart.buyer_id == buyer_id)
            .order_by(desc(Cart.cart_date))
            .first()
        )


    @staticmethod
    def create_cart(db: Session, buyer_id: str):
        cart = Cart(
            cart_id=str(uuid.uuid4())[:8],
            buyer_id=buyer_id,
            cart_date=datetime.utcnow(),
            update_cart_date=datetime.utcnow()  # thêm dòng này
        )
        db.add(cart)
        db.commit()
        db.refresh(cart)
        return cart


    # ===============================
    # VIEW CART
    # ===============================
    @staticmethod
    def view_cart(db: Session, buyer_id: str):


        cart = CartRepository.get_current_cart(db, buyer_id)
        if not cart:
            return None


        from app.models import Ingredient, Stall, Goods


        items = (
            db.query(
                CartDetail.ingredient_id,
                CartDetail.stall_id,
                CartDetail.cart_quantity,
                Ingredient.ingredient_name,
                Goods.good_price,
                Stall.stall_name
            )
            .join(Goods,
                (Goods.ingredient_id == CartDetail.ingredient_id) &
                (Goods.stall_id == CartDetail.stall_id))
            .join(Ingredient, Ingredient.ingredient_id == CartDetail.ingredient_id)
            .join(Stall, Stall.stall_id == CartDetail.stall_id)
            .filter(CartDetail.cart_id == cart.cart_id)
            .all()
        )


        result_items = []
        total_price = 0


        for item in items:
            thanh_tien = item.good_price * item.cart_quantity
            total_price += thanh_tien


            result_items.append({
                "ingredient_id": item.ingredient_id,
                "ingredient_name": item.ingredient_name,
                "stall_id": item.stall_id,
                "stall_name": item.stall_name,
                "price": item.good_price,
                "cart_quantity": item.cart_quantity,
                "line_total": thanh_tien
            })


        return {
            "cart_id": cart.cart_id,
            "buyer_id": cart.buyer_id,
            "items": result_items,
            "total_amount": total_price
        }
      
       
    @staticmethod
    def view_cart_by_cart_id(db: Session, cart_id: str):


        cart = db.query(Cart).filter(Cart.cart_id == cart_id).first()
        if not cart:
            return None


        items = db.query(CartDetail).filter(
            CartDetail.cart_id == cart_id
        ).all()


        total_amount = 0


        for item in items:
            goods = db.query(Goods).filter(
                Goods.ingredient_id == item.ingredient_id,
                Goods.stall_id == item.stall_id
            ).first()


            total_amount += goods.good_price * item.cart_quantity


        return {
            "cart_id": cart_id,
            "total_amount": total_amount
        }
           
    # =============================
    # ADD ITEM
    # =============================
    @staticmethod
    def add_item(
        db: Session,
        buyer_id: str,
        ingredient_id: str,
        stall_id: str,
        quantity: float
    ):

        # 0️⃣ Kiểm tra gian hàng có mở cửa không
        stall = db.query(Stall).filter(Stall.stall_id == stall_id).first()
        if not stall:
            raise HTTPException(status_code=404, detail="Gian hàng không tồn tại")
        
        from app.models.models import User as UserModel
        stall_owner = db.query(UserModel).filter(UserModel.user_id == stall.user_id).first()
        if stall_owner and stall_owner.active_status == "dong_cua":
            raise HTTPException(status_code=400, detail="Gian hàng đang đóng cửa, không thể thêm vào giỏ hàng")

        # 1️⃣ Check goods exist
        goods = db.query(Goods).filter(
            and_(
                Goods.ingredient_id == ingredient_id,
                Goods.stall_id == stall_id
            )
        ).first()


        if not goods:
            raise HTTPException(
                status_code=404,
                detail="Goods not found"
            )


        # 2️⃣ Get or create cart
        cart = CartRepository.get_current_cart(db, buyer_id)
        if not cart:
            cart = CartRepository.create_cart(db, buyer_id)


        # 3️⃣ Check existing cart detail
        cart_detail = db.query(CartDetail).filter(
            and_(
                CartDetail.cart_id == cart.cart_id,
                CartDetail.ingredient_id == ingredient_id,
                CartDetail.stall_id == stall_id
            )
        ).first()


        if cart_detail:
            cart_detail.cart_quantity += quantity
        else:
            new_detail = CartDetail(
                cart_id=cart.cart_id,
                ingredient_id=ingredient_id,
                stall_id=stall_id,
                cart_quantity=quantity
            )
            db.add(new_detail)


        cart.update_cart_date = datetime.utcnow()
        db.commit()


        total_amount, total_items = CartRepository.calculate_cart_total(
            db, cart.cart_id
        )


        return CartRepository.view_cart(db, buyer_id)
    
    
    # =============================
    # CALCULATE TOTAL
    # =============================
    @staticmethod
    def calculate_cart_total(db: Session, cart_id: str):


        results = db.query(
            CartDetail.cart_quantity,
            Goods.good_price
        ).join(
            Goods,
            and_(
                Goods.ingredient_id == CartDetail.ingredient_id,
                Goods.stall_id == CartDetail.stall_id
            )
        ).filter(
            CartDetail.cart_id == cart_id
        ).all()


        total_amount = 0
        for quantity, price in results:
            total_amount += quantity * price


        total_items = len(results)


        return total_amount, total_items
    
    
    # ===============================
    # UPDATE ITEM
    # ===============================
    @staticmethod
    def update_item(db: Session, cart_id: str, ingredient_id: str, stall_id: str, quantity: float):


        cart_detail = db.query(CartDetail).filter(
            CartDetail.cart_id == cart_id,
            CartDetail.ingredient_id == ingredient_id,
            CartDetail.stall_id == stall_id
        ).first()


        if not cart_detail:
            return None


        cart_detail.cart_quantity = quantity
        db.commit()
        db.refresh(cart_detail)


        return cart_detail


    # ===============================
    # REMOVE ITEM
    # ===============================
    @staticmethod
    def remove_item(db: Session,
                    cart_id: str,
                    ingredient_id: str,
                    stall_id: str):


        item = db.query(CartDetail).filter(
            CartDetail.cart_id == cart_id,
            CartDetail.ingredient_id == ingredient_id,
            CartDetail.stall_id == stall_id
        ).first()


        if not item:
            return False


        db.delete(item)
        db.commit()
        return True


    # ===============================
    # CLEAR CART
    # ===============================
    @staticmethod
    def clear_cart(db: Session, buyer_id: str):


        cart = CartRepository.get_current_cart(db, buyer_id)
        if not cart:
            return False


        db.query(CartDetail).filter(
            CartDetail.cart_id == cart.cart_id
        ).delete()


        db.commit()
        return True
   
    # ===============================
    # CHECKOUT
    # ===============================
    @staticmethod
    def checkout(db: Session, buyer_id: str, body: CheckoutBody, background_tasks: BackgroundTasks):

        from app.utils.distance import calculate_distance
        from app.utils.shipping_fee import calculate_shipping_fee
        from app.models.models import User as UserModel, Market

        # =========================
        # LẤY CART
        # =========================
        cart = CartRepository.get_current_cart(db, buyer_id)
        if not cart:
            raise HTTPException(404, "Cart not found")

        # =========================
        # LẤY ITEMS
        # =========================
        items = (
            db.query(
                CartDetail.ingredient_id,
                CartDetail.stall_id,
                CartDetail.cart_quantity,
                Goods.good_price
            )
            .join(Goods,
                (Goods.ingredient_id == CartDetail.ingredient_id) &
                (Goods.stall_id == CartDetail.stall_id))
            .filter(
                CartDetail.cart_id == cart.cart_id,
                tuple_(CartDetail.ingredient_id, CartDetail.stall_id)
                .in_([(i.ingredient_id, i.stall_id) for i in body.selected_items])
            )
            .all()
        )

        if not items:
            raise HTTPException(400, "No items selected")

        # =========================
        # CHECK GIAN HÀNG
        # =========================
        stall_ids = set(i.stall_id for i in items)

        for sid in stall_ids:
            stall = db.query(Stall).filter(Stall.stall_id == sid).first()
            if stall:
                owner = db.query(UserModel).filter(UserModel.user_id == stall.user_id).first()
                if owner and owner.active_status == "dong_cua":
                    raise HTTPException(400, f"Gian hàng {stall.stall_name} đang đóng cửa")

        # =========================
        # TÍNH TIỀN HÀNG (CHƯA SHIP)
        # =========================
        total_amount = sum(i.cart_quantity * i.good_price for i in items)

        # =========================
        # LẤY ĐỊA CHỈ CHỢ
        # =========================
        # lấy 1 stall bất kỳ từ items
        first_stall_id = items[0].stall_id

        stall = db.query(Stall).filter(Stall.stall_id == first_stall_id).first()
        if not stall:
            raise HTTPException(400, "Không tìm thấy gian hàng")

        market = db.query(Market).filter(Market.market_id == stall.market_id).first()
        if not market:
            raise HTTPException(400, "Không tìm thấy chợ")

        market_address = market.market_address

        # =========================
        # TÍNH DISTANCE + SHIP
        # =========================
        distance = calculate_distance(market_address, body.delivery_address)
        if distance is None:
            raise HTTPException(400, "Địa chỉ giao hàng không hợp lệ")
        shipping_fee = calculate_shipping_fee(distance or 0)

        # =========================
        # TẠO PAYMENT
        # =========================
        payment = Payment(
            payment_id=str(uuid.uuid4())[:10],
            payment_method=body.payment_method,
            payment_account="N/A",
            payment_time=datetime.utcnow(),
            payment_status="chua_thanh_toan"
        )
        db.add(payment)
        db.flush()

        # =========================
        # TIME SLOT
        # =========================
        time_slot = db.query(TimeSlot).filter(
            TimeSlot.time_slot_id == body.time_slot_id
        ).first()

        if not time_slot:
            raise HTTPException(400, "Khung giờ không hợp lệ")

        delivery_time = datetime.combine(date.today(), time_slot.start_time)

        # =========================
        # TẠO ORDER
        # =========================
        order = Order(
            order_id=str(uuid.uuid4())[:10],
            payment_id=payment.payment_id,
            buyer_id=buyer_id,
            total_amount=total_amount,  # tạm thời chưa có ship
            delivery_address=body.delivery_address,
            delivery_time=delivery_time,
            distance_km=distance
        )
        db.add(order)
        db.flush()

        # =========================
        # THÊM ORDER DETAIL (ITEMS)
        # =========================
        for i in items:
            db.add(OrderDetail(
                order_id=order.order_id,
                ingredient_id=i.ingredient_id,
                stall_id=i.stall_id,
                quantity_order=i.cart_quantity,
                final_price=i.good_price
            ))

        # =========================
        # THÊM PHÍ SHIP
        # =========================
        db.add(OrderDetail(
            order_id=order.order_id,
            ingredient_id="NLQD01",
            stall_id="GH0000",
            quantity_order=1,
            final_price=shipping_fee
        ))

        # =========================
        # UPDATE TOTAL (SAU KHI CÓ SHIP)
        # =========================
        total_amount += shipping_fee
        order.total_amount = total_amount

        # =========================
        # XÓA CART ITEMS ĐÃ CHECKOUT
        # =========================
        for i in body.selected_items:
            db.query(CartDetail).filter(
                CartDetail.cart_id == cart.cart_id,
                CartDetail.ingredient_id == i.ingredient_id,
                CartDetail.stall_id == i.stall_id
            ).delete()

        db.commit()
        background_tasks.add_task(auto_confirm_order, order.order_id)

        # =========================
        # ĐẾM ITEM CÒN LẠI
        # =========================
        remaining_items = db.query(CartDetail).filter(
            CartDetail.cart_id == cart.cart_id
        ).count()

        # =========================
        # RESPONSE
        # =========================
        return {
            "success": True,
            "order": {
                "ma_don_hang": order.order_id,
                "trang_thai": order.order_status,
                "tong_tien": total_amount,
                "payment_method": payment.payment_method
            },
            "totals": {
                "tong_tien": total_amount,
                "phi_ship": shipping_fee,
                "distance_km": round(distance, 2) if distance else 0
            },
            "so_mat_hang": len(items),
            "items_checkout": len(items),
            "items_remaining": remaining_items
        }