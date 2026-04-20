import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_app/core/constants/app_colors.dart';
import 'package:market_app/injection_container.dart';
import 'package:market_app/presentation/bloc/merchant/merchant_bloc.dart';
import 'package:market_app/presentation/bloc/merchant/merchant_event.dart';
import 'package:market_app/presentation/bloc/merchant/merchant_state.dart';
import 'package:market_app/presentation/widgets/common/market_app_bar.dart';
import '../../../data/models/goods_category_model.dart';
import '../../../data/models/merchant_model.dart';

class ApproveVendorScreen extends StatefulWidget {
  final MerchantModel merchant;

  const ApproveVendorScreen({
    super.key,
    required this.merchant,
  });

  @override
  State<ApproveVendorScreen> createState() => _ApproveVendorScreenState();
}

class _ApproveVendorScreenState extends State<ApproveVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _stallNameCtrl = TextEditingController();
  final _taxCtrl = TextEditingController(text: '500000');
  final _gridColCtrl = TextEditingController(text: '0');
  final _gridRowCtrl = TextEditingController(text: '0');

  String? _selectedGoodsType;
  List<GoodsCategoryModel> _categories = [];
  late MerchantBloc _merchantBloc;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _merchantBloc = sl<MerchantBloc>();
    _merchantBloc.add(GetGoodsCategoriesEvent());
  }

  @override
  void dispose() {
    _stallNameCtrl.dispose();
    _taxCtrl.dispose();
    _gridColCtrl.dispose();
    _gridRowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _merchantBloc,
      child: BlocListener<MerchantBloc, MerchantState>(
        listener: (context, state) {
          if (state is ApproveMerchantSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tạo gian hàng thành công!'), backgroundColor: AppColors.primary),
            );
            Navigator.pop(context, true);
          } else if (state is ApproveMerchantError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is GoodsCategoriesLoaded) {
            setState(() {
              _categories = state.categories;
              _isLoadingCategories = false;
            });
          } else if (state is MerchantError) {
             setState(() {
              _isLoadingCategories = false;
            });
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: const MarketAppBar(
            title: 'Duyệt Tiểu Thương',
            showBack: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ─── Thông tin tiểu thương đã đăng ký ─────────────────────────────
                    _buildSection(
                      title: 'Thông tin người bán',
                      icon: Icons.person_outline,
                      children: [
                        _buildInfoRow('Tên:', widget.merchant.displayName),
                        const SizedBox(height: 8),
                        _buildInfoRow('SĐT:', widget.merchant.sdt ?? 'Không có'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // ─── Thông tin gian hàng ────────────────────────────
                    _buildSection(
                      title: 'Cấp gian hàng',
                      icon: Icons.storefront_outlined,
                      children: [
                        _buildLabel('Tên gian hàng *'),
                         _buildTextField(
                          controller: _stallNameCtrl,
                          hintText: 'VD: Sạp rau cô Thanh',
                          icon: Icons.store_outlined,
                        ),
                        const SizedBox(height: 14),
                        _buildLabel('Loại hàng hóa *'),
                        _isLoadingCategories ? const LinearProgressIndicator() : _buildDropdown(),
                        const SizedBox(height: 14),
                        _buildLabel('Tiền thuế mặc định/tháng *'),
                        _buildTextField(
                          controller: _taxCtrl,
                          hintText: '500000',
                          icon: Icons.monetization_on_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // ─── Toạ độ sơ đồ chợ ──────────────────────────────
                    _buildSection(
                      title: 'Toạ độ trên sơ đồ chợ',
                      icon: Icons.grid_on_outlined,
                      subtitle: 'Xác định vị trí sạp để hiển thị trên bản đồ',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Toạ độ X (Cột)'),
                                  _buildTextField(
                                    controller: _gridColCtrl,
                                    hintText: '0',
                                    icon: Icons.swap_horiz,
                                    keyboardType: TextInputType.number,
                                    validator: (v) => null, // Optional
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Toạ độ Y (Hàng)'),
                                  _buildTextField(
                                    controller: _gridRowCtrl,
                                    hintText: '0',
                                    icon: Icons.swap_vert,
                                    keyboardType: TextInputType.number,
                                    validator: (v) => null, // Optional
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: BlocBuilder<MerchantBloc, MerchantState>(
                  builder: (context, state) {
                    final isLoading = state is ApproveMerchantLoading;
                    return ElevatedButton.icon(
                      onPressed: isLoading ? null : () {
                        if (_formKey.currentState!.validate()) {
                          _merchantBloc.add(RegisterStallEvent(
                            userId: widget.merchant.userId,
                            tenGianHang: _stallNameCtrl.text.trim(),
                            loaiHangHoa: _selectedGoodsType!,
                            gridCol: int.tryParse(_gridColCtrl.text) ?? 0,
                            gridRow: int.tryParse(_gridRowCtrl.text) ?? 0,
                          ));
                        }
                      },
                      icon: isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_outline, size: 24),
                      label: Text(
                        isLoading ? 'Đang duyệt...' : 'Duyệt & Tạo gian hàng',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 22) : null,
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: Colors.red, width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator ?? (value) => (value == null || value.isEmpty) ? 'Vui lòng không để trống' : null,
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGoodsType,
      decoration: InputDecoration(
        hintText: 'Chọn loại hàng hóa',
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: _categories.map((cat) => DropdownMenuItem(value: cat.ma, child: Text(cat.ten))).toList(),
      onChanged: (val) => setState(() => _selectedGoodsType = val),
      validator: (val) => val == null ? 'Vui lòng chọn loại hàng hóa' : null,
    );
  }
}
