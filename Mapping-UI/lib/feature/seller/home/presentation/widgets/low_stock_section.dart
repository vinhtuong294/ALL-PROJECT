import 'package:flutter/material.dart';
import '../../../../../core/config/route_name.dart';
import '../../../../../core/router/app_router.dart';
import '../cubit/home_state.dart';

class LowStockSection extends StatelessWidget {
  final SellerHomeState state;

  const LowStockSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.lowStockProducts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cảnh báo hết hàng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.lowStockProducts.length} sản phẩm',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...state.lowStockProducts.map((prod) => GestureDetector(
            onTap: () => AppRouter.navigateTo(context, RouteName.sellerMain, arguments: 1),
            child: _buildLowStockCard(context, prod),
          )),
        ],
      ),
    );
  }

  Widget _buildLowStockCard(BuildContext context, dynamic prod) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              image: prod['hinh_anh'] != null ? DecorationImage(
                image: NetworkImage(prod['hinh_anh']),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: prod['hinh_anh'] == null ? const Icon(Icons.image_outlined, color: Colors.grey) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prod['ten_nguyen_lieu'] ?? 'Sản phẩm',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'SKU: ${prod['ma_nguyen_lieu'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Chỉ còn ${prod['so_luong_ban']}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Text(
                'Tồn kho',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
