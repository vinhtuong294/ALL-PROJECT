from typing import Optional, Dict, Any


def paginate(
    page: Optional[int] = 1,
    limit: Optional[int] = 10
) -> Dict[str, int]:
    """
    Tính toán offset và limit cho pagination
    
    Args:
        page: Số trang (bắt đầu từ 1)
        limit: Số items mỗi trang
    
    Returns:
        Dict với page, limit, skip, take
    """
    page = max(1, page or 1)
    limit = min(100, max(1, limit or 10))
    skip = (page - 1) * limit
    
    return {
        "page": page,
        "limit": limit,
        "skip": skip,
        "take": limit
    }


def create_meta(page: int, limit: int, total: int) -> Dict[str, Any]:
    """
    Tạo metadata cho response pagination
    """
    return {
        "page": page,
        "limit": limit,
        "total": total,
        "hasNext": (page * limit) < total
    }
