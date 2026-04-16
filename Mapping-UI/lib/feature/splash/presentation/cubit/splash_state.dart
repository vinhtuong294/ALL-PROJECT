part of 'splash_cubit.dart';

/// Base class cho tất cả các state của Splash
abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

/// State khởi tạo ban đầu
class SplashInitial extends SplashState {}

/// State đang tải dữ liệu
class SplashLoading extends SplashState {}

/// State người dùng đã đăng nhập
/// 
/// Sau state này, ứng dụng sẽ điều hướng đến màn hình phù hợp theo vai trò
class SplashAuthenticated extends SplashState {
  final String role; // nguoi_mua hoặc nguoi_ban

  const SplashAuthenticated({required this.role});

  @override
  List<Object?> get props => [role];
}

/// State người dùng chưa đăng nhập
/// 
/// Sau state này, ứng dụng sẽ điều hướng đến màn hình Onboarding hoặc Login
class SplashUnauthenticated extends SplashState {}

/// State vai trò không hợp lệ (không phải nguoi_mua)
class SplashInvalidRole extends SplashState {
  final String role;
  final String message;

  const SplashInvalidRole({
    required this.role,
    this.message = 'Tài khoản của bạn không có quyền truy cập ứng dụng này',
  });

  @override
  List<Object?> get props => [role, message];
}

/// State xảy ra lỗi trong quá trình khởi tạo
class SplashError extends SplashState {
  final String message;

  const SplashError({required this.message});

  @override
  List<Object?> get props => [message];
}
