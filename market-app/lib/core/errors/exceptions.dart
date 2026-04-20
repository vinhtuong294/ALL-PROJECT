import 'package:dio/dio.dart';
import 'failures.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  factory AppException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(message: 'Kết nối timeout, vui lòng thử lại');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 'Lỗi từ server';
        return AppException(message: message, statusCode: statusCode);
      case DioExceptionType.connectionError:
        return const AppException(message: 'Không có kết nối internet');
      default:
        return const AppException(message: 'Đã xảy ra lỗi không xác định');
    }
  }

  Failure toFailure() {
    if (statusCode == 401) return AuthFailure(message: message, statusCode: statusCode);
    if (statusCode == 404) return const NotFoundFailure();
    return ServerFailure(message: message, statusCode: statusCode);
  }
}
