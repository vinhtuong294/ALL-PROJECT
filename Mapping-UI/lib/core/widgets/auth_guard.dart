import 'package:flutter/material.dart';
import '../services/auth/auth_service.dart';
import '../config/route_name.dart';
import '../dependency/injection.dart';

/// Widget wrapper để kiểm tra authentication và tự động logout khi hết phiên
class AuthGuard extends StatefulWidget {
  final Widget child;
  final bool checkOnInit;
  
  const AuthGuard({
    super.key,
    required this.child,
    this.checkOnInit = true,
  });

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> with WidgetsBindingObserver {
  final AuthService _authService = getIt<AuthService>();
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    if (widget.checkOnInit) {
      _checkAuthentication();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kiểm tra khi app quay lại foreground
    if (state == AppLifecycleState.resumed) {
      _checkAuthentication();
    }
  }

  /// Kiểm tra authentication và xử lý khi hết phiên
  Future<void> _checkAuthentication() async {
    if (_isChecking) return;
    
    setState(() {
      _isChecking = true;
    });

    try {
      final isExpired = await _authService.checkAndHandleTokenExpiration();
      
      if (isExpired && mounted) {
        // Token đã hết hạn, chuyển về login
        _navigateToLogin();
      }
    } catch (e) {
      // Nếu có lỗi, cũng chuyển về login để an toàn
      if (mounted) {
        _navigateToLogin();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  /// Chuyển về màn hình login
  void _navigateToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteName.login,
      (route) => false,
    );
    
    // Hiển thị thông báo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
