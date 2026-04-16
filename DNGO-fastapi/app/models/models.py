from sqlalchemy import (
    Column, String, Integer, Float, Boolean, DateTime, Text,
    ForeignKey, Enum, Date, Time, Numeric, Computed, SmallInteger
)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base
import enum
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import BigInteger, CheckConstraint
from datetime import datetime

# ==================== ENUMS ====================
class UserRole(str, enum.Enum):
    nguoi_mua = "nguoi_mua"
    nguoi_ban = "nguoi_ban"
    shipper = "shipper"
    quan_ly_cho = "quan_ly_cho"
    admin = "admin"


class PaymentMethod(str, enum.Enum):
    chuyen_khoan = "chuyen_khoan"
    tien_mat = "tien_mat"


class PaymentStatus(str, enum.Enum):
    chua_thanh_toan = "chua_thanh_toan"
    da_thanh_toan = "da_thanh_toan"
    da_hoan_tien = "da_hoan_tien"
    huy_thanh_toan = "huy_thanh_toan"


class OrderStatus(str, enum.Enum):
    chua_xac_nhan = "chua_xac_nhan"
    da_xac_nhan = "da_xac_nhan"
    dang_giao = "dang_giao"
    da_giao = "da_giao"
    cho_hoan = "cho_hoan"
    da_hoan = "da_hoan"
    da_huy = "da_huy"
    hoan_thanh = "hoan_thanh"


# ==================== MODELS ====================

class District(Base):
    __tablename__ = "district"
   
    district_id = Column(String(4), primary_key=True)
    district_name = Column(String(255), nullable=False)
   
    markets = relationship("Market", back_populates="district")


class Market(Base):
    __tablename__ = "market"
   
    market_id = Column(String(5), primary_key=True)
    market_name = Column(String(255), nullable=False)
    district_id = Column(String(4), ForeignKey("district.district_id"), nullable=False)
    market_address = Column(String(255), nullable=False)
    market_image = Column(Text)
    long_market = Column(Float)
    lat_market = Column(Float)
   
    district = relationship("District", back_populates="markets")
    stalls = relationship("Stall", back_populates="market")
    market_managers = relationship("MarketManagement", back_populates="market")
    

class User(Base):
    __tablename__ = "users"
   
    user_id = Column(String(6), primary_key=True)
    login_name = Column(String(255), nullable=False)
    user_name = Column(String(255), nullable=False)
    password = Column(String(255), nullable=False)
    role = Column(String(20), nullable=False)
    gender = Column(String(1), nullable=False)
    bank_account = Column(String(255))
    phone = Column(String(10), nullable=False)
    bank_name = Column(String(255))
    address = Column(String(255), nullable=False)
    approval_status = Column(SmallInteger, default=0)
    active_status = Column(String(20), nullable=False, server_default='mo_cua')
    buyers = relationship("Buyer", back_populates="user")
    shippers = relationship("Shipper", back_populates="user")
    stalls = relationship("Stall", back_populates="user")
    market_managers = relationship("MarketManagement", back_populates="user")


class Buyer(Base):
    __tablename__ = "buyer"
   
    buyer_id = Column(String(8), primary_key=True)
    user_id = Column(String(6), ForeignKey("users.user_id"), nullable=False)
    weight = Column(Float)
    height = Column(Float)
   
    user = relationship("User", back_populates="buyers")
    orders = relationship("Order", back_populates="buyer")
    reviews = relationship("Review", back_populates="buyer")
    review_shippers = relationship("ReviewShipper", back_populates="buyer")
    carts = relationship("Cart", back_populates="buyer")


class MarketManagement(Base):
    __tablename__ = "market_management"
   
    manage_id = Column(String(8), primary_key=True)
    market_id = Column(String(5), ForeignKey("market.market_id"), nullable=False)
    user_id = Column(String(6), ForeignKey("users.user_id"), nullable=False)
   
    market = relationship("Market", back_populates="market_managers")
    user = relationship("User", back_populates="market_managers")
    stalls = relationship("Stall", back_populates="manager")


class Stall(Base):
    __tablename__ = "stall"
   
    stall_id = Column(String(8), primary_key=True)
    stall_name = Column(String(255), nullable=False)
    market_id = Column(String(5), ForeignKey("market.market_id"), nullable=False)
    user_id = Column(String(6), ForeignKey("users.user_id"), nullable=False)
    manage_id = Column(String(10), ForeignKey("market_management.manage_id"))
    stall_location = Column(String(255), nullable=False)
    stall_image = Column(Text)
    avr_rating = Column(Float)
    signup_date = Column(Date, nullable=False)
    grid_col = Column(Integer)
    grid_row = Column(Integer)
    grid_floor = Column(Integer) 
    stall_fee = Column(Integer, default=50000)

    market = relationship("Market", back_populates="stalls")
    user = relationship("User", back_populates="stalls")
    manager = relationship("MarketManagement", back_populates="stalls")
    goods = relationship("Goods", back_populates="stall")
    reviews = relationship("Review", back_populates="stall")
    stall_fees = relationship("StallFee", back_populates="stall")


