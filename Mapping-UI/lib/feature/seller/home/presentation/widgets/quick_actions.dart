import 'package:flutter/material.dart';
import '../../../../../core/config/route_name.dart';
import '../../../../../core/router/app_router.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chức năng nhanh',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionItem(context, 'Sản phẩm', Icons.inventory_2, const Color(0xFFE8F5E9), 
              () => AppRouter.navigateTo(context, RouteName.sellerMain, arguments: 1)),
            _buildQuickActionItem(context, 'Đơn hàng', Icons.assignment, const Color(0xFFE3F2FD), 
              () => AppRouter.navigateTo(context, RouteName.sellerMain, arguments: 2)),
            _buildQuickActionItem(context, 'Thống kê', Icons.bar_chart, const Color(0xFFF1F8E9), 
              () => AppRouter.navigateTo(context, RouteName.sellerMain, arguments: 3)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(BuildContext context, String label, IconData icon, Color bgColor, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: const Color(0xFF26CD3A), size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
