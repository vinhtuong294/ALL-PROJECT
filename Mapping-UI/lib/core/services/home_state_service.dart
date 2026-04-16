import '../../feature/buyer/home/presentation/cubit/home_cubit.dart';

/// Service để quản lý global state của Home
/// Giữ HomeCubit sống suốt phiên đăng nhập
class HomeStateService {
  static HomeCubit? _homeCubit;

  /// Lấy hoặc tạo HomeCubit instance
  static HomeCubit getOrCreateHomeCubit() {
    _homeCubit ??= HomeCubit()..initializeHome();
    return _homeCubit!;
  }

  /// Lấy HomeCubit hiện tại (nếu có)
  static HomeCubit? getHomeCubit() {
    return _homeCubit;
  }

  /// Reset HomeCubit (khi logout)
  static void reset() {
    _homeCubit?.close();
    _homeCubit = null;
  }

  /// Kiểm tra xem HomeCubit đã được khởi tạo chưa
  static bool isInitialized() {
    return _homeCubit != null;
  }
}
