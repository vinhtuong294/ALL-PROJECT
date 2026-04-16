import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/auth_storage.dart';
import '../../../../core/services/api_service.dart';
import '../../../../feature/shipper/presentation/pages/main_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final token = await AuthStorage.getToken();
    Widget target;

    if (token != null) {
      try {
        await ApiService.getMe(); // validate token + refresh user data
        target = const MainScreen();
      } catch (_) {
        await AuthStorage.clear();
        target = const LoginScreen();
      }
    } else {
      target = const LoginScreen();
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (c, a, s) => target,
          transitionsBuilder: (c, a, s, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            left: 0, right: 0, bottom: -50,
            child: Opacity(
              opacity: 0.9,
              child: Image.network(
                'https://t3.ftcdn.net/jpg/04/47/98/69/360_F_447986940_l6TngbSOT1q8Ips4Ggq3q3PqOa8XZ0N5.jpg',
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height * 0.6,
                errorBuilder: (c, e, s) => Container(height: MediaQuery.of(context).size.height * 0.6, color: Colors.white),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.white.withValues(alpha: 0.6), Colors.transparent],
                  stops: const [0.4, 0.6, 1.0],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network('https://cdn-icons-png.flaticon.com/512/3753/3753061.png', height: 50, color: const Color(0xFF2F8000),
                  errorBuilder: (c, e, s) => const Icon(Icons.shopping_cart, size: 50, color: Color(0xFF2F8000)),
                ),
                const SizedBox(width: 8),
                const Text('DNGo', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ],
            ),
          ),
          const Align(
            alignment: Alignment(0, 0.3),
            child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2F8000))),
          ),
        ],
      ),
    );
  }
}
