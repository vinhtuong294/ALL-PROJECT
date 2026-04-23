import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes/app_router.dart';
import '../../../core/constants/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.home),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),
          _CategoriesTab(),
          _CartTab(),
          _OrdersTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: AppStrings.home),
          BottomNavigationBarItem(icon: Icon(Icons.category_outlined), activeIcon: Icon(Icons.category), label: AppStrings.categories),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), activeIcon: Icon(Icons.shopping_cart), label: AppStrings.cart),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: AppStrings.orders),
          BottomNavigationBarItem(icon: Icon(Icons.person_outlined), activeIcon: Icon(Icons.person), label: AppStrings.profile),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Home Tab'));
  }
}

class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Categories Tab'));
  }
}

class _CartTab extends StatelessWidget {
  const _CartTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Cart Tab'));
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Orders Tab'));
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Profile Tab'));
  }
}
