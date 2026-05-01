import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_app/core/constants/app_colors.dart';
import 'package:market_app/presentation/widgets/common/market_app_bar.dart';
import 'package:market_app/presentation/widgets/common/market_bottom_nav_bar.dart';
import 'change_password_screen.dart';
import 'login_history_screen.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../../injection_container.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../core/utils/jwt_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountScreen extends StatefulWidget {
  final MarketNavItem currentNav;
  final ValueChanged<MarketNavItem> onNavTap;

  const AccountScreen({
    super.key,
    required this.currentNav,
    required this.onNavTap,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankNameController;
  UserProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _bankAccountController = TextEditingController();
    _bankNameController = TextEditingController();

    // Pre-populate from token if available
    final prefs = sl<SharedPreferences>();
    final token = prefs.getString('access_token');
    if (token != null && token.isNotEmpty) {
      final payload = JwtUtils.decode(token);
      if (payload != null) {
        final userName = payload['user_name'] as String?;
        final role = payload['role'] as String?;
        final userId = payload['user_id'] as String? ?? payload['sub'] as String?;
        
        if (userName != null) _nameController.text = userName;
        
        // Create a temporary profile object to show basic info immediately
        _profile = UserProfileModel(
          userId: userId ?? '',
          loginName: payload['login_name'] as String? ?? '',
          userName: userName ?? '',
          role: role ?? '',
          gender: '',
          phone: '',
          address: '',
          approvalStatus: 0,
          marketName: null,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProfileBloc>()..add(GetUserProfileEvent()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSuccess) {
            _profile = state.profile;
            _nameController.text = state.profile.userName;
            _phoneController.text = state.profile.phone;
            _addressController.text = state.profile.address;
            _bankAccountController.text = state.profile.bankAccount ?? '';
            _bankNameController.text = state.profile.bankName ?? '';
          }
          if (state is ProfileUpdateSuccess) {
            _profile = state.profile;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          }
          if (state is ProfileError) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: const MarketAppBar(
              title: 'Quản Lý Thông Tin',
              showBack: true,
            ),
            body: (state is ProfileLoading && _profile == null)
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Thông tin tài khoản'),
                        _buildAccountInfoCard(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Thông tin cá nhân'),
                        _buildPersonalInfoForm(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Thông tin công việc'),
                        _buildWorkInfoCard(),
                        const SizedBox(height: 20),
                        _buildSectionHeader('Cài đặt nhanh'),
                        _buildQuickSettingsCard(),
                        const SizedBox(height: 20),
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
                  child: _buildFooterButtons(context, state),
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

  Widget _buildProfileHeader() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_circle, size: 80, color: Colors.white),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF4CAF50)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow('Tên hồ sơ', _profile?.userName ?? '--'),
          const Divider(height: 24),
          _buildInfoRow('Chợ', _profile?.marketName ?? 'Chưa gán chợ'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _buildPersonalInfoForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Tên hiển thị'),
          _isEditing ? _buildTextField(_nameController) : _buildField(_profile?.userName ?? ''),
          const SizedBox(height: 16),
          _buildLabel('Số điện thoại'),
          _isEditing ? _buildTextField(_phoneController, keyboardType: TextInputType.phone) : _buildField(_profile?.phone ?? ''),
          const SizedBox(height: 16),
          _buildLabel('Địa chỉ'),
          _isEditing ? _buildTextField(_addressController) : _buildField(_profile?.address ?? ''),
           const SizedBox(height: 16),
          _buildLabel('Số tài khoản'),
          _isEditing ? _buildTextField(_bankAccountController) : _buildField(_profile?.bankAccount ?? ''),
           const SizedBox(height: 16),
          _buildLabel('Ngân hàng'),
          _isEditing ? _buildTextField(_bankNameController) : _buildField(_profile?.bankName ?? ''),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, {TextInputType? keyboardType}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildWorkInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mã nhân viên', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(
                _profile?.userId ?? '--',
                style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Vai trò', _profile?.role == 'quan_ly_cho' ? 'Quản lý chợ' : _profile?.role ?? '--'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quyền hạn', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Quản lý cao',
                  style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            Icons.lock_outline,
            'Thay đổi mật khẩu',
            showArrow: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangePasswordScreen(
                    currentNav: widget.currentNav,
                    onNavTap: widget.onNavTap,
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1),
          ),
          _buildSettingItem(
            Icons.history,
            'Lịch sử đăng nhập',
            showArrow: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginHistoryScreen(
                    currentNav: widget.currentNav,
                    onNavTap: widget.onNavTap,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, {bool showArrow = false, Widget? trailing, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF4CAF50)),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: trailing ?? (showArrow ? const Icon(Icons.chevron_right, color: AppColors.iconGrey) : null),
      onTap: onTap,
    );
  }

  Widget _buildFooterButtons(BuildContext context, ProfileState state) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: (state is ProfileLoading) ? null : () {
              setState(() {
                if (_isEditing) {
                  _isEditing = false;
                   context.read<ProfileBloc>().add(UpdateUserProfileEvent({
                    'ten_nguoi_dung': _nameController.text,
                    'sdt': _phoneController.text,
                    'dia_chi': _addressController.text,
                    'so_tai_khoan': _bankAccountController.text,
                    'ngan_hang': _bankNameController.text,
                  }));
                } else {
                  _isEditing = true;
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: (state is ProfileLoading && _isEditing == false)
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                  _isEditing ? 'Lưu thay đổi' : 'Cập nhật thông tin',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: TextButton.icon(
            onPressed: () {
              context.read<AuthBloc>().add(LoggedOut());
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
              foregroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Đăng xuất', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
