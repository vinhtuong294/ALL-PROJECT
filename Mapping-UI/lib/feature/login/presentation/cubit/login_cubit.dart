import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/services/auth/auth_service.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/config/app_config.dart';

part 'login_state.dart';

/// Login Cubit quản lý logic nghiệp vụ của màn hình đăng nhập
/// 
/// Chức năng chính:
/// - Xử lý đăng nhập với email và mật khẩu
/// - Validate input
/// - Quản lý trạng thái hiển thị mật khẩu
/// - Xử lý lỗi và hiển thị thông báo
class LoginCubit extends Cubit<LoginState> {
  final AuthService _authService;
  
  LoginCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(LoginInitial());

  bool _isPasswordVisible = false;

  bool get isPasswordVisible => _isPasswordVisible;

  /// Toggle hiển thị/ẩn mật khẩu
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    emit(LoginPasswordVisibilityChanged(isPasswordVisible: _isPasswordVisible));
  }

  /// Validate email hoặc username
  String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Vui lòng nhập tên đăng nhập hoặc email';
    }
    
    // Chấp nhận cả username (không có @) và email (có @)
    // Username: chỉ chứa chữ cái, số, dấu gạch dưới, dấu chấm
    // Email: phải có @ và domain hợp lệ
    
    if (email.contains('@')) {
      // Nếu có @ thì validate như email
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      
      if (!emailRegex.hasMatch(email)) {
        return 'Email không hợp lệ';
      }
    } else {
      // Nếu không có @ thì validate như username
      final usernameRegex = RegExp(
        r'^[a-zA-Z0-9._]{3,}$',
      );
      
      if (!usernameRegex.hasMatch(email)) {
        return 'Tên đăng nhập phải có ít nhất 3 ký tự (chữ cái, số, dấu chấm, gạch dưới)';
      }
    }
    
    return null;
  }

  /// Validate password
  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    
    if (password.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    
    return null;
  }

  /// Xử lý đăng nhập
  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('🎯 [LOGIN] Bắt đầu xử lý đăng nhập');
      AppLogger.info('📝 [LOGIN] Username/Email: $email');
    }

    // Validate inputs
    final emailError = validateEmail(email);
    final passwordError = validatePassword(password);

    if (emailError != null || passwordError != null) {
      if (AppConfig.enableApiLogging) {
        AppLogger.warning('⚠️ [LOGIN] Validation failed');
        AppLogger.warning('   Email error: $emailError');
        AppLogger.warning('   Password error: $passwordError');
      }
      emit(LoginValidationError(
        emailError: emailError,
        passwordError: passwordError,
      ));
      return;
    }

    if (AppConfig.enableApiLogging) {
      AppLogger.info('✅ [LOGIN] Validation passed');
    }

    try {
      emit(LoginLoading());

      if (AppConfig.enableApiLogging) {
        AppLogger.info('🔄 [LOGIN] Đang gọi API login...');
      }

      // Call API login
      await _authService.login(
        username: email,
        password: password,
      );

      // Check if cubit is still open before emitting success
      if (!isClosed) {
        if (AppConfig.enableApiLogging) {
          AppLogger.info('🎉 [LOGIN] Login thành công!');
        }

        // Login successful
        emit(const LoginSuccess(
          message: '✅ Đăng nhập thành công!',
        ));
      }
    } on UnauthorizedException catch (e) {
      // Wrong credentials
      if (AppConfig.enableApiLogging) {
        AppLogger.error('🔒 [LOGIN] Unauthorized: ${e.message}');
      }
      if (!isClosed) {
        emit(LoginFailure(
          errorMessage: '❌ ${e.message}',
        ));
      }
    } on NetworkException catch (e) {
      // Network error
      if (AppConfig.enableApiLogging) {
        AppLogger.error('🌐 [LOGIN] Network error: ${e.message}');
      }
      if (!isClosed) {
        emit(LoginFailure(
          errorMessage: '❌ Lỗi kết nối: ${e.message}',
        ));
      }
    } on AppException catch (e) {
      // Other app exceptions
      if (AppConfig.enableApiLogging) {
        AppLogger.error('⚠️ [LOGIN] App exception: ${e.message}');
      }
      if (!isClosed) {
        emit(LoginFailure(
          errorMessage: '❌ ${e.message}',
        ));
      }
    } catch (e) {
      // Unknown error
      if (AppConfig.enableApiLogging) {
        AppLogger.error('💥 [LOGIN] Unknown error: ${e.toString()}');
      }
      if (!isClosed) {
        emit(LoginFailure(
          errorMessage: '❌ Đã có lỗi xảy ra: ${e.toString()}',
        ));
      }
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    try {
      await _authService.logout();
      emit(LoginInitial());
    } catch (e) {
      // Handle logout error silently
    }
  }

  /// Đăng nhập với Google
  Future<void> loginWithGoogle() async {
    try {
      emit(LoginLoading());

      // TODO: Implement Google Sign-In
      await Future.delayed(const Duration(seconds: 2));

      if (!isClosed) {
        emit(const LoginSuccess(message: 'Đăng nhập Google thành công!'));
      }
    } catch (e) {
      if (!isClosed) {
        emit(LoginFailure(
          errorMessage: 'Đăng nhập Google thất bại: ${e.toString()}',
        ));
      }
    }
  }

  /// Đăng nhập với Facebook
  Future<void> loginWithFacebook() async {
    try {
      emit(LoginLoading());

      // TODO: Implement Facebook Sign-In
      await Future.delayed(const Duration(seconds: 2));

      if (!isClosed) {
        emit(const LoginSuccess(message: 'Đăng nhập Facebook thành công!'));
      }
    } catch (e) {
      if (!isClosed) {
        emit(LoginFailure(
          errorMessage: 'Đăng nhập Facebook thất bại: ${e.toString()}',
        ));
      }
    }
  }

  /// Reset state về initial
  void resetState() {
    emit(LoginInitial());
  }
}
