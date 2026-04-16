import 'package:flutter/material.dart';
import '../services/navigation_state_service.dart';
import '../dependency/injection.dart';
import '../utils/app_logger.dart';

/// Observer để theo dõi và lưu trạng thái navigation
class AppNavigationObserver extends NavigatorObserver {
  final NavigationStateService _navigationService = getIt<NavigationStateService>();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _saveRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _saveRoute(newRoute);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _saveRoute(previousRoute);
    }
  }

  void _saveRoute(Route<dynamic> route) {
    final routeName = route.settings.name;
    if (routeName != null && routeName.isNotEmpty) {
      _navigationService.saveCurrentRoute(routeName);
      AppLogger.info('📍 Saved route: $routeName');
      
      // Đánh dấu đã mở app lần đầu
      if (_navigationService.isFirstLaunch()) {
        _navigationService.markFirstLaunchComplete();
      }
    }
  }
}
