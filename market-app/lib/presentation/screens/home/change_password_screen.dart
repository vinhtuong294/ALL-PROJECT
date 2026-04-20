import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_app/core/constants/app_colors.dart';
import 'package:market_app/presentation/widgets/common/market_app_bar.dart';
import 'package:market_app/presentation/widgets/common/market_bottom_nav_bar.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
import '../../../injection_container.dart';

class ChangePasswordScreen extends StatefulWidget {
  final MarketNavItem currentNav;
  final ValueChanged<MarketNavItem> onNavTap;

  const ChangePasswordScreen({
    super.key,
    required this.currentNav,
    required this.onNavTap,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Password requirements state
  bool _hasMinLength = false;
  bool _hasCaps = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final value = _newPasswordController.text;
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasCaps = value.contains(RegExp(r'[A-Z]')) && value.contains(RegExp(r'[a-z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecial = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  bool get _isPasswordValid => _hasMinLength && _hasCaps && _hasNumber && _hasSpecial;

  void _onSubmit(BuildContext context) {
    final oldPwd = _currentPasswordController.text.trim();
    final newPwd = _newPasswordController.text.trim();
    final confirmPwd = _confirmPasswordController.text.trim();

    if (oldPwd.isEmpty || newPwd.isEmpty || confirmPwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu mới không đáp ứng yêu cầu'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (newPwd != confirmPwd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mật khẩu xác nhận không khớp'), backgroundColor: Colors.red),
      );
      return;
    }

    context.read<ProfileBloc>().add(ChangePasswordEvent(
      oldPassword: oldPwd,
      newPassword: newPwd,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProfileBloc>(),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is PasswordChangeSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            // Clear fields on success
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
          }
          if (state is PasswordChangeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: const MarketAppBar(
              title: 'Thay Đổi Mật Khẩu',
              showBack: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormCard(),
                  const SizedBox(height: 20),
                  _buildRequirementsCard(),
                  const SizedBox(height: 20),
                  _buildWarningBox(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
                  ),
                  child: _buildSubmitButton(context, state),
                ),
                MarketBottomNavBar(
                  currentItem: widget.currentNav,
                  onTap: widget.onNavTap,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputLabel('Mật khẩu hiện tại *'),
          _buildPasswordField(
            hint: '••••••••',
            obscure: _obscureCurrent,
            controller: _currentPasswordController,
            onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
          ),
          const SizedBox(height: 20),
          _buildInputLabel('Mật khẩu mới *'),
          _buildPasswordField(
            hint: '••••••••',
            obscure: _obscureNew,
            controller: _newPasswordController,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
          ),
          const SizedBox(height: 20),
          _buildInputLabel('Xác nhận mật khẩu mới *'),
          _buildPasswordField(
            hint: '••••••••',
            obscure: _obscureConfirm,
            controller: _confirmPasswordController,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    TextEditingController? controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint, letterSpacing: 2),
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4CAF50), size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.textHint,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRequirementsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yêu cầu mật khẩu',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildRequirementItem('Ít nhất 8 ký tự', _hasMinLength),
          _buildRequirementItem('Có chữ hoa và chữ thường', _hasCaps),
          _buildRequirementItem('Có ít nhất 1 chữ số', _hasNumber),
          _buildRequirementItem('Có ký tự đặc biệt (@, #, \$, !...)', _hasSpecial),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    final bool isNotEmpty = _newPasswordController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            !isNotEmpty
                ? Icons.circle_outlined
                : (isMet ? Icons.check_circle : Icons.cancel),
            size: 20,
            color: !isNotEmpty
                ? AppColors.textHint.withValues(alpha: 0.5)
                : (isMet ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: !isNotEmpty
                    ? AppColors.textSecondary
                    : (isMet ? const Color(0xFF4CAF50) : AppColors.textSecondary),
                fontWeight: (isNotEmpty && isMet) ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFEBB3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA000), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sử dụng mật khẩu mạnh để bảo vệ tài khoản của bạn. Không chia sẻ mật khẩu với bất kỳ ai.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF856404),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, ProfileState state) {
    final isLoading = state is ProfileLoading;
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43A047).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _onSubmit(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                'Đổi Mật Khẩu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
      ),
    );
  }
}
