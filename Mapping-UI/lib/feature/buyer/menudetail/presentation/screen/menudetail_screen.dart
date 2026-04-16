import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dngo/core/widgets/shared_bottom_navigation.dart';
import '../../../../../../feature/buyer/menudetail/presentation/cubit/menudetail_cubit.dart';
import '../../../../../../feature/buyer/menudetail/presentation/cubit/menudetail_state.dart';

class MenuDetailScreen extends StatelessWidget {
  const MenuDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MenuDetailCubit()
        ..loadMenuDetails(
          productName: 'Bún bò Huế',
          productImage: 'assets/img/product_detail_main_image.png',
          description:
              'Bún Bò Huế là món ăn đặc trưng với nước dùng đậm đà, cay nồng và dậy mùi sả cùng mắm ruốc. Món này dùng sợi bún to, ăn kèm với thịt bò, giò heo và chả cua, thường được tô điểm bằng màu đỏ cam hấp dẫn cùng rau sống tươi mát.',
        ),
      child: const _MenuDetailView(),
    );
  }
}

class _MenuDetailView extends StatelessWidget {
  const _MenuDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuDetailCubit, MenuDetailState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // Scrollable content
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, state),
                    _buildProductImage(state),
                    _buildDivider(),
                    _buildProductInfo(state),
                    _buildDivider(),
                    _buildQuantitySection(context, state),
                    _buildDetailsSection(state),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SharedBottomNavigation(
            currentIndex: state.selectedBottomNavIndex,
            onTap: (index) {
              context.read<MenuDetailCubit>().onBottomNavTap(index);
            },
          ),
        );
      },
    );
  }

  static Widget _buildHeader(BuildContext context, MenuDetailState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, size: 16),
              ),
              const Spacer(),
              // Share button
              GestureDetector(
                onTap: () {},
                child: const Icon(Icons.share_outlined, size: 24),
              ),
              const SizedBox(width: 20),
              // Cart button with badge
              Stack(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.shopping_cart_outlined, size: 24),
                  ),
                  if (state.cartItemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFDBDB),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${state.cartItemCount}',
                            style: const TextStyle(
                              color: Color(0xFFFF0000),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              // Three dots menu
              const Icon(Icons.more_vert, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildProductImage(MenuDetailState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 13),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.asset(
          state.productImage,
          width: 370,
          height: 308,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 370,
              height: 308,
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 100, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  static Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 2,
      color: const Color(0xFFD9D9D9),
    );
  }

  static Widget _buildProductInfo(MenuDetailState state) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name
          Text(
            state.productName,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w500,
              height: 0.64,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          // Description section
          const Text(
            'Mô tả món ăn',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            state.description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.33,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildQuantitySection(
      BuildContext context, MenuDetailState state) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Định lượng',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 198,
                height: 41,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFECECEC)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Decrement button
                    IconButton(
                      onPressed: () {
                        context.read<MenuDetailCubit>().decrementServings();
                      },
                      icon: const Icon(Icons.remove, size: 16),
                      color: const Color(0xFF7E7E7E),
                    ),
                    // Quantity display
                    Text(
                      '${state.servings} khẩu phần',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    // Increment button
                    IconButton(
                      onPressed: () {
                        context.read<MenuDetailCubit>().incrementServings();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      color: const Color(0xFF7E7E7E),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailsSection(MenuDetailState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Khẩu phần:', '${state.servings} người'),
          const SizedBox(height: 35),
          _buildDetailRow('Thời gian thực hiện:', state.preparationTime),
          const SizedBox(height: 35),
          _buildDetailRow('Dinh dưỡng:', state.nutrition),
          const SizedBox(height: 35),
          _buildDetailRow('Độ khó:', state.difficulty),
          const SizedBox(height: 35),
          _buildDetailRow('Công thức:', state.recipe),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Inter',
            color: Color(0xFF0F2F63),
            height: 5.83,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Inter',
            color: Color(0xFF0F2F63),
            height: 5.83,
          ),
        ),
      ],
    );
  }
}
