import 'package:logger/logger.dart';

/// Logger toàn cục để ghi log trong ứng dụng
/// Sử dụng package logger để format đẹp và dễ đọc
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Log debug message
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  static void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal/critical message
  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log API request
  static void logRequest(String method, String url, {Map<String, dynamic>? data}) {
    _logger.i('🌐 API Request: $method $url${data != null ? '\nData: $data' : ''}');
  }

  /// Log API response
  static void logResponse(int statusCode, String url, {dynamic data}) {
    _logger.i('✅ API Response: $statusCode $url${data != null ? '\nData: $data' : ''}');
  }

  /// Log API error
  static void logApiError(String method, String url, dynamic error) {
    _logger.e('❌ API Error: $method $url\nError: $error');
  }
}
