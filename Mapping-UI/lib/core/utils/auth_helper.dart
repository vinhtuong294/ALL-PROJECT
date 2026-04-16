import 'package:flutter/material.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/error/app_exception.dart';

/// Helper functions cho authentication
class AuthHelper {
  static final AuthService _authService = AuthService();

  /// Hàm đăng nhập - Gọi từ UI
  /// 
  /// Tham số:
  /// - context: BuildContext để hiển thị SnackBar
  /// - username: Tên đăng nhập
  /// - password: Mật khẩu
  /// 
  /// Return: true nếu đăng nhập thành công, false nếu thất bại
  static Future<bool> logIn(
    BuildContext context,
    String username,
    String password,
  ) async {
    try {
      // Call API login
      await _authService.login(
        username: username,
        password: password,
      );

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đăng nhập thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      return true;
    } on UnauthorizedException catch (e) {
      // Wrong credentials
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    } on NetworkException catch (e) {
      // Network error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi kết nối: ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    } on AppException catch (e) {
      // Other app exceptions
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    } catch (e) {
      // Unknown error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Đã có lỗi xảy ra: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// Hàm đăng xuất
  /// 
  /// Xóa token và user data khỏi SharedPreferences
  static Future<void> logOut() async {
    await _authService.logout();
  }

  /// Kiểm tra trạng thái đăng nhập
  static Future<bool> isLoggedIn() async {
    return await _authService.isLoggedIn();
  }

  /// Lấy token hiện tại
  static Future<String?> getToken() async {
    return await _authService.getToken();
  }

  /// Lấy thông tin user hiện tại
  static Future<dynamic> getUserData() async {
    return await _authService.getUserData();
  }
}
