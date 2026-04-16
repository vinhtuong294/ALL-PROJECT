import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config/app_config.dart';
import 'core/dependency/injection.dart';
import 'core/router/app_router.dart';
import 'core/router/navigation_observer.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'core/services/navigation_state_service.dart';
import 'core/utils/device_preview_screen.dart';

/// Entry point cho Device Preview Mode
/// Chạy với: flutter run -t lib/main_device_preview.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initDependencies();

  final navigationService = getIt<NavigationStateService>();
  final initialRoute = navigationService.getInitialRoute();

  AppLogger.info('Starting Device Preview Mode...');
  AppLogger.info('Environment: ${AppConfig.environment}');

  runApp(DevicePreviewApp(initialRoute: initialRoute));
}

class DevicePreviewApp extends StatelessWidget {
  final String initialRoute;

  const DevicePreviewApp({
    super.key,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Device Preview - ${AppConfig.appName}',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00B40F),
          secondary: const Color(0xFF00B40F),
        ),
      ),
      home: DevicePreviewScreen(
        child: MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          initialRoute: initialRoute,
          onGenerateRoute: AppRouter.onGenerateRoute,
          navigatorObservers: [AppNavigationObserver()],
        ),
      ),
    );
  }
}
