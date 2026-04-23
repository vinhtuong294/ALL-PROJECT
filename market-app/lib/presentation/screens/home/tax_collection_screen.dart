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
import 'collect_tax_detail_screen.dart';
import 'tax_history_screen.dart';
import 'package:market_app/presentation/widgets/common/market_app_bar.dart';
import 'package:market_app/presentation/widgets/common/market_bottom_nav_bar.dart';

class TaxCollectionScreen extends StatefulWidget {
  final MarketNavItem currentNav;
  final ValueChanged<MarketNavItem> onNavTap;

  const TaxCollectionScreen({
    super.key,
    required this.currentNav,
    required this.onNavTap,
  });

  @override
  State<TaxCollectionScreen> createState() => _TaxCollectionScreenState();
}

class _TaxCollectionScreenState extends State<TaxCollectionScreen> {
  late DateTime _selectedMonth;
  String _filterStatus = 'Chưa thu'; 
  int _currentPage = 1;
  late TaxBloc _taxBloc;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _taxBloc = sl<TaxBloc>();
    _loadData();
  }

  @override
  void dispose() {
    _taxBloc.close();
    super.dispose();
  }

  String get _monthParam => DateFormat('yyyy-MM').format(_selectedMonth);

  String? get _statusParam {
    if (_filterStatus == 'Đã thu') return 'da_nop';
    if (_filterStatus == 'Chưa thu') return 'chua_nop';
    return null;
  }

  void _loadData({int page = 1}) {
    _taxBloc.add(LoadStallFeesEvent(
      month: _monthParam,
      status: _statusParam,
      page: page,
    ));
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.filter_list, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text('Lọc trạng thái đóng thuế',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textHint, size: 20)),
              ]),
              const Divider(height: 20),
              ...['Tất cả', 'Đã thu', 'Chưa thu'].map((opt) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Radio<String>(
                      value: opt,
                      groupValue: _filterStatus,
                      activeColor: AppColors.primary,
                      onChanged: (v) {
                        setState(() {
                          _filterStatus = v!;
                          _currentPage = 1;
                        });
                        _loadData(page: 1);
                        Navigator.pop(context);
                      },
                    ),
                    title: Text(opt, style: const TextStyle(fontSize: 14)),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _taxBloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MarketAppBar(title: 'Thu Thuế Gian Hàng', showBack: true),
        body: Column(
          children: [
            // Header: month + filter
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tháng/Năm',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _pickMonth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Tháng ${_selectedMonth.month.toString().padLeft(2, '0')}/${_selectedMonth.year}',
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                const Icon(Icons.keyboard_arrow_down,
                                    color: AppColors.textSecondary, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // List
            Expanded(
              child: BlocBuilder<TaxBloc, TaxState>(
                builder: (context, state) {
                  if (state is TaxLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is TaxError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.textHint, size: 48),
                          const SizedBox(height: 8),
                          Text(state.message,
                              style: const TextStyle(color: AppColors.textSecondary),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Thử lại'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    );
                  } else if (state is TaxLoaded) {
                    if (state.fees.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.receipt_long_outlined,
                                size: 48, color: AppColors.textHint),
                            const SizedBox(height: 8),
                            Text(
                              _filterStatus == 'Tất cả'
                                  ? 'Chưa có dữ liệu thu thuế tháng này'
                                  : 'Không có gian hàng "$_filterStatus"',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            itemCount: state.fees.length,
                            itemBuilder: (context, i) =>
                                _TaxCard(fee: state.fees[i], onRefresh: () => _loadData(page: _currentPage)),
                          ),
                        ),
                        if (state.meta.totalPages > 1)
                          _TaxPaginationBar(
                            currentPage: _currentPage,
                            totalPages: state.meta.totalPages,
                            total: state.meta.total,
                            onPrev: _currentPage > 1
                                ? () {
                                    setState(() => _currentPage--);
                                    _loadData(page: _currentPage);
                                  }
                                : null,
                            onNext: _currentPage < state.meta.totalPages
                                ? () {
                                    setState(() => _currentPage++);
                                    _loadData(page: _currentPage);
                                  }
                                : null,
                          ),
                        const SizedBox(height: 4),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Footer: total collected
            BlocBuilder<TaxBloc, TaxState>(
              builder: (context, state) {
                final total = state is TaxLoaded ? state.totalCollected : 0.0;
                final fmt = NumberFormat('#,###', 'vi_VN');
                return Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                        top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng thu tháng này',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                            Text(
                              '${fmt.format(total.toInt())} VNĐ',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaxHistoryScreen(
                                  currentNav: widget.currentNav,
                                  onNavTap: widget.onNavTap,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.history, size: 20),
                          label: const Text('Lịch sử thu thuế', 
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
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
}

// ─── Tax Card ───────────────────────────────────────────────────────────────
class _TaxCard extends StatelessWidget {
  final StallFeeModel fee;
  final VoidCallback onRefresh;
  const _TaxCard({required this.fee, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###', 'vi_VN');
    return GestureDetector(
      onTap: () async {
        if (fee.isPaid) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaxReceiptScreen(
                feeId: fee.feeId,
              ),
            ),
          );
          return;
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CollectTaxDetailScreen(
              feeId: fee.feeId ?? '',
              initialData: {
                'name': fee.userName,
                'stall': fee.stallId,
                'amount': fee.fee,
              },
            ),
          ),
        );
        if (result == true) {
          onRefresh();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.storefront,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fee.userName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Gian hàng: ${fee.stallId}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${fmt.format(fee.fee.toInt())} VNĐ',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50)),
                ),
                const SizedBox(height: 6),
                _StatusBadge(isPaid: fee.isPaid),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isPaid;
  const _StatusBadge({required this.isPaid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isPaid ? 'Đã thu' : 'Chưa thu',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isPaid ? const Color(0xFF065F46) : const Color(0xFF92400E),
        ),
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

// ─── Pagination Bar ──────────────────────────────────────────────────────────
class _TaxPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int total;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _TaxPaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.total,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _TaxPageButton(icon: Icons.chevron_left, onTap: onPrev, enabled: onPrev != null),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trang $currentPage / $totalPages',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              Text(
                'Tổng: $total gian hàng',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          _TaxPageButton(icon: Icons.chevron_right, onTap: onNext, enabled: onNext != null),
        ],
      ),
    );
  }
}

class _TaxPageButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _TaxPageButton({required this.icon, required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: enabled ? Colors.white : AppColors.textHint, size: 22),
      ),
    );
  }
}
