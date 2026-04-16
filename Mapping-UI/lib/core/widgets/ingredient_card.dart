import 'package:flutter/material.dart';

/// Ingredient Card Widget
/// Hỗ trợ cả layout ngang (horizontal) và dọc (vertical/grid)
class IngredientCard extends StatelessWidget {
  final String name;
  final String price;
  final String imagePath;
  final String? shopName;
  final bool hasDiscount;
  final String? originalPrice;
  final bool isGridLayout; // true = vertical/grid, false = horizontal
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onBuyNow;
  final VoidCallback? onTap;

  const IngredientCard({
    super.key,
    required this.name,
    required this.price,
    required this.imagePath,
    this.shopName,
    this.hasDiscount = false,
    this.originalPrice,
    this.isGridLayout = false,
    this.onFavoriteTap,
    this.onAddToCart,
    this.onBuyNow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return isGridLayout ? _buildGridLayout() : _buildHorizontalLayout();
  }

  // Horizontal Layout (cho IngredientScreen)
  Widget _buildHorizontalLayout() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHorizontalImage(),
            Expanded(
              child: _buildHorizontalDetails(),
            ),
          ],
        ),
      ),
    );
  }

  // Grid Layout (cho ProductDetailScreen)
  Widget _buildGridLayout() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Không hiển thị ảnh, chỉ có thông tin
            Expanded(
              child: _buildGridDetails(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalImage() {
    // Placeholder widget khi không có ảnh hoặc lỗi
    final placeholderWidget = Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: const Icon(
        Icons.shopping_basket,
        size: 40,
        color: Color(0xFF00B40F),
      ),
    );

    // Nếu không có ảnh, hiển thị placeholder
    if (imagePath.isEmpty) {
      return placeholderWidget;
    }

    // Kiểm tra xem có phải URL không
    final isNetworkImage = imagePath.startsWith('http://') || imagePath.startsWith('https://');

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        bottomLeft: Radius.circular(12),
      ),
      child: isNetworkImage
          ? Image.network(
              imagePath,
              width: 140,
              height: 140,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 140,
                  height: 140,
                  color: Colors.grey[200],
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: const Color(0xFF00B40F),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => placeholderWidget,
            )
          : Image.asset(
              imagePath,
              width: 140,
              height: 140,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => placeholderWidget,
            ),
    );
  }



  Widget _buildHorizontalDetails() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onFavoriteTap,
                child: const Icon(
                  Icons.favorite_border,
                  size: 20,
                  color: Color(0xFFFF0000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          if (shopName != null && shopName!.isNotEmpty)
            Text(
              shopName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E93),
              ),
            ),
          const SizedBox(height: 1),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (hasDiscount && originalPrice != null)
                Text(
                  originalPrice!,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E93),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                price,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF3B30),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onAddToCart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF008EDB)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Thêm giỏ hàng',
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
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onBuyNow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B40F),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Mua ngay',
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
          ),
        ],
      ),
    );
  }

  Widget _buildGridDetails() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product Name
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 2),
          
          // Shop Name
          if (shopName != null && shopName!.isNotEmpty)
            Text(
              shopName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E93),
              ),
            ),
          
          const Spacer(),
          
          // Price
          Row(
            children: [
              if (hasDiscount && originalPrice != null) ...[
                Text(
                  originalPrice!,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E93),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  price,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF3B30),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onFavoriteTap,
                child: const Icon(
                  Icons.favorite_border,
                  size: 14,
                  color: Color(0xFFFF0000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onAddToCart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF008EDB)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Thêm',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF008EDB),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: onBuyNow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B40F),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Mua',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
