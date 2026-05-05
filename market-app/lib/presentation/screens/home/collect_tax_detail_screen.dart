import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:market_app/core/constants/app_colors.dart';
import 'package:market_app/data/models/stall_fee_model.dart';
import 'package:market_app/injection_container.dart';
import 'package:market_app/presentation/bloc/dashboard/dashboard_bloc.dart';
import 'package:market_app/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:market_app/presentation/bloc/tax/tax_bloc.dart';
import 'package:market_app/presentation/bloc/tax/tax_event.dart';
import 'package:market_app/presentation/bloc/tax/tax_state.dart';
import 'tax_receipt_screen.dart';
import 'package:market_app/presentation/widgets/common/market_app_bar.dart';

class CollectTaxDetailScreen extends StatefulWidget {
  final String feeId;
  final Map<String, dynamic> initialData;

  const CollectTaxDetailScreen({
    super.key,
    required this.feeId,
    required this.initialData,
  });

  @override
  State<CollectTaxDetailScreen> createState() => _CollectTaxDetailScreenState();
}

class _CollectTaxDetailScreenState extends State<CollectTaxDetailScreen> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  String _paymentMethod = 'Tiền mặt';
  final _fmt = NumberFormat('#,###', 'vi_VN');
  late TaxBloc _taxBloc;
  StallFeeDetailModel? _detailData;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
        text: _fmt.format((widget.initialData['amount'] as num).toInt()));
    _noteController = TextEditingController();
    _taxBloc = sl<TaxBloc>();
    if (widget.feeId.isNotEmpty) {
      _taxBloc.add(LoadTaxDetailEvent(feeId: widget.feeId));
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (widget.feeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Không tìm thấy mã định danh hóa đơn (fee_id). Vui lòng thử lại sau.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ??
        (widget.initialData['amount'] as num).toDouble();
    _taxBloc.add(ConfirmTaxPaymentEvent(
      feeId: widget.feeId,
      paymentMethod: _paymentMethod,
      amount: amount,
      note: _noteController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaxBloc, TaxState>(
      bloc: _taxBloc,
      listener: (context, state) {
        if (state is TaxPaymentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.green),
          );
          final collectedAmount = double.tryParse(_amountController.text.replaceAll('.', ''))
              ?? (_detailData?.fee ?? (widget.initialData['amount'] as num).toDouble());
          final dashState = context.read<DashboardBloc>().state;
          final marketName = dashState is DashboardSuccess ? dashState.stats.marketName : null;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TaxReceiptScreen(
                detail: _detailData?.copyWith(fee: collectedAmount, feeStatus: 'da_nop'),
                feeId: _detailData == null ? widget.feeId : null,
                paymentMethod: _paymentMethod,
                marketName: marketName,
              ),
            ),
          );
        } else if (state is TaxError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        } else if (state is TaxDetailLoaded) {
          setState(() {
            _detailData = state.detail;
            _amountController.text = _fmt.format(state.detail.fee.toInt());
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const MarketAppBar(
          title: 'Thu Tiền Gian Hàng',
          showBack: true,
        ),
        body: BlocBuilder<TaxBloc, TaxState>(
          bloc: _taxBloc,
          builder: (context, state) {
            final isLoading = state is TaxLoading;
            final data = _detailData;

            return Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thông tin gian hàng',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoSection(data),
                        const SizedBox(height: 24),
                        const Text(
                          'Thông tin thu tiền',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        _buildFormSection(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
                if (isLoading) const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),
        bottomSheet: _buildBottomSheet(),
      ),
    );
  }

  Widget _buildInfoSection(StallFeeDetailModel? data) {
    final Map<String, dynamic> initial = widget.initialData;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow('Tên tiểu thương',
              data?.userName ?? initial['name'] as String? ?? ''),
          const Divider(height: 32),
          _buildInfoRow(
              'Số gian hàng', data?.stallId ?? initial['stall'] as String? ?? ''),
          const Divider(height: 32),
          _buildInfoRow('Địa chỉ', data?.address ?? 'Chợ Bắc Mỹ An, Đà Nẵng'),
          const Divider(height: 32),
          _buildInfoRow('Tiền mặc định',
              '${_fmt.format((data?.fee ?? (initial['amount'] as num).toDouble()).toInt())} VNĐ',
              isHighlight: true),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormLabel('Số tiền thu thực tế *'),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.monetization_on_outlined,
                  color: AppColors.primary, size: 20),
              suffixText: 'VNĐ',
              suffixStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF7FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          _buildFormLabel('Phương thức thanh toán *'),
          _buildDropdownField(
            value: _paymentMethod,
            icon: Icons.account_balance_wallet_outlined,
            items: ['Tiền mặt', 'Chuyển khoản'],
            onChanged: (val) => setState(() => _paymentMethod = val!),
          ),
          const SizedBox(height: 20),
          _buildFormLabel('Ghi chú'),
          TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú (tùy chọn)...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
              filled: true,
              fillColor: const Color(0xFFF7FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thu',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              Text(
                '${_amountController.text} VNĐ',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_detailData != null && _detailData!.feeStatus == 'da_nop') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gian hàng này đã nộp tiền')),
                );
                return;
              }
              _onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Xác Nhận Thu & Lưu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.textSecondary),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(item,
                      style:
                          const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
