import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market_app/core/constants/app_colors.dart';
import 'package:market_app/injection_container.dart';
import 'package:market_app/presentation/bloc/merchant/merchant_bloc.dart';
import 'package:market_app/presentation/bloc/merchant/merchant_event.dart';
import 'package:market_app/presentation/bloc/merchant/merchant_state.dart';
import 'package:market_app/presentation/widgets/common/market_app_bar.dart';
import 'package:market_app/presentation/widgets/common/market_bottom_nav_bar.dart';
import '../../../data/models/goods_category_model.dart';

class AddVendorScreen extends StatefulWidget {
  final MarketNavItem currentNav;
  final ValueChanged<MarketNavItem> onNavTap;

  const AddVendorScreen({
    super.key,
    required this.currentNav,
    required this.onNavTap,
  });

  @override
  State<AddVendorScreen> createState() => _AddVendorScreenState();
}

class _AddVendorScreenState extends State<AddVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _taxCtrl = TextEditingController(text: '500000');
  final _notesCtrl = TextEditingController();
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
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _taxCtrl.dispose();
    _notesCtrl.dispose();
    _gridColCtrl.dispose();
    _gridRowCtrl.dispose();
    super.dispose();
  }

  void _showSuccessDialog(BuildContext ctx, AddMerchantSuccess state) {
    final loginName = state.loginName ?? '(không xác định)';
    final password = state.defaultPassword ?? '123456';
    final stallId = state.stallId ?? '(tự sinh)';
    final stallName = state.stallName ?? '';
    final loaiHang = state.loaiHangHoa ?? '';
    final copyText = 'Tên đăng nhập: $loginName\nMật khẩu: $password\nMã sạp: $stallId';

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header xanh lá ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Tạo tài khoản thành công!',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cung cấp thông tin sau cho tiểu thương:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  // ─── Thông tin đăng nhập ───────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FFF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _credRow(Icons.phone_outlined, 'Tên đăng nhập (SĐT)', loginName),
                        const SizedBox(height: 10),
                        _credRow(Icons.lock_outline, 'Mật khẩu mặc định', password),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ─── Thông tin gian hàng ───────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F8FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _credRow(Icons.storefront_outlined, 'Mã gian hàng (tự sinh)', stallId),
                        if (stallName.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _credRow(Icons.label_outline, 'Tên gian hàng', stallName),
                        ],
                        if (loaiHang.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _credRow(Icons.category_outlined, 'Loại hàng', loaiHang),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '⚠️ Tiểu thương nên đổi mật khẩu ngay sau khi đăng nhập lần đầu.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Sao chép'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: copyText));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Đã sao chép thông tin tài khoản!'),
                  backgroundColor: AppColors.primary,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(ctx); // back to vendor list
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  Widget _credRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.1)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _merchantBloc,
      child: BlocListener<MerchantBloc, MerchantState>(
        listener: (context, state) {
          if (state is AddMerchantSuccess) {
            _showSuccessDialog(context, state);
          } else if (state is AddMerchantError) {
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
            title: 'Thêm Tiểu Thương Mới',
            showBack: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ─── Thông tin tiểu thương ─────────────────────────────
                    _buildSection(
                      title: 'Thông tin tiểu thương',
                      icon: Icons.person_outline,
                      children: [
                        _buildLabel('Tên tiểu thương *'),
                        _buildTextField(
                          controller: _nameCtrl,
                          hintText: 'Nhập tên đầy đủ',
                          icon: Icons.person_outline,
                          validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập tên' : null,
                        ),
                        const SizedBox(height: 14),
                        _buildLabel('Số điện thoại *'),
                        _buildTextField(
                          controller: _phoneCtrl,
                          hintText: 'Nhập số điện thoại',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập SĐT' : null,
                        ),
                        const SizedBox(height: 6),
                        // Gợi ý: SĐT sẽ là tên đăng nhập
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'SĐT này sẽ là tên đăng nhập của tiểu thương',
                                  style: TextStyle(fontSize: 12, color: AppColors.primary.withOpacity(0.85)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildLabel('Địa chỉ *'),
                        _buildTextField(
                          controller: _addressCtrl,
                          hintText: 'Nhập địa chỉ',
                          icon: Icons.location_on_outlined,
                          validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập địa chỉ' : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // ─── Thông tin gian hàng ────────────────────────────
                    _buildSection(
                      title: 'Thông tin gian hàng',
                      icon: Icons.storefront_outlined,
                      children: [
                        _buildLabel('Loại hàng hóa *'),
                        _isLoadingCategories ? const LinearProgressIndicator() : _buildDropdown(),
                        const SizedBox(height: 14),
                        _buildLabel('Tiền gian hàng mặc định/tháng *'),
                        _buildTextField(
                          controller: _taxCtrl,
                          hintText: '500000',
                          icon: Icons.monetization_on_outlined,
                          suffix: const Text('VNĐ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập tiền thuê' : null,
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
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Xem tab "Bản đồ chợ" để xác định vị trí. X = số cột từ trái sang (bắt đầu từ 0), Y = số hàng từ trên xuống (bắt đầu từ 0).',
                                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // ─── Ghi chú ────────────────────────────────────────
                    _buildSection(
                      title: 'Ghi chú',
                      icon: Icons.notes_outlined,
                      children: [
                        _buildTextField(
                          controller: _notesCtrl,
                          hintText: 'Nhập ghi chú bổ sung (tùy chọn)...',
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: BlocBuilder<MerchantBloc, MerchantState>(
                    builder: (context, state) {
                      final isLoading = state is AddMerchantLoading;
                      return ElevatedButton.icon(
                        onPressed: isLoading ? null : () {
                          if (_formKey.currentState!.validate()) {
                            _merchantBloc.add(AddMerchantEvent(
                              tenNguoiDung: _nameCtrl.text.trim(),
                              diaChi: _addressCtrl.text.trim(),
                              soDienThoai: _phoneCtrl.text.trim(),
                              loaiHangHoa: _selectedGoodsType!,
                              tienThueMacDinh: double.tryParse(_taxCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
                              ghiChu: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                              gridCol: int.tryParse(_gridColCtrl.text) ?? 0,
                              gridRow: int.tryParse(_gridRowCtrl.text) ?? 0,
                            ));
                          }
                        },
                        icon: isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check, size: 24),
                        label: Text(
                          isLoading ? 'Đang lưu...' : 'Lưu & Thêm',
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
              MarketBottomNavBar(
                currentItem: widget.currentNav,
                onTap: widget.onNavTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
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
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
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
    int maxLines = 1,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 22) : null,
        suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.all(12), child: suffix) : null,
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator ?? (value) {
        if (hintText.contains('*') || (hintText.contains('Nhập') && !hintText.contains('tùy chọn'))) {
           if (value == null || value.isEmpty) {
             return 'Vui lòng không để trống';
           }
        }
        return null;
      },
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGoodsType,
      decoration: InputDecoration(
        hintText: 'Chọn loại hàng hóa',
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        prefixIcon: Icon(Icons.category_outlined, color: AppColors.primary.withOpacity(0.7), size: 22),
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: _categories.map((cat) {
        return DropdownMenuItem(
          value: cat.ma,
          child: Text(cat.ten),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGoodsType = value;
        });
      },
      validator: (value) => value == null ? 'Vui lòng chọn loại hàng hóa' : null,
    );
  }
}
