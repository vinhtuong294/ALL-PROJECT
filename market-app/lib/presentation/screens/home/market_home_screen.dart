import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/dashboard_stats_model.dart';
import '../../../injection_container.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../bloc/dashboard/dashboard_event.dart';
import '../../bloc/dashboard/dashboard_state.dart';
import '../../widgets/common/market_app_bar.dart';
import '../../widgets/common/market_bottom_nav_bar.dart';
import 'vendor_list_screen.dart';
import 'market_book_screen.dart';
import 'tax_collection_screen.dart';
import 'add_vendor_screen.dart';
import 'account_screen.dart';
import 'market_map_screen.dart';

class MarketHomeScreen extends StatefulWidget {
  const MarketHomeScreen({super.key});

  @override
  State<MarketHomeScreen> createState() => _MarketHomeScreenState();
}

class _MarketHomeScreenState extends State<MarketHomeScreen> {
  MarketNavItem _currentNav = MarketNavItem.home;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DashboardBloc>()..add(GetDashboardStatsEvent()),
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          DashboardStatsModel? stats;
          if (state is DashboardSuccess) stats = state.stats;

          final subtitle = stats != null
              ? '${stats.managerName} · ${stats.marketName}'
              : 'Hệ thống Quản lý Chợ Thông minh';

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: MarketAppBar(
              title: 'Trang chủ quản lý chợ',
              subtitle: subtitle,
            ),
            body: state is DashboardLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async =>
                        context.read<DashboardBloc>().add(GetDashboardStatsEvent()),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsRow(stats),
                          const SizedBox(height: 14),
                          _buildRevenueCard(stats),
                          const SizedBox(height: 14),
                          _buildMarketBookCard(),
                          const SizedBox(height: 14),
                          _buildMarketMapCard(),
                          const SizedBox(height: 14),
                          _buildVendorManagementCard(stats),
                          const SizedBox(height: 14),
                          _buildTaxCollectionCard(stats),
                          const SizedBox(height: 24),
                          _buildViewVendorsLink(),
                          const SizedBox(height: 10),
                          _buildLogoutButton(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
            bottomNavigationBar: MarketBottomNavBar(
              currentItem: _currentNav,
              onTap: _handleNavTap,
            ),
          );
        },
      ),
    );
  }

  void _handleNavTap(MarketNavItem item) {
    if (item == MarketNavItem.vendors) {
      _goToVendors();
    } else if (item == MarketNavItem.market) {
      _goToMarketBook();
    } else if (item == MarketNavItem.tax) {
      _goToTaxCollection();
    } else if (item == MarketNavItem.profile) {
      _goToAccount();
    } else {
      setState(() => _currentNav = item);
    }
  }

  void _goToAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AccountScreen(
          currentNav: MarketNavItem.profile,
          onNavTap: (item) {
            Navigator.pop(context);
            if (item != MarketNavItem.profile) {
              _handleNavTap(item);
            }
          },
        ),
      ),
    );
  }

  void _goToTaxCollection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaxCollectionScreen(
          currentNav: MarketNavItem.tax,
          onNavTap: (item) {
            Navigator.pop(context);
            if (item != MarketNavItem.tax) {
              _handleNavTap(item);
            }
          },
        ),
      ),
    );
  }

  void _goToMarketBook() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MarketBookScreen(
          currentNav: MarketNavItem.market,
          onNavTap: (item) {
            Navigator.pop(context);
            if (item != MarketNavItem.market) {
              _handleNavTap(item);
            }
          },
        ),
      ),
    );
  }

  void _goToMarketMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MarketMapScreen(),
      ),
    );
  }

  void _goToAddVendor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddVendorScreen(
          currentNav: _currentNav,
          onNavTap: _handleNavTap,
        ),
      ),
    );
  }

  void _goToVendors() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VendorListScreen(
          currentNav: MarketNavItem.vendors,
          onNavTap: (item) {
            Navigator.pop(context);
            if (item != MarketNavItem.vendors) {
              setState(() => _currentNav = item);
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow(DashboardStatsModel? stats) {
    return Row(
      children: [
        Expanded(
          child: _SmallStatCard(
            icon: Icons.people_outline,
            count: stats?.activeMerchants.toString() ?? '--',
            label: 'Tiểu thương hoạt động',
            iconBg: const Color(0xFFE8F5E9),
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SmallStatCard(
            icon: Icons.inbox_outlined,
            count: stats?.ordersToday.toString() ?? '--',
            label: 'Đơn hàng hôm nay',
            iconBg: const Color(0xFFE8F5E9),
            iconColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCard(DashboardStatsModel? stats) {
    final revenue = stats != null
        ? '${(stats.monthlyTaxRevenue).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} VNĐ'
        : '--';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monetization_on_outlined,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tổng thu thuế tháng',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                revenue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarketBookCard() {
    return _ManagementCard(
      icon: Icons.menu_book_outlined,
      title: 'Quản lý Sổ Chợ',
      child: _GreenButton(
        label: 'Cập nhật Sổ Chợ',
        onTap: _goToMarketBook,
      ),
    );
  }

  Widget _buildMarketMapCard() {
    return _ManagementCard(
      icon: Icons.map_outlined,
      title: 'Bản Đồ Chợ',
      child: _GreenButton(
        label: 'Xem Sơ Đồ Chợ',
        onTap: _goToMarketMap,
      ),
    );
  }

  Widget _buildVendorManagementCard(DashboardStatsModel? stats) {
    return _ManagementCard(
      icon: Icons.storefront_outlined,
      title: 'Quản lý Tiểu thương',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${stats?.totalStalls ?? '--'} ',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                  ),
                  const TextSpan(
                    text: 'Gian hàng',
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _GreenButton(label: 'Thêm Tiểu thương Mới', onTap: _goToAddVendor),
        ],
      ),
    );
  }

  Widget _buildTaxCollectionCard(DashboardStatsModel? stats) {
    final pending = stats?.pendingTaxStalls;
    final total = stats?.totalStalls;
    final pendingLabel = (pending != null && total != null)
        ? '$pending/$total chưa thu'
        : '-- chưa thu';
    return GestureDetector(
      onTap: _goToTaxCollection,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Thu Thuế Gian Hàng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A).withOpacity(0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pendingLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: _goToTaxCollection,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Thu Thuế Ngay',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewVendorsLink() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: _goToVendors,
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFF7FAFC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Xem Danh sách tiểu thương',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.arrow_forward, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton.icon(
        onPressed: () => _showLogoutDialog(),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.logoutBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.logout, color: AppColors.logoutText, size: 18),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(
            color: AppColors.logoutText,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LoggedOut());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color iconBg;
  final Color iconColor;

  const _SmallStatCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration:
                BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                    maxLines: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _GreenButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GreenButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
