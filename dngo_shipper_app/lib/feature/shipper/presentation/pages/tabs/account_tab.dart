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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Tài khoản', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : RefreshIndicator(
              color: const Color(0xFF4CAF50),
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  // Profile Section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Color(0xFF4CAF50),
                          child: Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_user?['user_name'] ?? 'Tài xế', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                              const SizedBox(height: 4),
                              Text(_user?['phone'] ?? 'Chưa cập nhật SĐT', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                                child: Text('Mã: ${_shipper?['ma_shipper'] ?? 'N/A'}', style: TextStyle(color: Colors.green.shade800, fontSize: 12, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wallet Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage())).then((_) => _loadData()),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Ví thu nhập', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text(formatVND(_walletBalance), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Vehicle info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text('Phương tiện giao hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditVehiclePage(vehicleType: _shipper?['phuong_tien'], vehiclePlate: _shipper?['bien_so_xe']))).then((_) => _loadData()),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.two_wheeler, color: Color(0xFF4CAF50)),
                                const SizedBox(width: 8),
                                const Expanded(child: Text('Thông tin xe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                                Icon(Icons.edit_outlined, size: 20, color: Colors.grey.shade500),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                            _infoItem('Loại xe', _shipper?['phuong_tien'] ?? 'Chưa cập nhật'),
                            _infoItem('Biển số', _shipper?['bien_so_xe'] ?? 'Chưa cập nhật'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // General Settings
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text('Tiện ích & Cài đặt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _menuCard([
                      _menuItem(Icons.verified_user_outlined, 'Xác thực eKYC', color: Colors.blue.shade700, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EkycRegistrationPage()))),
                      _menuItem(Icons.star_outline, 'Đánh giá của tôi', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsPage()))),
                      _menuItem(Icons.notifications_outlined, 'Thông báo', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()))),
                      _menuItem(Icons.credit_card_outlined, 'Tài khoản ngân hàng', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BankInfoPage(bankAccount: _user?['bank_account'], bankName: _user?['bank_name']))).then((_) => _loadData())),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  
                  // Security Settings
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _menuCard([
                      _menuItem(Icons.lock_outline, 'Thay đổi mật khẩu', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()))),
                      _menuItem(Icons.history, 'Lịch sử đăng nhập', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginHistoryPage()))),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Logout
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _menuCard([
                      _menuItem(Icons.logout, 'Đăng xuất', color: Colors.red, onTap: _logout),
                    ]),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _infoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _menuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast) const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, {Color color = Colors.black87, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 15)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