class Shipper(Base):
    __tablename__ = "shipper"
   
    shipper_id = Column(String(8), primary_key=True)
    user_id = Column(String(6), ForeignKey("users.user_id"), nullable=False)
    vehicle_type = Column(String(255), nullable=False)
    vehicle_plate = Column(String(255), nullable=False)
   
    user = relationship("User", back_populates="shippers")
    consolidations = relationship("Consolidation", back_populates="shipper")
    review_shippers = relationship("ReviewShipper", back_populates="shipper")


class Category(Base):
    __tablename__ = "category"
   
    category_id = Column(String(3), primary_key=True)
    category_name = Column(String(255), nullable=False)
    ingredient_type = Column(String(255), nullable=False)
   
    ingredients = relationship("Ingredient", back_populates="category")


class Ingredient(Base):
    __tablename__ = "ingredients"
   
    ingredient_id = Column(String(10), primary_key=True)
    ingredient_name = Column(String(255), nullable=False)
    category_id = Column(String(3), ForeignKey("category.category_id"), nullable=False)
   
    category = relationship("Category", back_populates="ingredients")
    goods = relationship("Goods", back_populates="ingredient")
    recipes = relationship("Recipe", back_populates="ingredient")


class Goods(Base):
    __tablename__ = "goods"
   
    ingredient_id = Column(String(10), ForeignKey("ingredients.ingredient_id"), primary_key=True)
    stall_id = Column(String(8), ForeignKey("stall.stall_id"), primary_key=True)
    good_image = Column(Text, nullable=False)
    inventory = Column(Float, nullable=False)
    good_price = Column(Integer, nullable=False)
    discount = Column(Float)
    update_date = Column(DateTime, nullable=False)
    sale_start_date = Column(DateTime)
    sale_end_date = Column(DateTime)
    unit = Column(String(255), nullable=False)
   
    ingredient = relationship("Ingredient", back_populates="goods")
    stall = relationship("Stall", back_populates="goods")


class DishGroup(Base):
    __tablename__ = "dish_group"
   
    group_id = Column(String(4), primary_key=True)
    group_name = Column(String(255), nullable=False)
    group_type = Column(String(255), nullable=False)
   
    dish_classifications = relationship("DishClassification", back_populates="group")


class Dish(Base):
    __tablename__ = "dishes"
   
    dish_id = Column(String(5), primary_key=True)
    dish_name = Column(String(255), nullable=False)
    dish_image = Column(Text)
    cooking_time = Column(Integer)
    level = Column(String(255))
    servings = Column(Integer, nullable=False)
    steps = Column(Text, nullable=False)
    prep = Column(Text)
    serve = Column(Text)
    calories = Column(Float)
   
    dish_classifications = relationship("DishClassification", back_populates="dish")
    recipes = relationship("Recipe", back_populates="dish")


class DishClassification(Base):
    __tablename__ = "dish_classification"
   
    group_id = Column(String(4), ForeignKey("dish_group.group_id"), primary_key=True)
    dish_id = Column(String(5), ForeignKey("dishes.dish_id"), primary_key=True)
   
    group = relationship("DishGroup", back_populates="dish_classifications")
    dish = relationship("Dish", back_populates="dish_classifications")


class Recipe(Base):
    __tablename__ = "recipes"
   
    id = Column(Integer, primary_key=True, autoincrement=True)
    dish_id = Column(String(5), ForeignKey("dishes.dish_id"), nullable=False)
    ingredient_id = Column(String(10), ForeignKey("ingredients.ingredient_id"), nullable=False)
    ingredient_name = Column(String(255))
    quantity_cook = Column(String(255))
   
    dish = relationship("Dish", back_populates="recipes")
    ingredient = relationship("Ingredient", back_populates="recipes")


class TimeSlot(Base):
    __tablename__ = "time_slot"
   
    time_slot_id = Column(String(4), primary_key=True)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)


class Payment(Base):
    __tablename__ = "payment"
   
    payment_id = Column(String(10), primary_key=True)
    payment_method = Column(String(20), nullable=False, default="tien_mat")
    payment_account = Column(String(255), nullable=False)
    payment_time = Column(DateTime, nullable=False)
    payment_status = Column(String(20), nullable=False, default="chua_thanh_toan")
   
    orders = relationship("Order", back_populates="payment")


