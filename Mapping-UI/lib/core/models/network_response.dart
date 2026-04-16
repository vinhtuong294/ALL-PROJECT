/// Generic network response wrapper
/// Sử dụng để wrap response từ API
class NetworkResponse<T> {
  final T? data;
  final String? message;
  final bool success;
  final int? statusCode;

  NetworkResponse({
    this.data,
    this.message,
    required this.success,
    this.statusCode,
  });

  /// Success response
  factory NetworkResponse.success(
    T data, {
    String? message,
    int statusCode = 200,
  }) {
    return NetworkResponse(
      data: data,
      message: message,
      success: true,
      statusCode: statusCode,
    );
  }

  /// Error response
  factory NetworkResponse.error(
    String message, {
    int? statusCode,
  }) {
    return NetworkResponse(
      message: message,
      success: false,
      statusCode: statusCode,
    );
  }

  /// Check if response is successful
  bool get isSuccess => success && data != null;

  /// Check if response is error
  bool get isError => !success;

  @override
  String toString() {
    return 'NetworkResponse(success: $success, data: $data, message: $message, statusCode: $statusCode)';
  }
}
