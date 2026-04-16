import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/widgets/seller_bottom_navigation.dart';
import '../../../order/presentation/screen/order_screen.dart';
import '../../../ingredient/presentation/screen/ingredient_screen.dart';
import '../../../home/presentation/screen/home_screen.dart';
import '../../../revenue/presentation/screen/revenue_screen.dart';
import '../../../user/presentation/screen/seller_user_screen.dart';
import '../cubit/seller_main_cubit.dart';

/// Màn hình chính của seller với smooth page transitions
class SellerMainScreen extends StatelessWidget {
  final int initialIndex;
  
  const SellerMainScreen({
    super.key,
    this.initialIndex = 0, // Mặc định là Home
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerMainCubit(initialIndex: initialIndex),
      child: const _SellerMainView(),
    );
  }
}

class _SellerMainView extends StatefulWidget {
  const _SellerMainView();

  @override
  State<_SellerMainView> createState() => _SellerMainViewState();
}

class _SellerMainViewState extends State<_SellerMainView> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = context.read<SellerMainCubit>().state.currentIndex;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<SellerMainCubit, SellerMainState>(
        listenWhen: (previous, current) => previous.currentIndex != current.currentIndex,
        listener: (context, state) {
          // Smooth animate to new page
          _pageController.animateToPage(
            state.currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Disable swipe, only use bottom nav
          children: const [
            _KeepAliveWrapper(child: SellerHomeScreen()), // Tab 0: Trang chủ
            _KeepAliveWrapper(child: SellerIngredientScreen()), // Tab 1: Sản phẩm
            _KeepAliveWrapper(child: SellerOrderScreen()), // Tab 2: Đơn hàng
            _KeepAliveWrapper(child: SellerRevenueScreen()), // Tab 3: Doanh số
            _KeepAliveWrapper(child: SellerUserScreen()), // Tab 4: Tài khoản
          ],
        ),
      ),
      bottomNavigationBar: BlocBuilder<SellerMainCubit, SellerMainState>(
        builder: (context, state) {
          return SellerBottomNavigation(
            currentIndex: state.currentIndex,
            onTap: (index) => context.read<SellerMainCubit>().changeTab(index),
          );
        },
      ),
    );
  }
}

/// Widget wrapper để giữ trạng thái của child widget
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

