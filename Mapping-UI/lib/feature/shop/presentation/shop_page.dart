import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/buyer_loading.dart';
import 'shop_cubit.dart';

class ShopPage extends StatefulWidget {
  final String? shopId;

  const ShopPage({
    super.key,
    this.shopId,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  late ShopCubit _shopCubit;

  @override
  void initState() {
    super.initState();
    _shopCubit = context.read<ShopCubit>();
    // Load shop data với shopId từ arguments hoặc parameters
    final shopId = widget.shopId ?? ModalRoute.of(context)?.settings.arguments as String?;
    if (shopId != null) {
      _shopCubit.loadShop(shopId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<ShopCubit, ShopState>(
        builder: (context, state) {
          if (state is ShopLoading) {
            return const BuyerLoading(
              message: 'Đang tải gian hàng...',
            );
          }

          if (state is ShopFailure) {
            return Center(
              child: Text('Lỗi: ${state.errorMessage}'),
            );
          }

          if (state is ShopLoaded) {
            return _buildShopPage(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildShopPage(BuildContext context, ShopLoaded state) {
    return CustomScrollView(
      slivers: [
        // Status bar area
        SliverAppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          pinned: true,
          toolbarHeight: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: SizedBox.shrink(),
          ),
        ),

        // Shop header dengan banner
        SliverToBoxAdapter(
          child: _buildShopHeader(context, state.shopInfo),
        ),

        // Shop info section
        SliverToBoxAdapter(
          child: _buildShopInfoSection(context, state.shopInfo),
        ),

        // Category tabs
        SliverToBoxAdapter(
          child: _buildCategoryTabs(context, state),
        ),

        // Products grid
        SliverToBoxAdapter(
          child: _buildProductsSection(context, state),
        ),
      ],
    );
  }

  /// Build shop header với banner
  Widget _buildShopHeader(BuildContext context, ShopInfo shopInfo) {
    return Column(
      children: [
        // Banner image
        Stack(
          children: [
            Image.asset(
              'assets/img/shop_header_banner.png',
              height: 179,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            // Avatar overlay
            Positioned(
              left: 12,
              bottom: -24,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: Image.asset(
                    'assets/img/shop_seller_1.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 44), // Space for avatar
      ],
    );
  }

  /// Build shop info section
  Widget _buildShopInfoSection(BuildContext context, ShopInfo shopInfo) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop name with rating
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopInfo.shopName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF202020),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          '5',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF0C0D0D),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          'assets/img/shop_star_icon.png',
                          width: 21,
                          height: 19,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/img/shop_seller_2.png',
                  width: 123,
                  height: 92,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Đã bán hơn ${shopInfo.soldCount} đơn hàng',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '${shopInfo.productCount} sản phẩm',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Categories section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Danh mục',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF202020),
                ),
              ),
              Row(
                children: List.generate(
                  shopInfo.categories.length,
                  (index) => Padding(
                    padding: EdgeInsets.only(right: index < shopInfo.categories.length - 1 ? 12 : 0),
                    child: _buildCategoryChip(shopInfo.categories[index], index),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  /// Build stat item
  Widget _buildStatItem(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Color(0xFF202020),
      ),
    );
  }

  /// Build category chip
  Widget _buildCategoryChip(String category, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 0.3,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        category,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
      ),
    );
  }

  /// Build category tabs
  Widget _buildCategoryTabs(BuildContext context, ShopLoaded state) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _buildCategoryTab('Tất cả', 0, state.selectedTabIndex),
            const SizedBox(width: 8),
            _buildCategoryTab('Gia vị', 1, state.selectedTabIndex),
            const SizedBox(width: 8),
            _buildCategoryTab('Thịt heo', 2, state.selectedTabIndex),
          ],
        ),
      ),
    );
  }

  /// Build category tab
  Widget _buildCategoryTab(String label, int index, int selectedIndex) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => context.read<ShopCubit>().selectCategory(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F8000) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  /// Build products section
  Widget _buildProductsSection(BuildContext context, ShopLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: state.products.length,
        itemBuilder: (context, index) {
          final product = state.products[index];
          return _buildProductCard(context, product);
        },
      ),
    );
  }

  /// Build product card
  Widget _buildProductCard(BuildContext context, ShopProduct product) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to product detail
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xem chi tiết: ${product.productName}')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withOpacity(0.15),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: Image.asset(
                    product.productImage,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Badge
                if (product.badge.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildBadge(product.badge),
                  ),
                // Favorite button
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () => context.read<ShopCubit>().toggleProductFavorite(product.productId),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        product.isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: product.isFavorite ? Colors.red : Colors.grey,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Expanded(
                      child: Text(
                        product.productName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Price
                    Text(
                      '${(product.price / 1000).toStringAsFixed(0)}.000đ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),

                    // Sold count
                    if (product.badge.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          product.badge,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Buy button
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFF5F5F5),
                    width: 0.5,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  context.read<ShopCubit>().addToCart(product.productId, 1);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm ${product.productName} vào giỏ'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: const Color(0xFF2F8000),
                  child: const Text(
                    'Mua ngay',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build badge
  Widget _buildBadge(String badge) {
    Color backgroundColor;
    if (badge == 'Flash sale') {
      backgroundColor = const Color(0xFFF73A3A);
    } else if (badge == 'Đang bán chạy') {
      backgroundColor = const Color(0xFFF58787);
    } else {
      backgroundColor = const Color(0xFFF58787);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        badge,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
