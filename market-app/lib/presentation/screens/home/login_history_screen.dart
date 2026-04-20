import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:market_app/core/constants/app_colors.dart';
import 'package:market_app/presentation/widgets/common/market_app_bar.dart';
import 'package:market_app/presentation/widgets/common/market_bottom_nav_bar.dart';
import '../../bloc/profile/profile_bloc.dart';
import '../../bloc/profile/profile_event.dart';
import '../../bloc/profile/profile_state.dart';
import '../../../data/models/login_history_model.dart';
import '../../../injection_container.dart';

class LoginHistoryScreen extends StatelessWidget {
  final MarketNavItem currentNav;
  final ValueChanged<MarketNavItem> onNavTap;

  const LoginHistoryScreen({
    super.key,
    required this.currentNav,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProfileBloc>()..add(GetLoginHistoryEvent()),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MarketAppBar(
          title: 'Lịch sử đăng nhập',
          showBack: true,
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is ProfileError) {
              return Center(child: Text(state.message));
            } else if (state is LoginHistoryLoaded) {
              final history = state.history;
              if (history.isEmpty) {
                return const Center(child: Text('Chưa có lịch sử đăng nhập.'));
              }
              
              // Map device info for the current session (first item)
              final currentSession = history.first;
              final recentActivities = history.skip(1).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Phiên Đăng nhập Hiện tại'),
                    _buildSessionCard(currentSession, isCurrent: true),
                    const SizedBox(height: 24),
                    if (recentActivities.isNotEmpty) ...[
                      _buildSectionHeader('Hoạt động Gần đây'),
                      Container(
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
                          children: recentActivities.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            return Column(
                              children: [
                                _buildHistoryItem(item),
                                if (idx < recentActivities.length - 1)
                                  const Divider(height: 1, indent: 70),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _buildRevokeSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
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
              child: _buildSubmitButton(),
            ),
            MarketBottomNavBar(
              currentItem: currentNav,
              onTap: onNavTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSessionCard(LoginHistoryModel item, {bool isCurrent = false}) {
    final dateFmt = DateFormat('dd/MM/yyyy, HH:mm');
    final timeStr = dateFmt.format(DateTime.parse(item.time));
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [
            isCurrent ? const Color(0x33B3FFC9) : Colors.white,
            isCurrent ? const Color(0x338EF5B0) : Colors.white,
          ],
          stops: const [0.6464, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? const Color(0xFFC8E6C9) : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrent ? Colors.white : const Color(0xFFF7FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getDeviceIcon(item.deviceInfo),
              color: isCurrent ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.deviceInfo ?? 'Thiết bị không xác định',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC8E6C9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Hiện tại',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.osInfo ?? 'OS'} • ${item.location ?? 'Vị trí không xác định'}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Đăng nhập: $timeStr',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(LoginHistoryModel item) {
    final dateFmt = DateFormat('dd/MM/yyyy, HH:mm');
    final timeStr = dateFmt.format(DateTime.parse(item.time));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getDeviceIcon(item.deviceInfo),
              color: const Color(0xFF2196F3),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.deviceInfo ?? 'Thiết bị không xác định',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${item.osInfo ?? 'OS'} • ${item.location ?? 'Vị trí'}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                Text(
                  timeStr,
                  style: const TextStyle(color: AppColors.textHint, fontSize: 11),
                ),
              ],
            ),
          ),
          Icon(
            item.success ? Icons.check_circle : Icons.cancel,
            color: item.success ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            size: 24,
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String? info) {
    final lower = info?.toLowerCase() ?? '';
    if (lower.contains('iphone') || lower.contains('phone') || lower.contains('android')) {
      return Icons.smartphone;
    } else if (lower.contains('macbook') || lower.contains('laptop')) {
      return Icons.laptop_mac;
    } else if (lower.contains('ipad') || lower.contains('tablet')) {
      return Icons.tablet_mac;
    }
    return Icons.computer;
  }

  Widget _buildRevokeSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Hủy Tất cả Phiên',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hành động này sẽ đăng xuất khỏi tất cả thiết bị ngoại trừ thiết bị hiện tại.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF991B1B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
            ),
            child: const Text(
              'Hủy Tất cả Phiên Khác',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
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
            color: const Color(0xFF43A047).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Đổi Mật Khẩu',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
