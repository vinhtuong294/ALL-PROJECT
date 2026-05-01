import 'package:flutter/material.dart';
import 'package:market_app/core/constants/app_colors.dart';

enum MarketNavItem { home, vendors, market, tax, profile }

/// Bottom Navigation Bar tái sử dụng - 5 tab: Trang chủ, Tiểu thương, Sổ Chợ, Thuế, Cá nhân
class MarketBottomNavBar extends StatelessWidget {
  final MarketNavItem currentItem;
  final ValueChanged<MarketNavItem> onTap;

  const MarketBottomNavBar({
    super.key,
    required this.currentItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Trang chủ',
                isActive: currentItem == MarketNavItem.home,
                onTap: () => onTap(MarketNavItem.home),
              ),
              _NavItem(
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Tiểu thương',
                isActive: currentItem == MarketNavItem.vendors,
                onTap: () => onTap(MarketNavItem.vendors),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book,
                label: 'Sổ Chợ',
                isActive: currentItem == MarketNavItem.market,
                onTap: () => onTap(MarketNavItem.market),
              ),
              _NavItem(
                icon: Icons.receipt_outlined,
                activeIcon: Icons.receipt,
                label: 'Thu tiền',
                isActive: currentItem == MarketNavItem.tax,
                onTap: () => onTap(MarketNavItem.tax),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Cá nhân',
                isActive: currentItem == MarketNavItem.profile,
                onTap: () => onTap(MarketNavItem.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 24,
              color: isActive ? AppColors.primary : AppColors.iconGrey,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.iconGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