class Order(Base):
    __tablename__ = "orders"
   
    order_id = Column(String(10), primary_key=True)
    payment_id = Column(String(10), ForeignKey("payment.payment_id"))
    buyer_id = Column(String(8), ForeignKey("buyer.buyer_id"), nullable=False)
    total_amount = Column(Integer)
    delivery_address = Column(String(255), nullable=False)
    order_status = Column(String(20), nullable=False, default="chua_xac_nhan")
    order_time = Column(DateTime, nullable=False)
    delivery_time = Column(DateTime, nullable=False)
    delivery_long = Column(Float)
    delivery_lat = Column(Float)
    consolidation_id = Column(String(10), ForeignKey("consolidation.consolidation_id"))
    time_slot_id = Column(String(4), ForeignKey("time_slot.time_slot_id"))
   
    buyer = relationship("Buyer", back_populates="orders")
    payment = relationship("Payment", back_populates="orders")
    reviews = relationship("Review", back_populates="order")
    review_shippers = relationship("ReviewShipper", back_populates="order")
    order_time = Column(DateTime, nullable=True, server_default=func.now())
    distance_km = Column(Float)


class OrderDetail(Base):
    __tablename__ = "order_detail"
   
    order_id = Column(String(10), ForeignKey("orders.order_id"), primary_key=True)
    ingredient_id = Column(String(10), ForeignKey("ingredients.ingredient_id"), primary_key=True)
    stall_id = Column(String(8), ForeignKey("stall.stall_id"), primary_key=True)
    quantity_order = Column(Float, nullable=False)
    final_price = Column(Integer)
    dish_id = Column(String(5))
    detail_status = Column(String(20), nullable=False, default="cho_duyet") 
    cancel_reason = Column(Text)
    line_total = Column(Integer, Computed("CAST(quantity_order * final_price AS INT)", persisted=True))


class Consolidation(Base):
    __tablename__ = "consolidation"
   
    consolidation_id = Column(String(10), primary_key=True)
    shipper_id = Column(String(8), ForeignKey("shipper.shipper_id"), nullable=False)
    shipping_time = Column(Integer)
   
    shipper = relationship("Shipper", back_populates="consolidations")


class Cart(Base):
    __tablename__ = "cart"
   
    cart_id = Column(String(10), primary_key=True)
    buyer_id = Column(String(8), ForeignKey("buyer.buyer_id"), nullable=False)
    cart_date = Column(DateTime, nullable=False, server_default=func.now())
    update_cart_date = Column(DateTime, nullable=False)
   
    buyer = relationship("Buyer", back_populates="carts")
    cart_details = relationship("CartDetail", back_populates="cart")


class CartDetail(Base):
    __tablename__ = "cart_detail"
   
    cart_id = Column(String(10), ForeignKey("cart.cart_id"), primary_key=True)
    ingredient_id = Column(String(10), ForeignKey("ingredients.ingredient_id"), primary_key=True)
    stall_id = Column(String(8), ForeignKey("stall.stall_id"), primary_key=True)
    cart_quantity = Column(Float, nullable=False)
    update_detail_date = Column(DateTime, nullable=False, server_default=func.now())
   
    cart = relationship("Cart", back_populates="cart_details")


class Review(Base):
    __tablename__ = "review"
   
    review_id = Column(String(10), primary_key=True)
    buyer_id = Column(String(8), ForeignKey("buyer.buyer_id"), nullable=False)
    stall_id = Column(String(8), ForeignKey("stall.stall_id"), nullable=False)
    review_date = Column(DateTime, nullable=False)
    rating = Column(Integer)
    comment = Column(Text)
    order_id = Column(String(10), ForeignKey("orders.order_id"), nullable=False)
   
    buyer = relationship("Buyer", back_populates="reviews")
    stall = relationship("Stall", back_populates="reviews")
    order = relationship("Order", back_populates="reviews")


class ReviewShipper(Base):
    __tablename__ = "review_shipper"
   
    review_shipper_id = Column(String(10), primary_key=True)
    shipper_id = Column(String(8), ForeignKey("shipper.shipper_id"), nullable=False)
    buyer_id = Column(String(8), ForeignKey("buyer.buyer_id"), nullable=False)
    order_id = Column(String(10), ForeignKey("orders.order_id"), nullable=False)
    comment_shipper = Column(Text)
    rating_shipper = Column(Integer)
    review_shipper_date = Column(DateTime, server_default=func.now())
   
    shipper = relationship("Shipper", back_populates="review_shippers")
    buyer = relationship("Buyer", back_populates="review_shippers")
    order = relationship("Order", back_populates="review_shippers")


