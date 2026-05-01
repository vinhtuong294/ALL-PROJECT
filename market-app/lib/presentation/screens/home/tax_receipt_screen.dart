import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:market_app/core/constants/app_colors.dart';
import 'package:market_app/data/models/stall_fee_model.dart';
import 'package:market_app/injection_container.dart';
import 'package:market_app/presentation/bloc/tax/tax_bloc.dart';
import 'package:market_app/presentation/bloc/tax/tax_event.dart';
import 'package:market_app/presentation/bloc/tax/tax_state.dart';
import 'package:market_app/presentation/widgets/common/market_app_bar.dart';

class TaxReceiptScreen extends StatefulWidget {
  final StallFeeDetailModel? detail;
  final String? feeId;
  final String paymentMethod;
  final String? marketName;

  const TaxReceiptScreen({
    super.key,
    this.detail,
    this.feeId,
    this.paymentMethod = 'Tiền mặt',
    this.marketName,
  }) : assert(detail != null || feeId != null);

  @override
  State<TaxReceiptScreen> createState() => _TaxReceiptScreenState();
}

class _TaxReceiptScreenState extends State<TaxReceiptScreen> {
  late TaxBloc _taxBloc;
  StallFeeDetailModel? _detail;
  final _fmt = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _detail = widget.detail;
    _taxBloc = sl<TaxBloc>();
    if (_detail == null && widget.feeId != null) {
      _taxBloc.add(LoadTaxDetailEvent(feeId: widget.feeId!));
    }
  }

  @override
  void dispose() {
    _taxBloc.close();
    super.dispose();
  }

  void _shareReceipt(StallFeeDetailModel detail) {
    final marketName = (widget.marketName ?? 'CHỢ BẮC MỸ AN').toUpperCase();
    final text = '''
$marketName — Hóa Đơn Thu Tiền Gian Hàng
----------------------------------------
Mã phí:       ${detail.feeId}
Gian hàng:    ${detail.stallName} (${detail.stallId})
Tiểu thương:  ${detail.userName}
Tháng:        ${detail.month}
Số tiền:      ${_fmt.format(detail.fee.toInt())}đ
Thanh toán:   ${widget.paymentMethod}
Trạng thái:   Đã nộp
''';
    Clipboard.setData(ClipboardData(text: text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép hóa đơn vào clipboard'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _taxBloc,
      child: BlocListener<TaxBloc, TaxState>(
        listener: (context, state) {
          if (state is TaxDetailLoaded) {
            setState(() {
              _detail = state.detail;
            });
          }
        },
        child: BlocBuilder<TaxBloc, TaxState>(
          builder: (context, state) {
            final detail = _detail;
            final isLoading = state is TaxLoading && detail == null;

            if (isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (detail == null) {
              return Scaffold(
                appBar: const MarketAppBar(title: 'Hóa Đơn', showBack: true),
                body: const Center(child: Text('Không thể tải thông tin hóa đơn')),
              );
            }

            final dateFormat = DateFormat('dd/MM/yyyy');
            final today = dateFormat.format(DateTime.now());

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: MarketAppBar(
                title: 'Hóa Đơn Thu Tiền',
                showBack: true,
                actions: [
                  IconButton(
                    onPressed: () => _shareReceipt(detail),
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.home, color: AppColors.primary, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          (widget.marketName ?? 'CHỢ BẮC MỸ AN').toUpperCase(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hệ thống quản lý tiền gian hàng',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'HÓA ĐƠN THU TIỀN',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '#${detail.feeId.replaceAll('FE', '')}-${detail.month}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Thông tin gian hàng'),
                        const SizedBox(height: 12),
                        _buildReceiptRow('Tên tiểu thương:', detail.userName),
                        _buildReceiptRow('Số gian hàng:', detail.stallId),
                        _buildReceiptRow('Địa chỉ:', detail.address),
                        _buildReceiptRow('Ngày thu:', today),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Chi tiết thu tiền'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Hạng mục', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                            Text('Số tiền', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textHint)),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildReceiptRow('Tiền gian hàng tháng ${detail.month}', '${_fmt.format(detail.fee.toInt())} VNĐ', isLabelSmall: true),
                        _buildReceiptRow('Phí dịch vụ', '0 VNĐ', isLabelSmall: true),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Text('${_fmt.format(detail.fee.toInt())} VNĐ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Phương thức thanh toán'),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary, size: 24),
                              const SizedBox(width: 12),
                              Text(widget.paymentMethod, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('Người thu', style: TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 12),
                                  Container(height: 60, decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(8))),
                                  const SizedBox(height: 8),
                                  const Text('(Ký và ghi rõ họ tên)', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('Người nộp', style: TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 12),
                                  Container(height: 60, decoration: BoxDecoration(color: const Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(8))),
                                  const SizedBox(height: 8),
                                  const Text('(Ký và ghi rõ họ tên)', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Hóa đơn này là bằng chứng xác nhận đã nộp tiền gian hàng',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFFB45309), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download_rounded, size: 20, color: AppColors.primary),
                        label: const Text('Tải xuống', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8F5E9),
                          elevation: 0,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.print_outlined, size: 20, color: Colors.white),
                        label: const Text('In Hóa Đơn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isLabelSmall = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLabelSmall ? 13 : 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
