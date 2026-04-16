import 'package:flutter/material.dart';
import '../../../../../core/services/api_service.dart';

import '../../../../../core/utils/helpers.dart';
import '../../../../../feature/auth/presentation/pages/login_screen.dart';
import '../bank_info_page.dart';
import '../change_password_page.dart';
import '../login_history_page.dart';
import '../cod_management_page.dart';
import '../reviews_page.dart';
import '../notifications_page.dart';
import '../edit_vehicle_page.dart';
import '../wallet_page.dart';
import '../ekyc_registration_page.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _shipper;
  int _walletBalance = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getMe(),
        ApiService.getShipperMe(),
      ]);
      int wallet = 0;
      try {
        final w = await ApiService.getWalletBalance();
        wallet = w['so_du'] ?? 0;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _user = results[0];
          _shipper = results[1]['shipper'];
          _walletBalance = wallet;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ApiService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2F8000)))
              : RefreshIndicator(
                  color: const Color(0xFF2F8000),
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Profile card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
                        child: Column(children: [
                          const CircleAvatar(radius: 40, backgroundColor: Color(0xFF2F8000), child: Icon(Icons.person, size: 40, color: Colors.white)),
                          const SizedBox(height: 12),
                          Text(_user?['user_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(_user?['phone'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Text('Shipper: ${_shipper?['ma_shipper'] ?? ''}', style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 16),

                      // Vehicle info
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditVehiclePage(vehicleType: _shipper?['phuong_tien'], vehiclePlate: _shipper?['bien_so_xe']))).then((_) => _loadData()),
                        child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.two_wheeler, color: Color(0xFF2F8000)),
                            const SizedBox(width: 8),
                            const Text('Phương tiện', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            Icon(Icons.edit, size: 18, color: Colors.grey.shade400),
                          ]),
                          const Divider(height: 24),
                          _infoItem('Loại xe', _shipper?['phuong_tien'] ?? 'N/A'),
                          _infoItem('Biển số', _shipper?['bien_so_xe'] ?? 'N/A'),
                        ]),
                      )),
                      const SizedBox(height: 16),

                      // Wallet
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage())).then((_) => _loadData()),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFF2F8000), borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Ví shipper', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              Text(formatVND(_walletBalance), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                            ])),
                            const Icon(Icons.chevron_right, color: Colors.white),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Menu items
                      _menuCard([
                        _menuItem(Icons.verified_user_outlined, 'Xác thực eKYC', color: Colors.blue.shade700, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EkycRegistrationPage()))),
                        _menuItem(Icons.star_outline, 'Đánh giá của tôi', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsPage()))),
                        _menuItem(Icons.notifications_outlined, 'Thông báo', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()))),
                        _menuItem(Icons.credit_card, 'Thông tin ngân hàng', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BankInfoPage(bankAccount: _user?['bank_account'], bankName: _user?['bank_name']))).then((_) => _loadData())),
                      ]),
                      const SizedBox(height: 16),
                      _menuCard([
                        _menuItem(Icons.lock_outline, 'Thay đổi mật khẩu', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()))),
                        _menuItem(Icons.history, 'Lịch sử đăng nhập', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginHistoryPage()))),
                      ]),
                      const SizedBox(height: 16),
                      _menuCard([
                        _menuItem(Icons.logout, 'Đăng xuất', color: Colors.red, onTap: _logout),
                      ]),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 16, right: 16, bottom: 12),
      color: const Color(0xFF2F8000),
      child: const Text('Tài khoản', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(children: children),
    );
  }

  Widget _menuItem(IconData icon, String title, {Color color = Colors.black87, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
