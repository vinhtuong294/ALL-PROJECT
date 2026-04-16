import 'package:shared_preferences/shared_preferences.dart';
import '../config/route_name.dart';

/// Service để lưu và khôi phục trạng thái navigation
class NavigationStateService {
  static const String _keyLastRoute = 'last_route';
  static const String _keyIsFirstLaunch = 'is_first_launch';
  
  final SharedPreferences _prefs;

  NavigationStateService(this._prefs);

  /// Lưu route hiện tại
  Future<void> saveCurrentRoute(String route) async {
    await _prefs.setString(_keyLastRoute, route);
  }

  /// Lấy route đã lưu
  String? getSavedRoute() {
    return _prefs.getString(_keyLastRoute);
  }

  /// Xóa route đã lưu
  Future<void> clearSavedRoute() async {
    await _prefs.remove(_keyLastRoute);
  }

  /// Kiểm tra có phải lần đầu mở app không
  bool isFirstLaunch() {
    return _prefs.getBool(_keyIsFirstLaunch) ?? true;
  }

  /// Đánh dấu đã mở app lần đầu
  Future<void> markFirstLaunchComplete() async {
    await _prefs.setBool(_keyIsFirstLaunch, false);
  }

  /// Lấy initial route dựa trên trạng thái
  String getInitialRoute() {
    // Luôn hiển thị splash khi khởi động app
    return RouteName.splash;
  }

  /// Kiểm tra có phải route chính không
  bool _isMainRoute(String route) {
    final mainRoutes = [
      RouteName.main,
      RouteName.home,
      RouteName.productList,
      RouteName.ingredient,
      RouteName.user,
    ];
    return mainRoutes.contains(route);
  }

  /// Reset về trạng thái ban đầu (khi logout)
  Future<void> reset() async {
    await clearSavedRoute();
    await _prefs.setBool(_keyIsFirstLaunch, true);
  }
}
