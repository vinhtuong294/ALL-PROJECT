from pydantic import BaseModel
from typing import List
from enum import Enum


class AddItemBody(BaseModel):
    ingredient_id: str
    stall_id: str
    cart_quantity: float


class AddCartItemResponse(BaseModel):
    success: bool
    cart_id: str
    total_amount: float
    total_items: int
   
   
class UpdateItemBody(BaseModel):
    cart_quantity: float


class CartItemResponse(BaseModel):
    ingredient_id: str
    ingredient_name: str
    stall_id: str
    stall_name: str
    price: float
    cart_quantity: float
    line_total: float


class CartResponse(BaseModel):
    cart_id: str
    buyer_id: str
    items: List[CartItemResponse]
    total_amount: float
   
   
class AddDishToCartBody(BaseModel):
    dish_id: str
    market_id: str
   
   
class SelectedItem(BaseModel):
    ingredient_id: str
    stall_id: str


class PaymentMethod(str, Enum):
    tien_mat = "tien_mat"
    chuyen_khoan = "chuyen_khoan"


class CheckoutBody(BaseModel):
    selected_items: list[SelectedItem]
    payment_method: PaymentMethod
