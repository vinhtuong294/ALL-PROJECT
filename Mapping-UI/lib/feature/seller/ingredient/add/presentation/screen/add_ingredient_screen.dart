import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../cubit/add_ingredient_cubit.dart';
import '../cubit/add_ingredient_state.dart';

class AddIngredientScreen extends StatelessWidget {
  const AddIngredientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddIngredientCubit()..initialize(),
      child: const _AddIngredientView(),
    );
  }
}

class _AddIngredientView extends StatefulWidget {
  const _AddIngredientView();

  @override
  State<_AddIngredientView> createState() => _AddIngredientViewState();
}

class _AddIngredientViewState extends State<_AddIngredientView> {
  final _tenNguyenLieuController = TextEditingController();
  final _giaGocController = TextEditingController();
  final _soLuongBanController = TextEditingController();
  final _phanTramGiamGiaController = TextEditingController(text: '0');

  @override
  void dispose() {
    _tenNguyenLieuController.dispose();
    _giaGocController.dispose();
    _soLuongBanController.dispose();
    _phanTramGiamGiaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocConsumer<AddIngredientCubit, AddIngredientState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
            context.read<AddIngredientCubit>().clearMessages();
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: const Color(0xFF2F8000),
              ),
            );
            context.read<AddIngredientCubit>().clearMessages();
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2F8000),
              ),
            );
          }

          return Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildImageUploadSection(context, state),
                      const SizedBox(height: 20),
                      _buildIngredientSection(context, state),
                      const SizedBox(height: 20),
                      _buildPricingSection(context, state),
                      const SizedBox(height: 20),
                      _buildDiscountSection(context, state),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(context, state),
            ],
          );
        },
      ),
    );
  }

  /// Header với nút back và title
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: SvgPicture.asset(
                'assets/img/seller_back_arrow.svg',
                width: 40,
                height: 40,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF1A202C),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const Text(
            'Thêm Nguyên liệu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }

  /// Section upload ảnh
  Widget _buildImageUploadSection(BuildContext context, AddIngredientState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ảnh sản phẩm',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thêm tối đa 5 ảnh để tăng cơ hội bán hàng',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(height: 14),
          
          if (state.selectedImages.isEmpty)
            _buildUploadBox(context)
          else
            _buildImageGrid(context, state),
        ],
      ),
    );
  }

  Widget _buildUploadBox(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF7FAFC),
              Color(0xFFEDF2F7),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF2F8000),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/img/seller_upload_icon.svg',
                  width: 32,
                  height: 32,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tải lên ảnh sản phẩm',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF4A5568),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tối đa 5 ảnh, mỗi ảnh không quá 5MB',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Color(0xFFA0AEC0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context, AddIngredientState state) {
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: state.selectedImages.length + (state.canAddMoreImages ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < state.selectedImages.length) {
              return _buildImageItem(context, state.selectedImages[index], index);
            } else {
              return _buildAddImageButton(context);
            }
          },
        ),
        const SizedBox(height: 8),
        Text(
          '${state.imageCount}/5 ảnh',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }

  Widget _buildImageItem(BuildContext context, dynamic image, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            image,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => context.read<AddIngredientCubit>().removeImage(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            size: 32,
            color: Color(0xFF718096),
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn nguồn ảnh',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF2F8000)),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<AddIngredientCubit>().pickImages();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2F8000)),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<AddIngredientCubit>().takePhoto();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Section chọn nguyên liệu
  Widget _buildIngredientSection(BuildContext context, AddIngredientState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin Nguyên liệu',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 14),
          
          // Nhóm nguyên liệu (từ API)
          _buildDropdownField(
            label: 'Nhóm nguyên liệu *',
            hint: 'Chọn nhóm nguyên liệu',
            value: state.selectedNhomNguyenLieu?.tenNhomNguyenLieu,
            onTap: () => _showNhomNguyenLieuPicker(context, state),
          ),
          const SizedBox(height: 14),
          
          // Nguyên liệu theo nhóm (hiển thị sau khi chọn nhóm)
          _buildNguyenLieuDropdown(context, state),
          const SizedBox(height: 14),
          
          // // Danh mục nguyên liệu
          // _buildDropdownField(
          //   label: 'Danh mục *',
          //   hint: 'Chọn danh mục nguyên liệu',
          //   value: state.selectedCategory?.name,
          //   onTap: () => _showCategoryPicker(context, state),
          // ),
        ],
      ),
    );
  }

  /// Dropdown chọn nguyên liệu theo nhóm
  Widget _buildNguyenLieuDropdown(BuildContext context, AddIngredientState state) {
    // Nếu chưa chọn nhóm, hiển thị disabled
    if (state.selectedNhomNguyenLieu == null) {
      return _buildDropdownField(
        label: 'Nguyên liệu *',
        hint: 'Vui lòng chọn nhóm nguyên liệu trước',
        value: null,
        onTap: () {},
        enabled: false,
      );
    }

    // Nếu đang load
    if (state.isLoadingNguyenLieu) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nguyên liệu *',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Color(0xFF4A5568),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2F8000),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Đang tải nguyên liệu...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFFA0AEC0),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Hiển thị dropdown nguyên liệu
    return _buildDropdownField(
      label: 'Nguyên liệu *',
      hint: 'Chọn nguyên liệu',
      value: state.selectedNguyenLieuTheoNhom?.tenNguyenLieu,
      onTap: () => _showNguyenLieuPicker(context, state),
    );
  }

  /// Section giá và số lượng
  Widget _buildPricingSection(BuildContext context, AddIngredientState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Giá và Số lượng',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 14),
          
          // Row: Giá gốc + Đơn vị bán
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Giá gốc (VNĐ) *',
                  hint: 'Nhập giá bán',
                  controller: _giaGocController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    context.read<AddIngredientCubit>().updateGiaGoc(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdownField(
                  label: 'Đơn vị bán *',
                  hint: 'Chọn đơn vị',
                  value: state.donViBan,
                  onTap: () => _showUnitPicker(context, state),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Số lượng bán
          _buildInputField(
            label: 'Số lượng bán *',
            hint: 'Nhập số lượng có thể bán',
            controller: _soLuongBanController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              context.read<AddIngredientCubit>().updateSoLuongBan(value);
            },
          ),
        ],
      ),
    );
  }

  /// Section giảm giá
  Widget _buildDiscountSection(BuildContext context, AddIngredientState state) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Khuyến mãi',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF1A202C),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Tùy chọn',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Phần trăm giảm giá
          _buildInputField(
            label: 'Phần trăm giảm giá (%)',
            hint: 'Nhập % giảm giá (0-100)',
            controller: _phanTramGiamGiaController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              context.read<AddIngredientCubit>().updatePhanTramGiamGia(value);
            },
          ),
          const SizedBox(height: 14),
          
          // Thời gian bắt đầu giảm
          _buildDateTimeField(
            label: 'Thời gian bắt đầu giảm',
            hint: 'Chọn ngày bắt đầu',
            value: state.thoiGianBatDauGiam != null 
                ? dateFormat.format(state.thoiGianBatDauGiam!) 
                : null,
            onTap: () => _showDateTimePicker(
              context, 
              state.thoiGianBatDauGiam,
              (dateTime) {
                context.read<AddIngredientCubit>().updateThoiGianBatDauGiam(dateTime);
              },
            ),
          ),
          const SizedBox(height: 14),
          
          // Thời gian kết thúc giảm
          _buildDateTimeField(
            label: 'Thời gian kết thúc giảm',
            hint: 'Chọn ngày kết thúc',
            value: state.thoiGianKetThucGiam != null 
                ? dateFormat.format(state.thoiGianKetThucGiam!) 
                : null,
            onTap: () => _showDateTimePicker(
              context, 
              state.thoiGianKetThucGiam,
              (dateTime) {
                context.read<AddIngredientCubit>().updateThoiGianKetThucGiam(dateTime);
              },
            ),
          ),
          
          // Hiển thị giá sau giảm
          if (state.hasDiscount && state.giaGoc.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Color(0xFFE53935), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Giá sau giảm: ${_calculateDiscountedPrice(state.giaGoc, state.phanTramGiamGia)}đ',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _calculateDiscountedPrice(String giaGoc, String phanTram) {
    final price = double.tryParse(giaGoc) ?? 0;
    final discount = double.tryParse(phanTram) ?? 0;
    final discountedPrice = price * (1 - discount / 100);
    return NumberFormat('#,###').format(discountedPrice.round());
  }

  /// Input field widget
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? helperText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF1A202C),
            ),
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFFA0AEC0),
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 11,
              color: Color(0xFFA0AEC0),
            ),
          ),
        ],
      ],
    );
  }

  /// Dropdown field widget
  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: enabled ? const Color(0xFF4A5568) : const Color(0xFFA0AEC0),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: enabled ? const Color(0xFFF7FAFC) : const Color(0xFFEDF2F7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: value != null
                          ? const Color(0xFF1A202C)
                          : const Color(0xFFA0AEC0),
                    ),
                  ),
                ),
                SvgPicture.asset(
                  'assets/img/seller_dropdown_arrow.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    enabled ? const Color(0xFFA0AEC0) : const Color(0xFFCBD5E0),
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// DateTime field widget
  Widget _buildDateTimeField({
    required String label,
    required String hint,
    required String? value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: value != null
                          ? const Color(0xFF1A202C)
                          : const Color(0xFFA0AEC0),
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Color(0xFFA0AEC0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Show date time picker
  Future<void> _showDateTimePicker(
    BuildContext context, 
    DateTime? initialDate,
    Function(DateTime) onSelected,
  ) async {
    final now = DateTime.now();
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2F8000),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate ?? now),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF2F8000),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year, date.month, date.day,
          time.hour, time.minute,
        );
        onSelected(dateTime);
      }
    }
  }

  /// Nhóm nguyên liệu picker dialog
  void _showNhomNguyenLieuPicker(BuildContext context, AddIngredientState state) {
    final cubit = context.read<AddIngredientCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn nhóm nguyên liệu',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.nhomNguyenLieuList.length,
                  itemBuilder: (_, index) {
                    final nhom = state.nhomNguyenLieuList[index];
                    final isSelected = state.selectedNhomNguyenLieu?.maNhomNguyenLieu == nhom.maNhomNguyenLieu;
                    return ListTile(
                      title: Text(
                        nhom.tenNhomNguyenLieu,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: isSelected ? const Color(0xFF2F8000) : const Color(0xFF1A202C),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${nhom.loaiNhomNguyenLieu} • ${nhom.soNguyenLieu} nguyên liệu',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF2F8000))
                          : null,
                      onTap: () {
                        cubit.selectNhomNguyenLieu(nhom);
                        Navigator.pop(bottomSheetContext);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Nguyên liệu theo nhóm picker dialog
  void _showNguyenLieuPicker(BuildContext context, AddIngredientState state) {
    if (state.nguyenLieuTheoNhomList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có nguyên liệu trong nhóm này'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final cubit = context.read<AddIngredientCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chọn nguyên liệu',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${state.nguyenLieuTheoNhomList.length} nguyên liệu',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF2F8000),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.nguyenLieuTheoNhomList.length,
                  itemBuilder: (_, index) {
                    final nguyenLieu = state.nguyenLieuTheoNhomList[index];
                    final isSelected = state.selectedNguyenLieuTheoNhom?.maNguyenLieu == nguyenLieu.maNguyenLieu;
                    return ListTile(
                      title: Text(
                        nguyenLieu.tenNguyenLieu,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          color: isSelected ? const Color(0xFF2F8000) : const Color(0xFF1A202C),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      subtitle: nguyenLieu.donVi != null
                          ? Text(
                              'Đơn vị: ${nguyenLieu.donVi}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF718096),
                              ),
                            )
                          : null,
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF2F8000))
                          : null,
                      onTap: () {
                        cubit.selectNguyenLieuTheoNhom(nguyenLieu);
                        Navigator.pop(bottomSheetContext);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Category picker dialog
  void _showCategoryPicker(BuildContext context, AddIngredientState state) {
    final cubit = context.read<AddIngredientCubit>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn danh mục',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 16),
              ...state.categories.map((category) {
                final isSelected = state.selectedCategory?.id == category.id;
                return ListTile(
                  title: Text(
                    category.name,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: isSelected ? const Color(0xFF2F8000) : const Color(0xFF1A202C),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF2F8000))
                      : null,
                  onTap: () {
                    cubit.selectCategory(category);
                    Navigator.pop(bottomSheetContext);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Unit picker dialog
  void _showUnitPicker(BuildContext context, AddIngredientState state) {
    final cubit = context.read<AddIngredientCubit>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chọn đơn vị bán',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 16),
              ...state.units.map((unit) {
                final isSelected = state.donViBan == unit;
                return ListTile(
                  title: Text(
                    unit,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: isSelected ? const Color(0xFF2F8000) : const Color(0xFF1A202C),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF2F8000))
                      : null,
                  onTap: () {
                    cubit.selectDonViBan(unit);
                    Navigator.pop(bottomSheetContext);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Action buttons (Hủy + Thêm)
  Widget _buildActionButtons(BuildContext context, AddIngredientState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SafeArea(
        child: Row(
          children: [
            // Nút Hủy
            Expanded(
              child: GestureDetector(
                onTap: () {
                  context.read<AddIngredientCubit>().cancel();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Hủy',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color: Color(0xFF4A5568),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Nút Thêm
            Expanded(
              child: GestureDetector(
                onTap: state.isSubmitting
                    ? null
                    : () => context.read<AddIngredientCubit>().submitProduct(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2F8000),
                        Color(0xFF2F8000),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Thêm nguyên liệu',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
