import 'package:flutter/material.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/utils/helpers.dart';
import '../main_screen.dart';
import '../delivery_route_page.dart';
import '../cod_management_page.dart';
import '../notifications_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _dashboard;
  int _walletBalance = 0;
  bool _loading = true;
  bool _isOnline = false; // Add state

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getMe(),
        ApiService.getDashboard(),
      ]);
      int wallet = 0;
      try {
        final w = await ApiService.getWalletBalance();
        wallet = w['so_du'] ?? 0;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _user = results[0];
          _dashboard = results[1];
          _walletBalance = wallet;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchTab(int index) {
    final mainState = context.findAncestorStateOfType<MainScreenState>();
    mainState?.switchToTab(index);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                : RefreshIndicator(
                    color: const Color(0xFF4CAF50),
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Text('Thống kê thu nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        _buildStatsGrid(),
                        const SizedBox(height: 32),
                        const Text('Thao tác nhanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        _buildActionCard(Icons.inventory_2_outlined, Colors.green, 'Nhận đơn hàng mới', onTap: () => _switchTab(1)),
                        const SizedBox(height: 12),
                        _buildActionCard(Icons.map_outlined, Colors.blue, 'Bản đồ khu vực chợ', onTap: () => _switchTab(2)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final name = _user?['user_name'] ?? 'Shipper';
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, left: 24, right: 24, bottom: 28),
      decoration: const BoxDecoration(
        color: Color(0xFF4CAF50),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_getGreeting(), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                const SizedBox(height: 2),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
              child: const Icon(Icons.notifications_none, color: Color(0xFF4CAF50)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOnlineToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _isOnline ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isOnline ? const Color(0xFF2F8000) : Colors.grey.shade300, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(shape: BoxShape.circle, color: _isOnline ? const Color(0xFF2F8000) : Colors.grey.shade400),
                child: Icon(_isOnline ? Icons.electric_bike : Icons.pedal_bike, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isOnline ? 'Đang nhận đơn' : 'Ngoại tuyến', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _isOnline ? const Color(0xFF2F8000) : Colors.grey.shade800)),
                  const SizedBox(height: 2),
                  Text(_isOnline ? 'Hệ thống đang tìm đơn cho bạn' : 'Bật để bắt đầu chạy xe', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
          Switch(
            value: _isOnline,
            activeColor: const Color(0xFF2F8000),
            inactiveThumbColor: Colors.grey.shade400,
            onChanged: (val) {
              setState(() => _isOnline = val);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? 'Đã bật nhận đơn tự động' : 'Đã tắt nhận đơn. Nghỉ ngơi nhé!', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: val ? const Color(0xFF2F8000) : Colors.orange.shade800, duration: const Duration(seconds: 2)));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildGridStat(Icons.payments, Colors.orange.shade700, 'Thu nhập (Hôm nay)', formatVND(_dashboard?['hom_nay']?['thu_nhap'] ?? 0), onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CODManagementPage())).then((_) => _loadData());
        }),
        _buildGridStat(Icons.account_balance_wallet, const Color(0xFF2F8000), 'Giao dịch (Số dư)', formatVND(_walletBalance), onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CODManagementPage())).then((_) => _loadData());
        }),
        _buildGridStat(Icons.check_circle_outline, Colors.blue.shade600, 'Đã hoàn thành', '${_dashboard?['hom_nay']?['don_hoan_thanh'] ?? 0} đơn'),
        _buildGridStat(Icons.show_chart, Colors.purple.shade600, 'Tỷ lệ nhận đơn', '${_dashboard?['hom_nay']?['ty_le_hoan_thanh'] ?? 0}%'),
      ],
    );
  }

  Widget _buildGridStat(IconData icon, Color color, String title, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => _switchTab(1),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2)),
            ]),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, Color bg, String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bg.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: bg, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      ),
    );
  }
}
