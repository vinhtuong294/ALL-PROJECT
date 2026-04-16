import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dngo/feature/user/presentation/cubit/user_state.dart';
import '../../../../core/services/auth/auth_service.dart';
import '../../../../core/services/home_state_service.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/app_logger.dart';

/// Cubit quản lý state cho User/Account Screen
class UserCubit extends Cubit<UserState> {
  final AuthService _authService;

  UserCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const UserState());

  /// Load thông tin user từ API
  Future<void> loadUserData({
    int? pendingOrders,
    int? processingOrders,
    int? shippingOrders,
    int? completedOrders,
  }) async {
    emit(state.copyWith(isLoading: true));

    try {
      // Gọi API để lấy thông tin người dùng
      final user = await _authService.getCurrentUser();

      // Check if cubit is still open before emitting
      if (!isClosed) {
        AppLogger.info('👤 [USER] Loaded user: ${user.tenNguoiDung}');

        // Cập nhật state với thông tin người dùng thực
        emit(state.copyWith(
          userName: user.tenNguoiDung,
          userImage: 'assets/img/user_profile_image.png', // Sử dụng ảnh mặc định
          pendingOrders: pendingOrders ?? 1,
          processingOrders: processingOrders ?? 0,
          shippingOrders: shippingOrders ?? 3,
          completedOrders: completedOrders ?? 1,
          isLoading: false,
          errorMessage: null,
        ));
      }
    } on UnauthorizedException catch (e) {
      // Token hết hạn - logout và yêu cầu đăng nhập lại
      AppLogger.warning('❌ [USER] Unauthorized: ${e.message}');
      await _authService.logout();
      if (!isClosed) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          requiresLogin: true, // Thêm flag để UI xử lý
        ));
      }
    } on NetworkException catch (e) {
      // Lỗi mạng
      AppLogger.error('🌐 [USER] Network error: ${e.message}');
      if (!isClosed) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: e.message,
        ));
      }
    } catch (e) {
      // Lỗi khác
      AppLogger.error('💥 [USER] Error: ${e.toString()}');
      if (!isClosed) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải thông tin người dùng',
        ));
      }
    }
  }

  /// Navigate to Favorites screen
  void navigateToFavorites() {
    // Navigation will be handled by screen
  }

  /// Navigate to MCard screen
  void navigateToMCard() {
    // Navigation will be handled by screen
  }

  /// Navigate to Terms of Service
  void navigateToTermsOfService() {
    // Navigation will be handled by screen
  }

  /// Navigate to Language settings
  void navigateToLanguage() {
    // Navigation will be handled by screen
  }

  /// Navigate to Customer Care
  void navigateToCustomerCare() {
    // Navigation will be handled by screen
  }

  /// Navigate to Support
  void navigateToSupport() {
    // Navigation will be handled by screen
  }

  /// Delete account
  void deleteAccount() {
    // Implement delete account logic
  }

  /// Logout
  Future<void> logout() async {
    try {
      // Gọi API logout và xóa token
      await _authService.logout();
      AppLogger.info('🚪 [USER] Logout successful');
      
      // Reset HomeCubit (bao gồm cả chat messages và conversationId)
      HomeStateService.reset();
      AppLogger.info('🔄 [USER] HomeCubit reset on logout');
      
      // Reset state
      emit(const UserState());
    } catch (e) {
      AppLogger.error('💥 [USER] Logout error: ${e.toString()}');
      // Vẫn reset HomeCubit và state ngay cả khi có lỗi
      HomeStateService.reset();
      emit(const UserState());
    }
  }

  /// Navigate to order status screen
  void navigateToOrders(String status) {
    // Navigation will be handled by screen
    // status can be: pending, processing, shipping, completed
  }

  /// Navigate to settings
  void navigateToSettings() {
    // Navigation will be handled by screen
  }

  /// Navigate to edit profile
  void navigateToEditProfile() {
    // Navigation will be handled by screen
  }

  /// Navigate to cart
  void navigateToCart() {
    // Navigation will be handled by screen
  }

  /// Change bottom navigation index
  void changeBottomNavIndex(int index) {
    emit(state.copyWith(selectedBottomNavIndex: index));
  }
}
