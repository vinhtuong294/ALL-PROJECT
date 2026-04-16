import 'package:flutter/material.dart';
import '../cubit/home_state.dart';

class HomeHeader extends StatelessWidget {
  final SellerHomeState state;

  const HomeHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: state.isStoreOpen 
              ? [const Color(0xFFE8F5E9), const Color(0xFFF5F9F6)]
              : [const Color(0xFFFFEBEE), const Color(0xFFFFEBEE)],
          ),
        ),
        child: Column(
          children: [
            if (!state.isStoreOpen)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'GIAN HÀNG ĐANG TẠM NGƯNG HOẠT ĐỘNG',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, ${state.shopName.split(' ').last}!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: state.isStoreOpen ? const Color(0xFF1B5E20) : Colors.red[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.isStoreOpen 
                        ? 'Chúc bạn một ngày bán hàng hiệu quả.'
                        : 'Gian hàng của bạn đang ở trạng thái tạm ngưng.',
                      style: TextStyle(
                        fontSize: 14,
                        color: state.isStoreOpen ? Colors.grey[600] : Colors.red[700],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        Icons.notifications_outlined, 
                        color: state.isStoreOpen ? const Color(0xFF26CD3A) : Colors.red,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
