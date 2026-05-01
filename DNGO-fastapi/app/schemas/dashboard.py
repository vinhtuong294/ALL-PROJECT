from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class DashboardStats(BaseModel):
    manager_name: str
    market_name: str
    district_name: str
    active_merchants: int
    total_stalls: int
    orders_today: int
    monthly_tax_revenue: float
    pending_tax_stalls: int
    
    class Config:
        from_attributes = True

class CategoryStat(BaseModel):
    ma: str
    ten: str
    count: int

class StationInfo(BaseModel):
    stall_id: str
    stall_name: str
    status: str # mo_cua / dong_cua
    user_name: str
    category_ma: str

class StatusLogInfo(BaseModel):
    log_id: str
    time: str
    stall_id: str
    stall_name: str
    user_name: str
    status: str
    status_label: str
    note: Optional[str]

class MarketDashboardV2(BaseModel):
    total_stalls: int
    open_stalls: int
    closed_stalls: int
    categories: List[CategoryStat]
    stalls: List[StationInfo]
    recent_logs: List[StatusLogInfo]

class UpdateStallStatusRequest(BaseModel):
    status: str
    note: Optional[str] = None
