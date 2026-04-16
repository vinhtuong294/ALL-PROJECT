import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../feature/shipper/presentation/pages/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  Future<void> _onLogin() async {
    if (_usernameCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ thông tin');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
      // After login, fetch full profile to get wallet_id etc.
      await ApiService.getMe();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network('https://cdn-icons-png.flaticon.com/512/3753/3753061.png', height: 48, color: const Color(0xFF2F8000),
                        errorBuilder: (c, e, s) => const Icon(Icons.shopping_cart, size: 48, color: Color(0xFF2F8000)),
                      ),
                      const SizedBox(width: 8),
                      const Text('DNGo', style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 60),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.lightBlue.shade100, width: 1.5),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(children: [
                                  const Text('Đăng nhập', style: TextStyle(color: Color(0xFF2F8000), fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Container(width: 40, height: 2, color: Colors.red),
                                ]),
                                const Text('Đăng ký', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.lightBlue.shade200)),
                              child: TextField(
                                controller: _usernameCtrl,
                                decoration: const InputDecoration(hintText: 'Tên đăng nhập', hintStyle: TextStyle(color: Colors.black54, fontSize: 14), prefixIcon: Icon(Icons.person_outline, size: 18, color: Colors.black54), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.lightBlue.shade200)),
                              child: TextField(
                                controller: _passwordCtrl,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  hintText: 'Mật khẩu', hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
                                  prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.black54),
                                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.black54), onPressed: () => setState(() => _obscure = !_obscure)),
                                  border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 12),
                              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                            ],
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity, height: 48,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _onLogin,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1CB02A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), elevation: 0),
                                child: _loading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Đăng nhập', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Bạn mới biết đến DNGo? ', style: TextStyle(color: Colors.black87, fontSize: 12)),
                                GestureDetector(onTap: () {}, child: const Text('Đăng ký', style: TextStyle(color: Color(0xFF2F8000), fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
