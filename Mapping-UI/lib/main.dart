import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/config/app_config.dart';
import 'core/dependency/injection.dart';
import 'core/router/app_router.dart';
import 'core/router/navigation_observer.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'core/services/navigation_state_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize dependencies
  await initDependencies();

  // Get initial route
  final navigationService = getIt<NavigationStateService>();
  final initialRoute = navigationService.getInitialRoute();

  // Log app startup
  AppLogger.info('Starting ${AppConfig.appName}...');
  AppLogger.info('Environment: ${AppConfig.environment}');
  AppLogger.info('Base URL: ${AppConfig.baseUrl}');
  AppLogger.info('Initial Route: $initialRoute');

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({
    super.key,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      
      // Navigation
      navigatorKey: AppRouter.navigatorKey,
      
      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      
      // Routing
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
      navigatorObservers: [AppNavigationObserver()],
      
      // Builder for error handling
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
