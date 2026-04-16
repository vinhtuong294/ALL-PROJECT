import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../config/route_name.dart';

/// Shared Bottom Navigation Widget
/// Dùng chung cho tất cả các màn hình trong app
class SharedBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const SharedBottomNavigation({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            icon: 'assets/img/add_home.svg',
            label: 'Trang chủ',
            index: 0,
            currentIndex: currentIndex,
            route: RouteName.home,
            isImage: false,
          ),
          _buildNavItem(
            context,
            icon: 'assets/img/mon_an_icon.png',
            label: 'Món ăn',
            index: 1,
            currentIndex: currentIndex,
            route: RouteName.productList,
            isImage: true,
          ),
          // Logo App ở giữa (không điều hướng)
          _buildNavItem(
            context,
            icon: 'assets/img/user_personas_presentation-26cd3a.png',
            label: '',
            index: 2,
            currentIndex: currentIndex,
            isCenter: true,
          ),
          _buildNavItem(
            context,
            icon: 'assets/img/ingredient.png',
            label: 'Nguyên liệu',
            index: 3,
            currentIndex: currentIndex,
            route: RouteName.ingredient,
            isImage: true,
          ),
          _buildNavItem(
            context,
            icon: 'assets/img/account_circle.svg',
            label: 'Tài khoản',
            index: 4,
            currentIndex: currentIndex,
            route: RouteName.user,
            isImage: false,
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation Item
  Widget _buildNavItem(
    BuildContext context, {
    required String icon,
    required String label,
    required int index,
    required int currentIndex,
    String? route,
    bool isImage = false,
    bool isCenter = false,
  }) {
    final isSelected = index == currentIndex;
    
    return InkWell(
      onTap: () {
        // Nếu đã được chọn, không làm gì
        if (isSelected) return;
        
        // Gọi callback để thay đổi tab
        onTap?.call(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCenter)
              Container(
                width: 58,
                height: 67,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(icon),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else ...[
              isImage
                  ? Image.asset(
                      icon,
                      width: 30,
                      height: 30,
                      color: isSelected ? const Color(0xFF00B40F) : null,
                    )
                  : SvgPicture.asset(
                      icon,
                      width: 30,
                      height: 30,
                      colorFilter: ColorFilter.mode(
                        isSelected ? const Color(0xFF00B40F) : const Color(0xFF000000),
                        BlendMode.srcIn,
                      ),
                    ),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 12,
                    height: 1.33,
                    color: isSelected ? const Color(0xFF00B40F) : const Color(0xFF000000),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
