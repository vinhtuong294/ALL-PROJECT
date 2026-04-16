import 'package:intl/intl.dart';

/// Utility class để format giá tiền
class PriceFormatter {
  /// Format số thành chuỗi với dấu phẩy ngăn cách hàng nghìn
  /// VD: 10000 -> "10,000"
  static String formatNumber(num number) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(number);
  }

  /// Format giá từ string hoặc number
  /// VD: "10000" -> "10,000đ"
  /// VD: 10000 -> "10,000đ"
  static String formatPrice(dynamic price) {
    if (price == null) return '0đ';
    
    // Nếu là string
    if (price is String) {
      // Loại bỏ ký tự không phải số
      final cleanPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
      if (cleanPrice.isEmpty) return '0đ';
      
      try {
        final number = double.parse(cleanPrice);
        if (number <= 0) return '0đ';
        return '${formatNumber(number)}đ';
      } catch (e) {
        return '0đ';
      }
    }
    
    // Nếu là number
    if (price is num) {
      if (price <= 0) return '0đ';
      return '${formatNumber(price)}đ';
    }
    
    return '0đ';
  }

  /// Format giá với đơn vị
  /// VD: 10000, "kg" -> "10,000đ/kg"
  static String formatPriceWithUnit(dynamic price, String? unit) {
    final formattedPrice = formatPrice(price);
    if (formattedPrice == '0đ') return formattedPrice;
    if (unit == null || unit.isEmpty) return formattedPrice;
    return '$formattedPrice/$unit';
  }

  /// Parse giá từ string về number
  /// VD: "10,000đ" -> 10000
  static double? parsePrice(String? priceString) {
    if (priceString == null || priceString.isEmpty) return null;
    
    // Loại bỏ ký tự không phải số
    final cleanPrice = priceString.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleanPrice.isEmpty) return null;
    
    try {
      return double.parse(cleanPrice);
    } catch (e) {
      return null;
    }
  }
}
