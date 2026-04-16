part of 'login_cubit.dart';

/// Base class cho tất cả các state của Login
abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

/// State khởi tạo ban đầu
class LoginInitial extends LoginState {}

/// State đang xử lý đăng nhập
class LoginLoading extends LoginState {}

/// State đăng nhập thành công
class LoginSuccess extends LoginState {
  final String message;

  const LoginSuccess({this.message = 'Đăng nhập thành công!'});

  @override
  List<Object?> get props => [message];
}

/// State đăng nhập thất bại
class LoginFailure extends LoginState {
  final String errorMessage;

  const LoginFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

/// State hiển thị/ẩn mật khẩu
class LoginPasswordVisibilityChanged extends LoginState {
  final bool isPasswordVisible;

  const LoginPasswordVisibilityChanged({required this.isPasswordVisible});

  @override
  List<Object?> get props => [isPasswordVisible];
}

/// State validation error
class LoginValidationError extends LoginState {
  final String? emailError;
  final String? passwordError;

  const LoginValidationError({
    this.emailError,
    this.passwordError,
  });

  @override
  List<Object?> get props => [emailError, passwordError];
}
