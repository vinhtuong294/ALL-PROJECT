import 'package:flutter/material.dart';
import '../../../../../core/services/api_service.dart';
import '../../../../../core/utils/helpers.dart';
import '../main_screen.dart';
import '../delivery_route_page.dart';
import '../cod_management_page.dart';
import '../notifications_page.dart';
import '../wallet_page.dart';
import '../market_map_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final results = await Future.wait([ApiService.getMe(), ApiService.getDashboard()]);
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
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchTab(int index) {
    context.findAncestorStateOfType<MainScreenState>()?.switchToTab(index);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Chào buổi sáng';
    if (h < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
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
                  _buildHeader(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EarningsCard(
                          walletBalance: _walletBalance,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletPage())).then((_) => _loadData()),
                        ),
                        const SizedBox(height: 16),
                        _StatsRow(dashboard: _dashboard),
                        const SizedBox(height: 24),
                        const Text('Thao tác nhanh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                        const SizedBox(height: 12),
                        _QuickActions(
                          onOrders: () => _switchTab(1),
                          onMap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketMapScreen())),
                          onCOD: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CODManagementPage())).then((_) => _loadData()),
                          onRoute: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryRoutePage())),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final name = _user?['user_name'] ?? 'Shipper';
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 14, 20, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFF00B40F), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500)),
                Text(name, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage())),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_outlined, color: Color(0xFF475569), size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final int walletBalance;
  final VoidCallback onTap;
  const _EarningsCard({required this.walletBalance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00B40F), Color(0xFF34C759)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00B40F).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
                  Text(formatVND(walletBalance), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Map<String, dynamic>? dashboard;
  const _StatsRow({this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(icon: Icons.local_shipping_rounded, color: const Color(0xFF0EA5E9), label: 'Hôm nay', value: '${dashboard?['don_hom_nay'] ?? 0}', unit: 'đơn'),
        const SizedBox(width: 10),
        _StatCard(icon: Icons.check_circle_rounded, color: const Color(0xFF00B40F), label: 'Hoàn thành', value: '${dashboard?['tong_don_hoan_thanh'] ?? 0}', unit: 'đơn'),
        const SizedBox(width: 10),
        _StatCard(icon: Icons.star_rounded, color: const Color(0xFFF59E0B), label: 'Tỷ lệ HT', value: '${dashboard?['ty_le_hoan_thanh'] ?? 0}', unit: '%'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String unit;
  const _StatCard({required this.icon, required this.color, required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(children: [
                TextSpan(text: value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w900)),
                TextSpan(text: ' $unit', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onOrders;
  final VoidCallback onMap;
  final VoidCallback onCOD;
  final VoidCallback onRoute;
  const _QuickActions({required this.onOrders, required this.onMap, required this.onCOD, required this.onRoute});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          _ActionTile(icon: Icons.assignment_rounded, color: const Color(0xFF00B40F), label: 'Nhận đơn mới', onTap: onOrders),
          const SizedBox(width: 10),
          _ActionTile(icon: Icons.alt_route_rounded, color: const Color(0xFF6366F1), label: 'Lộ trình giao', onTap: onRoute),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _ActionTile(icon: Icons.map_rounded, color: const Color(0xFF0EA5E9), label: 'Bản đồ chợ', onTap: onMap),
          const SizedBox(width: 10),
          _ActionTile(icon: Icons.account_balance_wallet_rounded, color: const Color(0xFFF59E0B), label: 'Ví Shipper', onTap: onCOD),
        ]),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1E293B))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
