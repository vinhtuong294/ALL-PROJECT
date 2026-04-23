import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../feature/shipper/presentation/pages/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _vehiclePlateCtrl = TextEditingController();
  final _vehicleTypeCtrl = TextEditingController();

  String _gender = 'M'; // M, F, O
  bool _loading = false;
  String? _error;
  bool _obscure = true;

  Future<void> _onRegister() async {
    if (_usernameCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _fullNameCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _addressCtrl.text.isEmpty) {
      setState(() => _error = 'Vui lòng nhập đầy đủ thông tin bắt buộc');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payload = {
        "ten_dang_nhap": _usernameCtrl.text.trim(),
        "mat_khau": _passwordCtrl.text,
        "ten_nguoi_dung": _fullNameCtrl.text.trim(),
        "role": "shipper",
        "gioi_tinh": _gender,
        "sdt": _phoneCtrl.text.trim(),
        "dia_chi": _addressCtrl.text.trim(),
        "bien_so_xe": _vehiclePlateCtrl.text.trim(),
        "phuong_tien": _vehicleTypeCtrl.text.trim(),
      };

      await ApiService.register(payload);
      // Lấy thêm thông tin sau khi đăng ký (ví)
      await ApiService.getMe();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
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
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _vehiclePlateCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    super.dispose();
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false, TextInputType type = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscure,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45, fontSize: 15),
          prefixIcon: Icon(icon, size: 22, color: Colors.black45),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20, color: Colors.black45),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: Column(
                  children: [
                    Image.asset('assets/img/logo.png', height: 80),
                    const SizedBox(height: 8),
                    const Text(
                      'ĐĂNG KÝ TÀI XẾ',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Tạo tài khoản',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Điền đầy đủ thông tin để trở thành đối tác giao hàng.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 32),

              // Form fields
              _buildTextField(_usernameCtrl, 'Tên đăng nhập *', Icons.person_outline),
              _buildTextField(_passwordCtrl, 'Mật khẩu *', Icons.lock_outline, isPassword: true),
              _buildTextField(_fullNameCtrl, 'Họ và tên *', Icons.badge_outlined),

              // Gender Selection
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wc, size: 22, color: Colors.black45),
                    const SizedBox(width: 12),
                    const Text('Giới tính:', style: TextStyle(color: Colors.black45, fontSize: 15)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _gender,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black45),
                          items: const [
                            DropdownMenuItem(value: 'M', child: Text('Nam', style: TextStyle(fontSize: 15))),
                            DropdownMenuItem(value: 'F', child: Text('Nữ', style: TextStyle(fontSize: 15))),
                            DropdownMenuItem(value: 'O', child: Text('Khác', style: TextStyle(fontSize: 15))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _gender = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _buildTextField(_phoneCtrl, 'Số điện thoại *', Icons.phone_outlined, type: TextInputType.phone),
              _buildTextField(_addressCtrl, 'Địa chỉ *', Icons.home_outlined),
              _buildTextField(_vehiclePlateCtrl, 'Biển số xe', Icons.pin_outlined),
              _buildTextField(_vehicleTypeCtrl, 'Loại xe (vd: Honda Wave)', Icons.motorcycle_outlined),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14))),
                  ],
                ),
              ],
              const SizedBox(height: 32),

              // Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Hoàn tất đăng ký', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
