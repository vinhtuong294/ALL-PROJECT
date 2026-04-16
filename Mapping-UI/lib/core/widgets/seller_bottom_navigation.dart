import 'package:flutter/material.dart';

/// Seller Bottom Navigation Widget
/// Dùng cho các màn hình của người bán
class SellerBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const SellerBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            iconAsset: 'assets/img/Vector.png',
            label: 'Trang chủ',
            index: 0,
          ),
          _buildNavItem(
            context,
            iconAsset: 'assets/img/product.png',
            label: 'Sản phẩm',
            index: 1,
          ),
          _buildNavItem(
            context,
            iconAsset: 'assets/img/order.png',
            label: 'Đơn hàng',
            index: 2,
          ),
          _buildNavItem(
            context,
            iconAsset: 'assets/img/doanhso.png',
            label: 'Doanh số',
            index: 3,
          ),
          _buildNavItem(
            context,
            iconAsset: 'assets/img/usser.png',
            label: 'Tài khoản',
            index: 4,
          ),
        ],
      ),
    );
  }

  /// Center item (Avatar/Home)
  Widget _buildCenterItem(BuildContext context) {
    
    
    return InkWell(
      onTap: () => {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Container(
          width: 58,
          height: 58,
            child: Image.asset(
              'assets/img/user_personas_presentation-26cd3a.png',
              width: 58,
              height: 58,
              fit: BoxFit.cover,
            ),
          
        ),
      ),
    );
  }

  /// Bottom Navigation Item
  Widget _buildNavItem(
    BuildContext context, {
    required String iconAsset,
    required String label,
    required int index,
  }) {
    final isSelected = index == currentIndex;
    
    return InkWell(
      onTap: () {
        if (isSelected) return;
        onTap?.call(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                isSelected ? const Color(0xFF00B40F) : Colors.black54,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                iconAsset,
                width: 28,
                height: 28,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.circle,
                    size: 28,
                    color: isSelected ? const Color(0xFF00B40F) : Colors.black54,
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 12,
                height: 1.33,
                color: isSelected ? const Color(0xFF00B40F) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
