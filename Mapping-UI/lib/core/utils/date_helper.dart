import 'package:intl/intl.dart';
import '../config/app_constant.dart';

/// Helper class để xử lý các tác vụ liên quan đến ngày tháng
class DateHelper {
  DateHelper._();

  /// Format DateTime thành string theo định dạng mặc định
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat(AppConstant.dateFormat).format(date);
  }

  /// Format DateTime thành string theo định dạng tùy chỉnh
  static String formatDateTime(DateTime? date, {String? pattern}) {
    if (date == null) return '';
    final format = pattern ?? AppConstant.dateTimeFormat;
    return DateFormat(format).format(date);
  }

  /// Format time only
  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return DateFormat(AppConstant.timeFormat).format(date);
  }

  /// Parse string thành DateTime
  static DateTime? parseDate(String? dateString, {String? pattern}) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      final format = pattern ?? AppConstant.dateFormat;
      return DateFormat(format).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse API DateTime string
  static DateTime? parseApiDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Format API DateTime
  static String formatApiDateTime(DateTime? date) {
    if (date == null) return '';
    return date.toIso8601String();
  }

  /// Kiểm tra ngày có phải hôm nay không
  static bool isToday(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Kiểm tra ngày có phải hôm qua không
  static bool isYesterday(DateTime? date) {
    if (date == null) return false;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  /// Lấy số ngày giữa 2 ngày
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// Format relative time (e.g., "2 giờ trước", "3 ngày trước")
  static String getRelativeTime(DateTime? date) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks tuần trước';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months tháng trước';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years năm trước';
    }
  }

  /// Lấy ngày đầu tuần
  static DateTime getFirstDayOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// Lấy ngày cuối tuần
  static DateTime getLastDayOfWeek(DateTime date) {
    return date.add(Duration(days: DateTime.daysPerWeek - date.weekday));
  }

  /// Lấy ngày đầu tháng
  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Lấy ngày cuối tháng
  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Kiểm tra năm nhuận
  static bool isLeapYear(int year) {
    return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
  }

  /// Lấy số ngày trong tháng
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
