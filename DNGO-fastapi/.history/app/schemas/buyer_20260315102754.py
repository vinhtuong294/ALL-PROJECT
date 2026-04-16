from pydantic import BaseModel, Field
from typing import Optional, List, Any
from datetime import datetime


# ==================== BASE SCHEMAS ====================

class PaginationParams(BaseModel):
    page: Optional[int] = Field(1, ge=1, description="Số trang")
    limit: Optional[int] = Field(10, ge=1, le=100, description="Số items mỗi trang")
    search: Optional[str] = Field(None, description="Từ khóa tìm kiếm")
    sort: Optional[str] = Field(None, description="Trường sắp xếp")
    order: Optional[str] = Field("asc", description="Thứ tự sắp xếp: asc hoặc desc")


class MetaResponse(BaseModel):
    page: int
    limit: int
    total: int
    hasNext: bool


# ==================== DISTRICT (KHU VỰC) ====================

class DistrictQuery(PaginationParams):
    pass


class DistrictItem(BaseModel):
    district_id: str = Field(..., alias="ma_khu_vuc")
    district_name: str = Field(..., alias="phuong")
    longitude: Optional[float] = None
    latitude: Optional[float] = None
    market_count: int = Field(0, alias="so_cho")
    
    class Config:
        populate_by_name = True


class DistrictListResponse(BaseModel):
    data: List[DistrictItem]
    meta: MetaResponse


# ==================== MARKET (CHỢ) ====================

class MarketQuery(PaginationParams):
    district_id: Optional[str] = Field(None, alias="ma_khu_vuc")
    
    class Config:
        populate_by_name = True


class MarketItem(BaseModel):
    market_id: str = Field(..., alias="ma_cho")
    market_name: str = Field(..., alias="ten_cho")
    district_id: str = Field(..., alias="ma_khu_vuc")
    district_name: str = Field(..., alias="ten_khu_vuc")
    address: str = Field(..., alias="dia_chi")
    image: Optional[str] = Field(None, alias="hinh_anh")
    stall_count: int = Field(0, alias="so_gian_hang")
    
    class Config:
        populate_by_name = True


class MarketListResponse(BaseModel):
    data: List[MarketItem]
    meta: MetaResponse


# ==================== STALL (GIAN HÀNG) ====================

class StallQuery(PaginationParams):
    market_id: Optional[str] = Field(None, alias="ma_cho")
    
    class Config:
        populate_by_name = True


class StallItem(BaseModel):
    stall_id: str = Field(..., alias="ma_gian_hang")
    stall_name: str = Field(..., alias="ten_gian_hang")
    location: str = Field(..., alias="vi_tri")
    image: Optional[str] = Field(None, alias="hinh_anh")
    avg_rating: Optional[float] = Field(None, alias="danh_gia_tb")
    market_id: str = Field(..., alias="ma_cho")
    
    class Config:
        populate_by_name = True


class StallListResponse(BaseModel):
    data: List[StallItem]
    meta: MetaResponse


class StallDetailQuery(PaginationParams):
    pass


class ProductInStall(BaseModel):
    ingredient_id: str = Field(..., alias="ma_nguyen_lieu")
    ingredient_name: Optional[str] = Field(None, alias="ten_nguyen_lieu")
    unit: Optional[str] = Field(None, alias="don_vi")
    category_id: Optional[str] = Field(None, alias="ma_nhom_nguyen_lieu")
    category_name: Optional[str] = Field(None, alias="ten_nhom_nguyen_lieu")
    image: Optional[str] = Field(None, alias="hinh_anh")
    original_price: int = Field(..., alias="gia_goc")
    final_price: Optional[Any] = Field(None, alias="gia_cuoi")
    quantity: float = Field(..., alias="so_luong_ban")
    discount: Optional[float] = Field(None, alias="phan_tram_giam_gia")
    updated_at: Optional[datetime] = Field(None, alias="ngay_cap_nhat")
    
    class Config:
        populate_by_name = True


