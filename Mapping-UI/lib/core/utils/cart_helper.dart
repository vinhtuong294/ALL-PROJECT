import 'package:flutter/material.dart';
import '../services/cart_api_service.dart';
import '../widgets/cart_badge_icon.dart';

/// Helper functions cho giỏ hàng
class CartHelper {
  static final CartApiService _cartService = CartApiService();

  /// Thêm sản phẩm vào giỏ hàng
  /// 
  /// Returns true nếu thành công, false nếu thất bại
  static Future<bool> addToCart({
    required BuildContext context,
    required String maNguyenLieu,
    required String maGianHang,
    double soLuong = 1,
    String maCho = 'C01',
    bool showSuccessMessage = true,
  }) async {
    try {
      final response = await _cartService.addToCart(
        maNguyenLieu: maNguyenLieu,
        maGianHang: maGianHang,
        soLuong: soLuong,
        maCho: maCho,
      );

      if (response.success) {
        // Refresh cart badge
        refreshCartBadge();

        // Show success message
        if (showSuccessMessage && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm vào giỏ hàng!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        return true;
      } else {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Không thể thêm vào giỏ hàng'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        return false;
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        final errorMessage = e.toString().contains('not logged in')
            ? 'Vui lòng đăng nhập để thêm vào giỏ hàng'
            : 'Không thể thêm vào giỏ hàng. Vui lòng thử lại!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      return false;
    }
  }
}
