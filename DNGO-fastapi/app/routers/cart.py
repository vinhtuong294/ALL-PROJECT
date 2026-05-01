from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session

from app.database import get_db
from app.middlewares.auth import allow, AuthUser
from app.repositories.cart import CartRepository
from app.schemas.cart import AddItemBody, UpdateItemBody, CartResponse, AddDishToCartBody, CheckoutBody
from app.services.cart import CartService
from app.models import Goods

router = APIRouter(
    prefix="/api/buyer/cart",
    tags=["Cart"]
)




# VIEW CART
@router.get("/", response_model=CartResponse)
def view_cart(buyer_id: str, db: Session = Depends(get_db),
              _: AuthUser = Depends(allow("nguoi_mua"))):
    cart = CartRepository.view_cart(db, buyer_id)
    if not cart:
        raise HTTPException(status_code=404, detail="Cart is empty")
    return cart


# ADD ITEM
@router.post("/items", response_model=CartResponse)
def add_item(buyer_id: str, body: AddItemBody, db: Session = Depends(get_db),
             _: AuthUser = Depends(allow("nguoi_mua"))):
    return CartRepository.add_item(
        db,
        buyer_id,
        body.ingredient_id,
        body.stall_id,
        body.cart_quantity
    )


@router.post("/dishes", response_model=CartResponse)
def add_dish_to_cart(buyer_id: str, body: AddDishToCartBody,
                     db: Session = Depends(get_db),
                     _: AuthUser = Depends(allow("nguoi_mua"))):
    return CartService.add_dish_to_cart(
        db=db,
        buyer_id=buyer_id,
        dish_id=body.dish_id,
        market_id=body.market_id
    )


# UPDATE ITEM
@router.put("/")
def update_item(cart_id: str, ingredient_id: str, stall_id: str,
                body: UpdateItemBody, db: Session = Depends(get_db),
                _: AuthUser = Depends(allow("nguoi_mua"))):
    cart_detail = CartRepository.update_item(db, cart_id, ingredient_id, stall_id, body.cart_quantity)
    if not cart_detail:
        raise HTTPException(status_code=404, detail="Item not found")

    goods = db.query(Goods).filter(
        Goods.ingredient_id == ingredient_id,
        Goods.stall_id == stall_id
    ).first()

    line_total = goods.good_price * cart_detail.cart_quantity
    return {
        "cart_id": cart_id,
        "stall_id": stall_id,
        "ingredient_id": ingredient_id,
        "cart_quantity": cart_detail.cart_quantity,
        "unit_price": goods.good_price,
        "line_total": line_total
    }


# REMOVE ITEM
@router.delete("/")
def remove_item(cart_id: str, ingredient_id: str, stall_id: str,
                db: Session = Depends(get_db),
                _: AuthUser = Depends(allow("nguoi_mua"))):
    success = CartRepository.remove_item(db, cart_id, ingredient_id, stall_id)
    if not success:
        raise HTTPException(status_code=404, detail="Item not found")
    return {"message": "Removed successfully"}


# CLEAR CART
@router.delete("/clear")
def clear_cart(buyer_id: str, db: Session = Depends(get_db),
               _: AuthUser = Depends(allow("nguoi_mua"))):
    success = CartRepository.clear_cart(db, buyer_id)
    if not success:
        raise HTTPException(status_code=404, detail="Cart not found")
    return {"message": "Cart cleared"}


# CHECKOUT
@router.post("/checkout")
def checkout(buyer_id: str, body: CheckoutBody, db: Session = Depends(get_db),
             background_tasks: BackgroundTasks = None,
             _: AuthUser = Depends(allow("nguoi_mua"))):
    return CartRepository.checkout(
        db,
        buyer_id,
        body=body,
        background_tasks=background_tasks
    )