class StallFee(Base):
    __tablename__ = "stall_fee"

    fee_id = Column(String(10), primary_key=True)
    stall_id = Column(String(8), ForeignKey("stall.stall_id"), nullable=False)
    month = Column(Date, nullable=False)
    fee = Column(Numeric(15, 2), nullable=False)
    fee_method = Column(String(20), nullable=False, default="tien_mat")
    payment_id = Column(String(10), nullable=False)
    fee_status = Column(String(20), nullable=False, default="chua_nop")

    stall = relationship("Stall", back_populates="stall_fees")


class LoginHistory(Base):
    __tablename__ = "login_history"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(6), ForeignKey("users.user_id"), nullable=False)
    device_info = Column(String(255))
    os_info = Column(String(255))
    location = Column(String(255))
    ip_address = Column(String(50))
    login_time = Column(DateTime, server_default=func.now())
    success = Column(Boolean, default=True)

    user = relationship("User")
    

class Notification(Base):
    __tablename__ = "notifications"

    noti_id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(6), ForeignKey("users.user_id"), nullable=False)
    title = Column(String(255), nullable=False)
    body = Column(Text)
    data = Column(Text)  # lưu JSON string
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, server_default=func.now())

    user = relationship("User")
    
class Wallet(Base):
    __tablename__ = "wallet"

    wallet_id = Column(String(10), primary_key=True)
    owner_id = Column(String(10), nullable=False)
    owner_type = Column(String(20), nullable=False)
    updated_wallet = Column(DateTime, server_default=func.now(), onupdate=func.now())

    __table_args__ = (
        CheckConstraint(
            "owner_type IN ('buyer','seller','shipper','platform')",
            name="ck_wallet_owner_type"
        ),
    )
    
class WithdrawalRequest(Base):
    __tablename__ = "withdrawal_request"

    id = Column(Integer, primary_key=True, autoincrement=True)
    wallet_id = Column(String(10), ForeignKey("wallet.wallet_id"), nullable=False)
    amount = Column(Integer, nullable=False)
    bank_bin = Column(String(20), nullable=False)
    bank_account_no = Column(String(255), nullable=False)
    account_name = Column(String(255), nullable=False)
    status = Column(String(20), nullable=False, default="chờ_duyệt")
    created_at = Column(DateTime, server_default=func.now())
    note = Column(Text)

    wallet = relationship("Wallet")
    
class Conversation(Base):
    __tablename__ = "conversation"


    conversation_id = Column(String(10), primary_key=True)
    buyer_id = Column(String(8), ForeignKey("buyer.buyer_id"), nullable=False)
    stall_id = Column(String(8), ForeignKey("stall.stall_id"), nullable=False)
    created_at = Column(DateTime, server_default=func.now())


    buyer = relationship("Buyer")
    stall = relationship("Stall")
    messages = relationship("Message", back_populates="conversation")




class Message(Base):
    __tablename__ = "message"


    message_id = Column(Integer, primary_key=True, autoincrement=True)
    conversation_id = Column(String(10), ForeignKey("conversation.conversation_id"), nullable=False)
    sender_id = Column(String(10), nullable=False)
    sender_type = Column(String(20), nullable=False)
    message_text = Column(Text)
    image_url = Column(Text)
    is_read = Column(Boolean, default=False)
    sent_at = Column(DateTime, server_default=func.now())


    conversation = relationship("Conversation", back_populates="messages")


class DeliveryProof(Base):
    """Bằng chứng giao hàng (POD - Proof of Delivery)"""
    __tablename__ = "delivery_proof"

    id = Column(Integer, primary_key=True, autoincrement=True)
    order_id = Column(String(10), ForeignKey("orders.order_id"), nullable=False)
    shipper_id = Column(String(8), ForeignKey("shipper.shipper_id"), nullable=False)
    image_url = Column(Text, nullable=False)
    note = Column(Text)
    created_at = Column(DateTime, server_default=func.now())

    order = relationship("Order")
    shipper = relationship("Shipper")


class FailedDeliveryReport(Base):
    """Báo cáo giao hàng thất bại"""
    __tablename__ = "failed_delivery_report"

    id = Column(Integer, primary_key=True, autoincrement=True)
    order_id = Column(String(10), ForeignKey("orders.order_id"), nullable=False)
    shipper_id = Column(String(8), ForeignKey("shipper.shipper_id"), nullable=False)
    reason = Column(String(255), nullable=False)
    note = Column(Text)
    evidence_image_url = Column(Text)
    created_at = Column(DateTime, server_default=func.now())

    order = relationship("Order")
    shipper = relationship("Shipper")