class StallDetail(BaseModel):
    stall_id: str = Field(..., alias="ma_gian_hang")
    stall_name: str = Field(..., alias="ten_gian_hang")
    location: str = Field(..., alias="vi_tri")
    image: Optional[str] = Field(None, alias="hinh_anh")
    avg_rating: Optional[float] = Field(None, alias="danh_gia_tb")
    signup_date: Optional[datetime] = Field(None, alias="ngay_dang_ky")
    product_count: int = Field(0, alias="so_san_pham")
    review_count: int = Field(0, alias="so_danh_gia")
    market: Optional[dict] = Field(None, alias="cho")
    
    class Config:
        populate_by_name = True


class StallDetailResponse(BaseModel):
    success: bool = True
    detail: StallDetail
    san_pham: dict


# ==================== INGREDIENT (NGUYÊN LIỆU) ====================

class IngredientQuery(PaginationParams):
    category_id: Optional[str] = Field(None, alias="ma_nhom_nguyen_lieu")
    market_id: Optional[str] = Field(None, alias="ma_cho")
    stall_id: Optional[str] = Field(None, alias="ma_gian_hang")
    has_image: Optional[bool] = Field(None, alias="hinh_anh")
    
    class Config:
        populate_by_name = True


class IngredientItem(BaseModel):
    ingredient_id: str = Field(..., alias="ma_nguyen_lieu")
    ingredient_name: str = Field(..., alias="ten_nguyen_lieu")
    unit: Optional[str] = Field(None, alias="don_vi")
    category_id: str = Field(..., alias="ma_nhom_nguyen_lieu")
    category_name: Optional[str] = Field(None, alias="ten_nhom_nguyen_lieu")
    stall_count: int = Field(0, alias="so_gian_hang")
    original_price: Optional[int] = Field(None, alias="gia_goc")
    final_price: Optional[Any] = Field(None, alias="gia_cuoi")
    updated_at: Optional[datetime] = Field(None, alias="ngay_cap_nhat")
    image: Optional[str] = Field(None, alias="hinh_anh")
    
    class Config:
        populate_by_name = True


class IngredientListResponse(BaseModel):
    data: List[IngredientItem]
    meta: MetaResponse


# ==================== CATEGORY (DANH MỤC NGUYÊN LIỆU) ====================

class CategoryQuery(PaginationParams):
    pass


class CategoryItem(BaseModel):
    category_id: str = Field(..., alias="ma_nhom_nguyen_lieu")
    category_name: str = Field(..., alias="ten_nhom_nguyen_lieu")
    ingredient_count: int = Field(0, alias="so_nguyen_lieu")
    
    class Config:
        populate_by_name = True


class CategoryListResponse(BaseModel):
    data: List[CategoryItem]
    meta: MetaResponse


# ==================== DISH CATEGORY (DANH MỤC MÓN ĂN) ====================

class DishCategoryQuery(PaginationParams):
    pass


class DishCategoryItem(BaseModel):
    category_id: str = Field(..., alias="ma_danh_muc_mon_an")
    category_name: str = Field(..., alias="ten_danh_muc_mon_an")
    dish_count: int = Field(0, alias="so_mon_an")
    
    class Config:
        populate_by_name = True


class DishCategoryListResponse(BaseModel):
    data: List[DishCategoryItem]
    meta: MetaResponse


# ==================== DISH (MÓN ĂN) ====================

class DishQuery(PaginationParams):
    category_id: Optional[str] = Field(None, alias="ma_danh_muc_mon_an")
    has_image: Optional[bool] = Field(None, alias="hinh_anh")
    
    class Config:
        populate_by_name = True


class DishItem(BaseModel):
    dish_id: str = Field(..., alias="ma_mon_an")
    dish_name: str = Field(..., alias="ten_mon_an")
    image: Optional[str] = Field(None, alias="hinh_anh")
    categories: List[dict] = Field([], alias="danh_muc")
    
    class Config:
        populate_by_name = True


class DishListResponse(BaseModel):
    data: List[DishItem]
    meta: MetaResponse


class DishDetailQuery(BaseModel):
    servings: Optional[int] = Field(None, alias="khau_phan", ge=1)
    
    class Config:
        populate_by_name = True


class DishDetailResponse(BaseModel):
    success: bool = True
    detail: dict
