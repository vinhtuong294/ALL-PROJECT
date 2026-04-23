import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_app/core/constants/app_colors.dart';
import 'package:market_app/data/models/merchant_model.dart';
import 'package:market_app/presentation/bloc/merchant/merchant_bloc.dart';
import 'package:market_app/presentation/bloc/merchant/merchant_event.dart';
import 'package:market_app/presentation/bloc/merchant/merchant_state.dart';
import 'package:market_app/injection_container.dart';

class AccountHistoryScreen extends StatefulWidget {
  const AccountHistoryScreen({super.key});

  @override
  State<AccountHistoryScreen> createState() => _AccountHistoryScreenState();
}

class _AccountHistoryScreenState extends State<AccountHistoryScreen> {
  late MerchantBloc _merchantBloc;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _merchantBloc = sl<MerchantBloc>()..add(const GetMerchantsEvent());
  }

  void _triggerFetch({int page = 1}) {
    _merchantBloc.add(GetMerchantsEvent(page: page));
  }

  @override
  void dispose() {
    _merchantBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _merchantBloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Lịch sử tạo tài khoản',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        body: BlocBuilder<MerchantBloc, MerchantState>(
          builder: (context, state) {
            if (state is MerchantLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is MerchantError) {
              return Center(child: Text(state.message));
            } else if (state is MerchantLoaded) {
              final merchants = state.merchants.where((m) => m.ngayTao != null).toList();
              
              if (merchants.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off, size: 64, color: AppColors.textHint),
                      SizedBox(height: 16),
                      Text('Chưa có tiểu thương nào được tạo',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: merchants.length + (state.meta.totalPages > 1 ? 1 : 0),
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == merchants.length) {
                    return _buildPagination(state.meta.totalPages, state.meta.total);
                  }
                  
                  final merchant = merchants[index];
                  return _HistoryCard(merchant: merchant);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages, int total) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: _currentPage > 1 ? AppColors.primary : AppColors.textHint,
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _triggerFetch(page: _currentPage);
                  }
                : null,
          ),
          Column(
            children: [
              Text('Trang $_currentPage / $totalPages',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: _currentPage < totalPages ? AppColors.primary : AppColors.textHint,
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() => _currentPage++);
                    _triggerFetch(page: _currentPage);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final MerchantModel merchant;

  const _HistoryCard({required this.merchant});

  @override
  Widget build(BuildContext context) {
    final dateStr = merchant.ngayTao != null ? merchant.ngayTao!.split('-').reversed.join('/') : '';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  merchant.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 12),
          
          Row(
            children: [
              const Icon(Icons.phone_android, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Tài khoản: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(
                merchant.sdt ?? 'Không rõ',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Mật khẩu: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(
                '123456',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.storefront, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Gian hàng: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(
                merchant.stallId ?? 'Chưa tạo',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
              ),
              if (merchant.stallName != null) ...[
                const Text(' - ', style: TextStyle(color: AppColors.textSecondary)),
                Expanded(
                  child: Text(
                    merchant.stallName!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]
            ],
          )
        ],
      ),
    );
  }
}
