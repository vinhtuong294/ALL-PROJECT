import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:market_app/core/constants/app_colors.dart';
import 'package:market_app/data/models/stall_fee_model.dart';
import 'package:market_app/injection_container.dart';
import 'package:market_app/presentation/bloc/tax/tax_bloc.dart';
import 'package:market_app/presentation/bloc/tax/tax_event.dart';
import 'package:market_app/presentation/bloc/tax/tax_state.dart';
import 'tax_receipt_screen.dart';
import 'package:market_app/presentation/widgets/common/market_app_bar.dart';
import 'package:market_app/presentation/widgets/common/market_bottom_nav_bar.dart';
import 'tax_collection_screen.dart';

class TaxHistoryScreen extends StatefulWidget {
  final MarketNavItem currentNav;
  final ValueChanged<MarketNavItem> onNavTap;

  const TaxHistoryScreen({
    super.key,
    required this.currentNav,
    required this.onNavTap,
  });

  @override
  State<TaxHistoryScreen> createState() => _TaxHistoryScreenState();
}

class _TaxHistoryScreenState extends State<TaxHistoryScreen> {
  late DateTime _selectedMonth;
  int _currentPage = 1;
  late TaxBloc _taxBloc;
  String _searchQuery = '';
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _taxBloc = sl<TaxBloc>();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _taxBloc.close();
    super.dispose();
  }

  String get _monthParam => DateFormat('yyyy-MM').format(_selectedMonth);

  void _loadData({int page = 1}) {
    _taxBloc.add(LoadStallFeesEvent(
      month: _monthParam,
      status: 'da_nop',
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      page: page,
    ));
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _currentPage = 1;
        });
        _loadData(page: 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _taxBloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MarketAppBar(title: 'Lịch Sử Thu Tiền', showBack: true),
        body: Column(
          children: [
            // Search & Filter Section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              color: Colors.white,
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm theo tên, mã gian hàng...',
                        hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                        prefixIcon: Icon(Icons.search, color: AppColors.textHint, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Advanced Filters
                  Row(
                    children: [
                      _buildFilterDropdown('Gian hàng', () {}),
                      const SizedBox(width: 8),
                      _buildFilterDropdown('T${_selectedMonth.month.toString().padLeft(2, '0')}', _pickMonth),
                      const SizedBox(width: 8),
                      _buildFilterDropdown('${_selectedMonth.year}', _pickMonth),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // List Section
            Expanded(
              child: BlocBuilder<TaxBloc, TaxState>(
                builder: (context, state) {
                  if (state is TaxLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TaxError) {
                    return Center(child: Text(state.message, textAlign: TextAlign.center));
                  } else if (state is TaxLoaded) {
                    if (state.fees.isEmpty) {
                      return const Center(child: Text('Không tìm thấy dữ liệu phù hợp'));
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.fees.length,
                            itemBuilder: (context, i) => _HistoryCard(fee: state.fees[i]),
                          ),
                        ),
                        if (state.meta.totalPages > 1)
                          _PaginationBar(
                            currentPage: _currentPage,
                            totalPages: state.meta.totalPages,
                            total: state.meta.total,
                            onPrev: _currentPage > 1 ? () {
                              setState(() => _currentPage--);
                              _loadData(page: _currentPage);
                            } : null,
                            onNext: _currentPage < state.meta.totalPages ? () {
                              setState(() => _currentPage++);
                              _loadData(page: _currentPage);
                            } : null,
                          ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            // Footer Section
            BlocBuilder<TaxBloc, TaxState>(
              builder: (context, state) {
                final total = state is TaxLoaded ? state.totalCollected : 0.0;
                final fmt = NumberFormat('#,###', 'vi_VN');
                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Total collected box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng thu tất cả', 
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                            Text('${fmt.format(total.toInt())} VNĐ', 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: MarketBottomNavBar(
          currentItem: widget.currentNav,
          onTap: widget.onNavTap,
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(label, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMonth() async {
    DateTime picked = _selectedMonth;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chọn tháng / năm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SizedBox(
          height: 260,
          width: 300,
          child: YearMonth(
            initial: _selectedMonth,
            onChanged: (d) => picked = d,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedMonth = picked;
                _currentPage = 1;
              });
              _loadData(page: 1);
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}

// ─── Simple month picker ─────────────────────────────────────────────────────
class YearMonth extends StatefulWidget {
  final DateTime initial;
  final ValueChanged<DateTime> onChanged;
  const YearMonth({super.key, required this.initial, required this.onChanged});
  @override
  State<YearMonth> createState() => _YearMonthState();
}

class _YearMonthState extends State<YearMonth> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
    _month = widget.initial.month;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year selector
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                onPressed: () {
                  setState(() => _year--);
                  widget.onChanged(DateTime(_year, _month));
                },
                icon: const Icon(Icons.chevron_left)),
            Text('$_year',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            IconButton(
                onPressed: _year < now.year
                    ? () {
                        setState(() => _year++);
                        widget.onChanged(DateTime(_year, _month));
                      }
                    : null,
                icon: Icon(Icons.chevron_right,
                    color: _year < now.year ? null : Colors.grey.shade300)),
          ]),
          const SizedBox(height: 8),
          // Month grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 1.6,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: List.generate(12, (i) {
              final m = i + 1;
              final selected = m == _month;
              // Block future months in the current year
              final isFuture = _year == now.year && m > now.month;
              return GestureDetector(
                onTap: isFuture
                    ? null
                    : () {
                        setState(() => _month = m);
                        widget.onChanged(DateTime(_year, _month));
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: isFuture
                        ? const Color(0xFFF0F0F0)
                        : selected
                            ? AppColors.primary
                            : const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isFuture
                            ? Colors.grey.shade300
                            : selected
                                ? AppColors.primary
                                : AppColors.border),
                  ),
                  child: Center(
                    child: Text('T${m.toString().padLeft(2, '0')}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isFuture
                                ? Colors.grey.shade400
                                : selected
                                    ? Colors.white
                                    : AppColors.textPrimary)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final StallFeeModel fee;
  const _HistoryCard({required this.fee});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,###', 'vi_VN');
    final dateFmt = DateFormat('dd/MM/yyyy');
    final String paymentDateStr = fee.paymentTime != null ? dateFmt.format(fee.paymentTime!) : 'N/A';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Date Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 6),
                    Text(paymentDateStr, 
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50))),
                  ],
                ),
              ),
              // Amount
              Text('${currencyFmt.format(fee.fee.toInt())} VNĐ', 
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF4CAF50))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fee.userName, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Gian hàng: ${fee.stallId}', 
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Đã thu', 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationBar({required this.currentPage, required this.totalPages, required this.total, this.onPrev, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PageBtn(icon: Icons.chevron_left, onTap: onPrev),
          Text('Trang $currentPage / $totalPages ($total items)', 
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          _PageBtn(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _PageBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: enabled ? Colors.white : AppColors.textHint, size: 20),
      ),
    );
  }
}
