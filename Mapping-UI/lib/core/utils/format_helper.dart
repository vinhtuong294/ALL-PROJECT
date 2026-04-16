import 'package:intl/intl.dart';

/// Helper class để format số, tiền tệ, phần trăm
class FormatHelper {
  FormatHelper._();

  /// Format số thành tiền tệ (VND)
  static String formatCurrency(num? amount, {String? currency}) {
    if (amount == null) return '0 ₫';
    
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: currency ?? '₫',
      decimalDigits: 0,
    );
    
    return formatter.format(amount);
  }

  /// Format số thành phần trăm
  static String formatPercentage(num? value, {int decimalDigits = 0}) {
    if (value == null) return '0%';
    return '${value.toStringAsFixed(decimalDigits)}%';
  }

  /// Format số với dấu phân cách hàng nghìn
  static String formatNumber(num? value, {int decimalDigits = 0}) {
    if (value == null) return '0';
    
    final formatter = NumberFormat('#,##0${decimalDigits > 0 ? '.${'0' * decimalDigits}' : ''}', 'vi_VN');
    return formatter.format(value);
  }

  /// Format số điện thoại (10-11 số)
  static String formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    
    // Remove all non-digit characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length == 10) {
      // Format: 0xxx xxx xxx
      return '${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7)}';
    } else if (digits.length == 11) {
      // Format: 0xxx xxxx xxx
      return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8)}';
    }
    
    return phone;
  }

  /// Format file size
  static String formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  /// Format rating (1-5 sao)
  static String formatRating(num? rating) {
    if (rating == null) return '0.0';
    return rating.toStringAsFixed(1);
  }

  /// Format giảm giá
  static String formatDiscount(num? originalPrice, num? discountedPrice) {
    if (originalPrice == null || discountedPrice == null || originalPrice == 0) {
      return '0%';
    }
    
    final discount = ((originalPrice - discountedPrice) / originalPrice * 100);
    return formatPercentage(discount);
  }

  /// Format duration (seconds to hh:mm:ss)
  static String formatDuration(int? seconds) {
    if (seconds == null || seconds < 0) return '00:00';
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  /// Rút gọn văn bản
  static String truncateText(String? text, int maxLength, {String suffix = '...'}) {
    if (text == null || text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    
    return '${text.substring(0, maxLength)}$suffix';
  }

  /// Format số lượng (k, M, B cho số lớn)
  static String formatCompactNumber(num? value) {
    if (value == null) return '0';
    
    if (value < 1000) {
      return value.toString();
    } else if (value < 1000000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (value < 1000000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else {
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    }
  }

  /// Capitalize first letter
  static String capitalize(String? text) {
    if (text == null || text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Title case (capitalize first letter of each word)
  static String titleCase(String? text) {
    if (text == null || text.isEmpty) return '';
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Remove HTML tags
  static String removeHtmlTags(String? html) {
    if (html == null || html.isEmpty) return '';
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
