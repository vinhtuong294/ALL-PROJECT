import '../config/app_constant.dart';

/// Base exception cho toàn bộ ứng dụng
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;

  AppException({
    required this.message,
    this.statusCode,
    this.error,
  });

  @override
  String toString() => message;
}

/// Exception khi có lỗi mạng (không kết nối được)
class NetworkException extends AppException {
  NetworkException({
    String? message,
  }) : super(
          message: message ?? AppConstant.networkErrorMessage,
        );
}

/// Exception khi request timeout
class TimeoutException extends AppException {
  TimeoutException({
    String? message,
  }) : super(
          message: message ?? AppConstant.timeoutErrorMessage,
        );
}

/// Exception khi server trả về lỗi (4xx, 5xx)
class ServerException extends AppException {
  ServerException({
    String? message,
    int? statusCode,
    dynamic error,
  }) : super(
          message: message ?? AppConstant.serverErrorMessage,
          statusCode: statusCode,
          error: error,
        );
}

/// Exception khi unauthorized (401)
class UnauthorizedException extends AppException {
  UnauthorizedException({
    String? message,
  }) : super(
          message: message ?? AppConstant.unauthorizedErrorMessage,
          statusCode: 401,
        );
}

/// Exception khi resource not found (404)
class NotFoundException extends AppException {
  NotFoundException({
    String? message,
  }) : super(
          message: message ?? 'Không tìm thấy dữ liệu',
          statusCode: 404,
        );
}

/// Exception khi validation failed
class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  ValidationException({
    String? message,
    this.errors,
  }) : super(
          message: message ?? 'Dữ liệu không hợp lệ',
          statusCode: 422,
        );
}

/// Exception khi parse JSON failed
class ParseException extends AppException {
  ParseException({
    String? message,
    dynamic error,
  }) : super(
          message: message ?? 'Lỗi xử lý dữ liệu',
          error: error,
        );
}

/// Exception khi cache error
class CacheException extends AppException {
  CacheException({
    String? message,
    dynamic error,
  }) : super(
          message: message ?? 'Lỗi lưu trữ dữ liệu',
          error: error,
        );
}

/// Exception khi permission denied
class PermissionDeniedException extends AppException {
  PermissionDeniedException({
    String? message,
  }) : super(
          message: message ?? 'Không có quyền truy cập',
          statusCode: 403,
        );
}

/// Exception khi có conflict (409) - ví dụ: username đã tồn tại
class ConflictException extends AppException {
  ConflictException({
    String? message,
  }) : super(
          message: message ?? 'Dữ liệu đã tồn tại',
          statusCode: 409,
        );
}
