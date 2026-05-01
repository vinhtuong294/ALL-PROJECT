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

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => AccountTabState();
}

class AccountTabState extends State<AccountTab> {
  void refreshData() => _loadData();
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
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([ApiService.getMe(), ApiService.getShipperMe()]);
      int wallet = 0;
      try {
        final w = await ApiService.getWalletBalance();
        wallet = w['so_du_kha_dung'] ?? w['so_du'] ?? 0;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _user = results[0];
          _shipper = results[1]['shipper'];
          _walletBalance = wallet;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.w700)),
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B40F)))
          : RefreshIndicator(
              color: const Color(0xFF00B40F),
              onRefresh: _loadData,
              child: ListView(
                children: [
                  // ── Compact top bar ──
                  Container(
                    color: Colors.white,
                    padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 16),
                    child: const Text('Tài khoản', style: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Profile card ──
                        _buildProfileCard(),
                        const SizedBox(height: 16),

                        // ── Wallet card ──
                        _buildWalletCard(context),
                        const SizedBox(height: 24),

                        // ── Vehicle ──
                        const _SectionTitle(title: 'Phương tiện'),
                        const SizedBox(height: 10),
                        _buildVehicleCard(context),
                        const SizedBox(height: 24),

                        // ── Tiện ích ──
                        const _SectionTitle(title: 'Tiện ích'),
                        const SizedBox(height: 10),
                        _MenuCard(items: [
                          _MenuItem(icon: Icons.star_outline_rounded, color: const Color(0xFFF59E0B), label: 'Đánh giá của tôi', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsPage()))),
                          _MenuItem(icon: Icons.notifications_outlined, color: const Color(0xFF8B5CF6), label: 'Thông báo', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()))),
                          _MenuItem(icon: Icons.credit_card_outlined, color: const Color(0xFF0EA5E9), label: 'Tài khoản ngân hàng', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BankInfoPage(bankAccount: _user?['bank_account'], bankName: _user?['bank_name']))).then((_) => _loadData())),
                        ]),
                        const SizedBox(height: 16),

                        // ── Bảo mật ──
                        const _SectionTitle(title: 'Bảo mật'),
                        const SizedBox(height: 10),
                        _MenuCard(items: [
                          _MenuItem(icon: Icons.lock_outline_rounded, color: const Color(0xFF64748B), label: 'Thay đổi mật khẩu', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordPage()))),
                          _MenuItem(icon: Icons.history_rounded, color: const Color(0xFF64748B), label: 'Lịch sử đăng nhập', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginHistoryPage()))),
                        ]),
                        const SizedBox(height: 16),

                        // ── Đăng xuất ──
                        _MenuCard(items: [
                          _MenuItem(icon: Icons.logout_rounded, color: const Color(0xFFEF4444), label: 'Đăng xuất', onTap: _logout),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    final name = _user?['user_name'] ?? 'Tài xế';
    final phone = _user?['phone'] ?? '';
    final maShipper = _shipper?['ma_shipper'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded, color: Color(0xFF00B40F), size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(phone, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
                if (maShipper.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('ID: $maShipper', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00B40F))),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage())).then((_) => _loadData()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00B40F), Color(0xFF34C759)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF00B40F).withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ví thu nhập', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(formatVND(_walletBalance), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context) {
    final vehicleType = _shipper?['phuong_tien'] ?? 'Chưa cập nhật';
    final plate = _shipper?['bien_so_xe'] ?? 'Chưa cập nhật';
    return _MenuCard(items: [
      _MenuItem(
        icon: Icons.two_wheeler_rounded,
        color: const Color(0xFF00B40F),
        label: vehicleType,
        subtitle: 'Biển số: $plate',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditVehiclePage(vehicleType: _shipper?['phuong_tien'], vehiclePlate: _shipper?['bien_so_xe']))).then((_) => _loadData()),
        trailing: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF94A3B8)),
      ),
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5));
  }
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return Column(children: [
            entry.value,
            if (!isLast) const Divider(height: 1, indent: 54, endIndent: 16),
          ]);
        }).toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _MenuItem({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
