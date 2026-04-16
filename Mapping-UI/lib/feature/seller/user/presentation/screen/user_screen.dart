import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_state.dart';

class SellerUserScreen extends StatelessWidget {
  const SellerUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerUserCubit()..loadUserInfo(),
      child: const _SellerUserView(),
    );
  }
}

class _SellerUserView extends StatelessWidget {
  const _SellerUserView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: BlocBuilder<SellerUserCubit, SellerUserState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SellerUserCubit>().refreshData(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildHeader(context),
              const Divider(height: 2, thickness: 2, color: Color(0xFFD9D9D9)),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<SellerUserCubit>().refreshData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildCategoriesCard(context, state),
                        const Divider(height: 5, thickness: 5, color: Color(0xFFD9D9D9)),
                        _buildInfoCard(context, state),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<SellerUserCubit, SellerUserState>(
        builder: (context, state) {
          return _buildBottomNavigation(context, state);
        },
      ),
    );
  }

  /// Header với title và nút back
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 12),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.read<SellerUserCubit>().goBack(),
            child: const Icon(
              Icons.arrow_back_ios,
              size: 16,
              color: Colors.black,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'GIAN HÀNG CỦA TÔI',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: 0.5,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16), // Balance for back button
        ],
      ),
    );
  }

  /// Card Danh mục
  Widget _buildCategoriesCard(BuildContext context, SellerUserState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Các loại danh mục',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.sellerInfo?.categoriesDisplay ?? '',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Card Thông tin chi tiết
  Widget _buildInfoCard(BuildContext context, SellerUserState state) {
    final sellerInfo = state.sellerInfo;
    if (sellerInfo == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 27, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên người bán
          _buildInfoRow(
            context,
            label: sellerInfo.fullName,
            showEdit: true,
            onEdit: () => context.read<SellerUserCubit>().editPersonalInfo(),
          ),
          const SizedBox(height: 8),
          // Chợ
          _buildInfoRowWithArrow(
            context,
            label: 'Chợ: ${sellerInfo.marketName}',
            onTap: () => context.read<SellerUserCubit>().editMarketInfo(),
          ),
          const SizedBox(height: 8),
          // Số lô
          _buildInfoRow(
            context,
            label: 'Số lô: ${sellerInfo.stallNumber}',
            showEdit: false,
          ),
          const SizedBox(height: 8),
          // Số tài khoản
          _buildInfoRow(
            context,
            label: 'Số tài khoản: ${sellerInfo.accountNumber}',
            showEdit: true,
            onEdit: () => context.read<SellerUserCubit>().editAccountNumber(),
          ),
          const SizedBox(height: 8),
          // Ngân hàng
          _buildInfoRowWithArrow(
            context,
            label: 'Ngân hàng: ${sellerInfo.bankName}',
            onTap: () => context.read<SellerUserCubit>().editBankInfo(),
          ),
          const SizedBox(height: 8),
          // Số điện thoại
          _buildInfoRow(
            context,
            label: 'Số điện thoại: ${sellerInfo.phoneNumber}',
            showEdit: true,
            onEdit: () => context.read<SellerUserCubit>().editPhoneNumber(),
          ),
          const SizedBox(height: 24),
          // Nút Đăng xuất
          Center(
            child: GestureDetector(
              onTap: () => _showLogoutDialog(context),
              child: const Text(
                'Đăng Xuất',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  letterSpacing: -0.2,
                  color: Color(0xFF0F2F63),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Row thông tin với icon edit
  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required bool showEdit,
    VoidCallback? onEdit,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              letterSpacing: -0.2,
              height: 1.76,
              color: Color(0xFF202020),
            ),
          ),
        ),
        if (showEdit && onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: const Icon(
              Icons.edit,
              size: 16,
              color: Color(0xFF1C1B1F),
            ),
          ),
      ],
    );
  }

  /// Row thông tin với icon arrow
  Widget _buildInfoRowWithArrow(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: -0.2,
                height: 1.76,
                color: Color(0xFF202020),
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Color(0xFF1C1B1F),
          ),
        ],
      ),
    );
  }

  /// Dialog xác nhận đăng xuất
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<SellerUserCubit>().logout();
              },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Bottom Navigation Bar
  Widget _buildBottomNavigation(BuildContext context, SellerUserState state) {
    final cubit = context.read<SellerUserCubit>();

    return Container(
      height: 69,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Đơn hàng
          _buildNavItem(
            context,
            icon: Icons.receipt_long,
            label: 'Đơn hàng',
            isSelected: state.currentTabIndex == 0,
            onTap: () => cubit.changeTab(0),
          ),
          // Sản phẩm
          _buildNavItem(
            context,
            icon: Icons.shopping_bag,
            label: 'Sản phẩm',
            isSelected: state.currentTabIndex == 1,
            onTap: () => cubit.changeTab(1),
          ),
          // Avatar (Home)
          GestureDetector(
            onTap: () => cubit.changeTab(2),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: state.currentTabIndex == 2
                      ? const Color(0xFF00B40F)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/img/seller_home_avatar.png',
                  width: 58,
                  height: 58,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 58,
                      height: 58,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 30),
                    );
                  },
                ),
              ),
            ),
          ),
          // Doanh số
          _buildNavItem(
            context,
            icon: Icons.attach_money,
            label: 'Doanh số',
            isSelected: state.currentTabIndex == 3,
            onTap: () => cubit.changeTab(3),
          ),
          // Tài khoản
          _buildNavItem(
            context,
            icon: Icons.account_circle,
            label: 'Tài khoản',
            isSelected: state.currentTabIndex == 4,
            onTap: () => cubit.changeTab(4),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 28,
            color: isSelected ? const Color(0xFF00B40F) : Colors.black54,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: isSelected ? const Color(0xFF00B40F) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
