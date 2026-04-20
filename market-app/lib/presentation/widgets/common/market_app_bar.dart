import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:market_app/core/constants/app_colors.dart';

/// AppBar xanh tái sử dụng cho toàn bộ app Quản lý Chợ
/// [title]: tiêu đề trang
/// [subtitle]: dòng thông tin người dùng/chợ (nền #45A049)
/// [showBack]: hiển thị nút back nếu true
/// [actions]: nút icon bên phải
class MarketAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final String? subtitleIcon; // optional emoji/icon text
  final List<Widget>? actions;
  final bool showBack;

  const MarketAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleIcon,
    this.actions,
    this.showBack = false,
  });

  @override
  Size get preferredSize {
    // Header cao hơn khi có subtitle
    return Size.fromHeight(subtitle != null ? 92 : 56);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Phần xanh chính (title + safe area top) ──────────────
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                automaticallyImplyLeading: false,
                leading: showBack
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    : null,
                title: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                actions: actions,
                systemOverlayStyle: SystemUiOverlayStyle.light,
              ),
            ),
          ),

          // ── Dải subtitle màu #45A049 ──────────────────────────────
          if (subtitle != null)
            Container(
              width: double.infinity,
              color: AppColors.primarySubtitle,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.account_circle_outlined,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
