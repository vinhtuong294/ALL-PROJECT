import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_app/core/constants/app_colors.dart';
import 'package:market_app/data/models/merchant_model.dart';
import 'package:market_app/presentation/bloc/merchant/merchant_bloc.dart';
import 'package:market_app/presentation/bloc/merchant/merchant_event.dart';
import 'package:market_app/presentation/bloc/merchant/merchant_state.dart';
import 'package:market_app/presentation/widgets/common/market_app_bar.dart';
import 'package:market_app/presentation/widgets/common/market_bottom_nav_bar.dart';
import 'package:market_app/injection_container.dart';
import 'add_vendor_screen.dart';
import 'tax_receipt_screen.dart';
import 'account_history_screen.dart';

class VendorListScreen extends StatefulWidget {
  final MarketNavItem currentNav;
  final ValueChanged<MarketNavItem> onNavTap;

  const VendorListScreen({
    super.key,
    required this.currentNav,
    required this.onNavTap,
  });

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final _searchCtrl = TextEditingController();
  String _filterStatus = 'Tất cả';
  final List<String> _filterOptions = ['Tất cả', 'Hoạt động', 'Tạm nghỉ'];
  int _currentPage = 1;
  late MerchantBloc _merchantBloc;

  @override
  void initState() {
    super.initState();
    _merchantBloc = sl<MerchantBloc>()..add(const GetMerchantsEvent());
  }

  void _onSearchChanged(String query) {
    _currentPage = 1;
    _triggerFetch(page: 1);
  }

  void _triggerFetch({int page = 1}) {
    String? statusParam;
    if (_filterStatus == 'Hoạt động') statusParam = 'hoat_dong';
    if (_filterStatus == 'Tạm nghỉ') statusParam = 'tam_nghi';
    
    _merchantBloc.add(GetMerchantsEvent(
      search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      status: statusParam,
      page: page,
    ));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
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
          title: const Text(
            'Quản lý Tiểu Thương',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history_edu, color: Colors.white),
              tooltip: 'Lịch sử tạo tài khoản',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountHistoryScreen()),
                );
              },
            ),
          ],
        ),
        body: _buildMainContent(context),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddVendorSheet(),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Thêm Tiểu Thương Mới',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            MarketBottomNavBar(
              currentItem: widget.currentNav,
              onTap: widget.onNavTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => _onSearchChanged(v),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên, số gian hàng...',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textHint, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7FAFC),
                ),
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => _showFilterSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_filterStatus,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textPrimary)),
                        const Icon(Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: BlocBuilder<MerchantBloc, MerchantState>(
            buildWhen: (prev, curr) => curr is MerchantLoading || curr is MerchantLoaded || curr is MerchantError,
            builder: (context, state) {
              if (state is MerchantLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is MerchantError) {
                return Center(child: Text(state.message));
              } else if (state is MerchantLoaded) {
                final merchants = state.merchants;
                final meta = state.meta;
                if (merchants.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48, color: AppColors.textHint),
                        SizedBox(height: 8),
                        Text('Không tìm thấy tiểu thương',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                        itemCount: merchants.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _VendorCard(
                          merchant: merchants[i],
                          onTap: () {
                            if (merchants[i].isTaxPaid) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TaxReceiptScreen(
                                    feeId: merchants[i].feeId,
                                  ),
                                ),
                              );
                            } else {
                              _showVendorDetail(merchants[i]);
                            }
                          },
                        ),
                      ),
                    ),
                    if (meta.totalPages > 1)
                      _PaginationBar(
                        currentPage: _currentPage,
                        totalPages: meta.totalPages,
                        total: meta.total,
                        onPrev: _currentPage > 1
                            ? () {
                                setState(() => _currentPage--);
                                _triggerFetch(page: _currentPage);
                              }
                            : null,
                        onNext: _currentPage < meta.totalPages
                            ? () {
                                setState(() => _currentPage++);
                                _triggerFetch(page: _currentPage);
                              }
                            : null,
                      ),
                    const SizedBox(height: 8),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }


  void _showFilterSheet(BuildContext context) {
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
              Row(
                children: [
                  const Icon(Icons.filter_list, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  const Text('Lọc theo trạng thái',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.textHint, size: 20),
                  ),
                ],
              ),
              const Divider(height: 24),
              ..._filterOptions.map((opt) => ListTile(
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
                    _triggerFetch(page: 1);
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

  void _showVendorDetail(MerchantModel v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: Center(
                  child: Text(v.initial,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary))),
            ),
            const SizedBox(height: 12),
            Text(v.userName,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            _StatusBadge(isActive: v.isActive),
            const SizedBox(height: 20),
            _DetailRow(icon: Icons.storefront_outlined,
                label: 'Mã gian hàng', value: v.stallId ?? 'Chưa có'),
            _DetailRow(icon: Icons.store_outlined,
                label: 'Tên gian hàng', value: v.stallName ?? 'Chưa có'),
            _DetailRow(icon: Icons.location_on_outlined,
                label: 'Vị trí', value: v.stallLocation ?? 'Chưa có'),
            if (v.sdt != null)
              _DetailRow(icon: Icons.phone_android,
                  label: 'Tài khoản (SĐT)', value: v.sdt!),
            _DetailRow(icon: Icons.password_outlined,
                label: 'Mật khẩu', value: '123456 (Mặc định)'),
            if (v.ngayTao != null)
              _DetailRow(icon: Icons.calendar_today,
                  label: 'Ngày tạo', value: v.ngayTao != null ? v.ngayTao!.split('-').reversed.join('/') : ''),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(0, 44)),
                  child: const Text('Đóng'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(0, 44)),
                  child: const Text('Chỉnh sửa'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAddVendorSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddVendorScreen(
          currentNav: widget.currentNav,
          onNavTap: widget.onNavTap,
        ),
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  final MerchantModel merchant;
  final VoidCallback onTap;

  const _VendorCard({required this.merchant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle),
              child: Center(
                child: Text(
                  merchant.initial,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(merchant.userName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Gian hàng: ${merchant.stallId ?? "Chưa có"}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),

            _StatusBadge(isActive: merchant.isActive),
            if (merchant.isTaxPaid) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Đã nộp thuế',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFD1FAE5)
            : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Hoạt động' : 'Tạm nghỉ',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive
              ? const Color(0xFF059669)
              : const Color(0xFFDC2626),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text('$label:',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
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

  const _PaginationBar({
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Prev button
          _PageButton(
            icon: Icons.chevron_left,
            onTap: onPrev,
            enabled: onPrev != null,
          ),

          // Page info
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trang $currentPage / $totalPages',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Tổng: $total tiểu thương',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // Next button
          _PageButton(
            icon: Icons.chevron_right,
            onTap: onNext,
            enabled: onNext != null,
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const _PageButton({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

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
        child: Icon(
          icon,
          color: enabled ? Colors.white : AppColors.textHint,
          size: 22,
        ),
      ),
    );
  }
}
