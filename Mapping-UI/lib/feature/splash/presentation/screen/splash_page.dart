import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/route_name.dart';
import '../../../../core/router/app_router.dart';
import '../cubit/splash_cubit.dart';

/// Màn hình Splash - Màn hình đầu tiên khi mở ứng dụng
/// 
/// Chức năng:
/// - Hiển thị logo và branding của ứng dụng
/// - Thực hiện các tác vụ khởi tạo ban đầu
/// - Điều hướng đến màn hình phù hợp dựa trên trạng thái người dùng
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  static const String routeName = '/splash';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashCubit()..initialize(),
      child: const SplashView(),
    );
  }
}

/// View của màn hình Splash
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        debugPrint('[SPLASH_PAGE] 📥 State received: ${state.runtimeType}');
        if (state is SplashAuthenticated) {
          // User đã đăng nhập -> Navigate theo vai trò
          debugPrint('[SPLASH_PAGE] ✅ SplashAuthenticated - role: ${state.role}');
          _navigateByRole(context, state.role);
        } else if (state is SplashUnauthenticated) {
          // User chưa đăng nhập -> Navigate to Login screen
          debugPrint('[SPLASH_PAGE] 🔒 SplashUnauthenticated - navigating to login');
          _navigateToLogin(context);
        } else if (state is SplashError) {
          // Show error dialog
          debugPrint('[SPLASH_PAGE] ❌ SplashError: ${state.message}');
          _showErrorDialog(context, state.message);
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/img/splash_background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Status bar space
                const SizedBox(height: 40),
                
                // Spacer to push logo up (smaller flex)
                const Spacer(flex: 1),
                
                // Logo
                _buildLogo(),
                
                // Spacer to balance layout (larger flex to push logo up)
                const Spacer(flex: 10),
                
                // Loading indicator
                _buildLoadingIndicator(),
                
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build logo widget với animation
  Widget _buildLogo() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 206,
        height: 91,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/img/splash_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator() {
    return BlocBuilder<SplashCubit, SplashState>(
      builder: (context, state) {
        if (state is SplashLoading) {
          return Column(
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B40F)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Đang tải...',
                style: TextStyle(
                  color: const Color(0xFF00B40F).withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Navigate to Login screen
  void _navigateToLogin(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (context.mounted) {
        AppRouter.navigateAndRemoveUntil(
          context,
          RouteName.login,
        );
      }
    });
  }

  /// Navigate theo vai trò người dùng
  void _navigateByRole(BuildContext context, String role) {
    debugPrint('[SPLASH_PAGE] 🎯 _navigateByRole called with role: $role');
    Future.delayed(const Duration(milliseconds: 300), () {
      if (context.mounted) {
        if (role == 'quan_ly_cho') {
          // Quản lý chợ -> Admin Home
          debugPrint('[SPLASH_PAGE] ➡️ Navigating to ADMIN home (RouteName.adminHome)');
          AppRouter.navigateAndRemoveUntil(
            context,
            RouteName.adminHome,
          );
        } else if (role == 'nguoi_ban') {
          // Người bán -> Seller Home
          debugPrint('[SPLASH_PAGE] ➡️ Navigating to SELLER home (RouteName.sellerMain)');
          AppRouter.navigateAndRemoveUntil(
            context,
            RouteName.sellerMain,
          );
        } else if (role == 'nguoi_mua') {
          // Người mua -> Buyer Home
          debugPrint('[SPLASH_PAGE] ➡️ Navigating to BUYER home (RouteName.main)');
          AppRouter.navigateAndRemoveUntil(
            context,
            RouteName.main,
          );
        } else {
          // Vai trò không xác định -> Login
          debugPrint('[SPLASH_PAGE] ⚠️ Unknown role: $role, navigating to login');
          _navigateToLogin(context);
        }
      }
    });
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Retry initialization
              context.read<SplashCubit>().initialize();
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

}
