import 'package:flutter/material.dart';

/// Cart Icon With Badge Widget
/// Hiển thị icon giỏ hàng với badge số lượng sản phẩm
class CartIconWithBadge extends StatelessWidget {
  final int itemCount;
  final VoidCallback? onTap;

  const CartIconWithBadge({
    super.key,
    this.itemCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF00B40F).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Cart Icon
            const Center(
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 24,
                color: Color(0xFF00B40F),
              ),
            ),
            
            // Badge
            if (itemCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      itemCount > 99 ? '99+' : itemCount.toString(),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
