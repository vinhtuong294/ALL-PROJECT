import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/home_header.dart';
import '../widgets/kpi_card.dart';
import '../widgets/stats_grid.dart';
import '../widgets/low_stock_section.dart';
import '../widgets/quick_actions.dart';
import '../widgets/recent_orders_section.dart';

class SellerHomeScreen extends StatelessWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SellerHomeCubit()..initializeHome(),
      child: const _SellerHomeView(),
    );
  }
}

class _SellerHomeView extends StatelessWidget {
  const _SellerHomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SellerHomeCubit, SellerHomeState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF26CD3A))),
          );
        }

        if (state.errorMessage != null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SellerHomeCubit>().refreshData(),
                    child: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: state.isStoreOpen ? const Color(0xFFF5F9F6) : Colors.red[50],
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => context.read<SellerHomeCubit>().refreshData(),
                color: const Color(0xFF26CD3A),
                child: CustomScrollView(
                  slivers: [
                    HomeHeader(state: state),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Shop Status Toggle
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: state.isStoreOpen ? Colors.white : Colors.red[100],
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: state.isStoreOpen ? Colors.transparent : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: state.isStoreOpen ? const Color(0xFFE8F5E9) : Colors.red[50],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          state.isStoreOpen ? Icons.store : Icons.store_outlined,
                                          color: state.isStoreOpen ? const Color(0xFF26CD3A) : Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Trạng thái gian hàng',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            state.isStoreOpen ? 'ĐANG HOẠT ĐỘNG' : 'TẠM NGƯNG',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: state.isStoreOpen ? const Color(0xFF2E7D32) : Colors.red[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: state.isStoreOpen,
                                    onChanged: (value) => context.read<SellerHomeCubit>().toggleStoreStatus(),
                                    activeColor: const Color(0xFF26CD3A),
                                    activeTrackColor: const Color(0xFFE8F5E9),
                                    inactiveThumbColor: Colors.red,
                                    inactiveTrackColor: Colors.red[100],
                                  ),
                                ],
                              ),
                            ),
                            KPIOverviewCard(state: state),
                            const SizedBox(height: 16),
                            StatsGrid(state: state),
                            const SizedBox(height: 24),
                            // Quick Actions Section
                            const QuickActions(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    LowStockSection(state: state),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: RecentOrdersSection(state: state),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                ),
              ),
              if (!state.isStoreOpen)
                IgnorePointer(
                  child: Container(
                    color: Colors.red.withOpacity(0.05),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
