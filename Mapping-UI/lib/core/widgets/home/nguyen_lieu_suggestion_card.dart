import 'package:flutter/material.dart';
import '../../../core/models/chat_ai_model.dart';
import '../../../core/utils/price_formatter.dart';

/// Widget hiển thị card nguyên liệu suggestion từ AI
class NguyenLieuSuggestionCard extends StatelessWidget {
  final NguyenLieuSuggestion nguyenLieu;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;

  const NguyenLieuSuggestionCard({
    super.key,
    required this.nguyenLieu,
    required this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final hasShop = nguyenLieu.gianHangSuggest != null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hình ảnh nguyên liệu
            Container(
              width: 160,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: nguyenLieu.hinhAnh != null && nguyenLieu.hinhAnh!.isNotEmpty
                    ? Image.network(
                        nguyenLieu.hinhAnh!,
                        width: 160,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(
                            Icons.shopping_basket,
                            size: 40,
                            color: Color(0xFF00B40F),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.shopping_basket,
                          size: 40,
                          color: Color(0xFF00B40F),
                        ),
                      ),
              ),
            ),
            
            // Tên nguyên liệu
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                nguyenLieu.tenNguyenLieu,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                  height: 1.2,
                ),
              ),
            ),
            
            // Định lượng (nếu có)
            if (nguyenLieu.dinhLuong != null && nguyenLieu.dinhLuong!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Định lượng: ${nguyenLieu.dinhLuong!.trim()} ${nguyenLieu.donVi ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ),
            
            // Thông tin gian hàng (nếu có)
            if (hasShop) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên gian hàng
                    Text(
                      nguyenLieu.gianHangSuggest!.tenGianHang,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF00B40F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Vị trí
                    Text(
                      nguyenLieu.gianHangSuggest!.viTri,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Giá
                    Text(
                      '${PriceFormatter.formatPrice(int.parse(nguyenLieu.gianHangSuggest!.gia))}/${nguyenLieu.gianHangSuggest!.donViBan}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF3B30),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const Spacer(),
            
            // Nút hành động
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  // Nút xem chi tiết
                  Expanded(
                    child: GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF008EDB)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Xem',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF008EDB),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Nút thêm giỏ hàng (nếu có thể)
                  if (nguyenLieu.actions.canAddToCart && hasShop) ...[
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B40F),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Thêm',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
