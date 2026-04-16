part of 'signup_cubit.dart';

/// Base class cho tất cả các state của SignUp
abstract class SignUpState extends Equatable {
  const SignUpState();

  @override
  List<Object?> get props => [];
}

/// State khởi tạo ban đầu
class SignUpInitial extends SignUpState {}

/// State đang xử lý đăng ký
class SignUpLoading extends SignUpState {}

/// State đăng ký thành công
class SignUpSuccess extends SignUpState {
  final String message;

  const SignUpSuccess({this.message = 'Đăng ký thành công!'});

  @override
  List<Object?> get props => [message];
}

/// State đăng ký thất bại
class SignUpFailure extends SignUpState {
  final String errorMessage;

  const SignUpFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

/// State hiển thị/ẩn mật khẩu
class SignUpPasswordVisibilityChanged extends SignUpState {
  final bool isPasswordVisible;

  const SignUpPasswordVisibilityChanged({required this.isPasswordVisible});

  @override
  List<Object?> get props => [isPasswordVisible];
}

/// State thay đổi vai trò
class SignUpRoleChanged extends SignUpState {
  final String role;

  const SignUpRoleChanged({required this.role});

  @override
  List<Object?> get props => [role];
}

/// State validation error
class SignUpValidationError extends SignUpState {
  final String? nameError;
  final String? phoneError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? roleError;

  const SignUpValidationError({
    this.nameError,
    this.phoneError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.roleError,
  });

  @override
  List<Object?> get props => [
        nameError,
        phoneError,
        emailError,
        passwordError,
        confirmPasswordError,
        roleError,
      ];
}
