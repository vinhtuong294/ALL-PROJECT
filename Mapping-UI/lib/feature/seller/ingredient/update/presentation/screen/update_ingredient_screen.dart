import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../../../seller/ingredient/presentation/cubit/ingredient_state.dart';
import '../cubit/update_ingredient_cubit.dart';
import '../cubit/update_ingredient_state.dart';

class UpdateIngredientScreen extends StatelessWidget {
  final SellerIngredient ingredient;
  
  const UpdateIngredientScreen({super.key, required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UpdateIngredientCubit()..initialize(ingredient),
      child: const _UpdateIngredientView(),
    );
  }
}

class _UpdateIngredientView extends StatefulWidget {
  const _UpdateIngredientView();

  @override
  State<_UpdateIngredientView> createState() => _UpdateIngredientViewState();
}

class _UpdateIngredientViewState extends State<_UpdateIngredientView> {
  late TextEditingController _giaGocController;
  late TextEditingController _soLuongBanController;
  late TextEditingController _phanTramGiamGiaController;

  @override
  void initState() {
    super.initState();
    _giaGocController = TextEditingController();
    _soLuongBanController = TextEditingController();
    _phanTramGiamGiaController = TextEditingController();
  }

  @override
  void dispose() {
    _giaGocController.dispose();
    _soLuongBanController.dispose();
    _phanTramGiamGiaController.dispose();
    super.dispose();
  }

  void _initControllers(UpdateIngredientState state) {
    if (_giaGocController.text.isEmpty && state.giaGoc.isNotEmpty) {
      _giaGocController.text = state.giaGoc;
    }
    if (_soLuongBanController.text.isEmpty && state.soLuongBan.isNotEmpty) {
      _soLuongBanController.text = state.soLuongBan;
    }
    if (_phanTramGiamGiaController.text.isEmpty) {
      _phanTramGiamGiaController.text = state.phanTramGiamGia;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: BlocConsumer<UpdateIngredientCubit, UpdateIngredientState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
            context.read<UpdateIngredientCubit>().clearMessages();
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: const Color(0xFF2F8000),
              ),
            );
            context.read<UpdateIngredientCubit>().clearMessages();
            Navigator.of(context).pop(true); // Return true to refresh list
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2F8000)),
            );
          }

          _initControllers(state);

          return Column(
            children: [
              _buildHeader(context, state),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProductInfo(state),
                      const SizedBox(height: 20),
                      _buildImageSection(context, state),
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


  /// Header
  Widget _buildHeader(BuildContext context, UpdateIngredientState state) {
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
            color: Colors.black.withValues(alpha: 0.1),
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
            'Chỉnh sửa sản phẩm',
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

  /// Product info (read-only)
  Widget _buildProductInfo(UpdateIngredientState state) {
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
            'Thông tin sản phẩm',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 14),
          _buildReadOnlyField('Mã nguyên liệu', state.maNguyenLieu),
          const SizedBox(height: 10),
          _buildReadOnlyField('Tên nguyên liệu', state.tenNguyenLieu),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Color(0xFF718096),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF2F7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF4A5568),
            ),
          ),
        ),
      ],
    );
  }

  /// Image section
  Widget _buildImageSection(BuildContext context, UpdateIngredientState state) {
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
            'Ảnh sản phẩm',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Current image
              _buildImagePreview(
                context,
                state.hasNewImages ? null : state.currentImageUrl,
                state.hasNewImages ? state.newImages.first : null,
                onRemove: state.hasNewImages
                    ? () => context.read<UpdateIngredientCubit>().removeNewImage()
                    : null,
              ),
              const SizedBox(width: 12),
              // Change image button
              GestureDetector(
                onTap: () => _showImageSourceDialog(context),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, color: Color(0xFF718096), size: 24),
                      SizedBox(height: 4),
                      Text(
                        'Đổi ảnh',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(
    BuildContext context,
    String? networkUrl,
    dynamic localFile, {
    VoidCallback? onRemove,
  }) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: localFile != null
                ? Image.file(localFile, fit: BoxFit.cover)
                : (networkUrl != null && networkUrl.isNotEmpty)
                    ? Image.network(
                        networkUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
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
                  context.read<UpdateIngredientCubit>().pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF2F8000)),
                title: const Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  context.read<UpdateIngredientCubit>().takePhoto();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }


  /// Pricing section
  Widget _buildPricingSection(BuildContext context, UpdateIngredientState state) {
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
            'Giá và Số lượng',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Giá gốc (VNĐ) *',
                  hint: 'Nhập giá bán',
                  controller: _giaGocController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    context.read<UpdateIngredientCubit>().updateGiaGoc(value);
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
          _buildInputField(
            label: 'Số lượng bán *',
            hint: 'Nhập số lượng',
            controller: _soLuongBanController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              context.read<UpdateIngredientCubit>().updateSoLuongBan(value);
            },
          ),
        ],
      ),
    );
  }

  /// Discount section
  Widget _buildDiscountSection(BuildContext context, UpdateIngredientState state) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
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
            'Khuyến mãi',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF1A202C),
            ),
          ),
          const SizedBox(height: 14),
          _buildInputField(
            label: 'Phần trăm giảm giá (%)',
            hint: 'Nhập % giảm giá (0-100)',
            controller: _phanTramGiamGiaController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              context.read<UpdateIngredientCubit>().updatePhanTramGiamGia(value);
            },
          ),
          const SizedBox(height: 14),
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
                context.read<UpdateIngredientCubit>().updateThoiGianBatDauGiam(dateTime);
              },
            ),
          ),
          const SizedBox(height: 14),
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
                context.read<UpdateIngredientCubit>().updateThoiGianKetThucGiam(dateTime);
              },
            ),
          ),
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

  /// Action buttons
  Widget _buildActionButtons(BuildContext context, UpdateIngredientState state) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF718096)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Hủy',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF718096),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => context.read<UpdateIngredientCubit>().submitUpdate(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F8000),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Cập nhật',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }


  /// Input field widget
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
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
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF1A202C),
            ),
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFFA0AEC0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Dropdown field widget
  Widget _buildDropdownField({
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
                      fontSize: 14,
                      color: value != null
                          ? const Color(0xFF1A202C)
                          : const Color(0xFFA0AEC0),
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Color(0xFFA0AEC0)),
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
                      fontSize: 14,
                      color: value != null
                          ? const Color(0xFF1A202C)
                          : const Color(0xFFA0AEC0),
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20, color: Color(0xFFA0AEC0)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showUnitPicker(BuildContext context, UpdateIngredientState state) {
    final cubit = context.read<UpdateIngredientCubit>();
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
                'Chọn đơn vị bán',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 16),
              ...state.units.map((unit) => ListTile(
                title: Text(unit),
                trailing: state.donViBan == unit
                    ? const Icon(Icons.check, color: Color(0xFF2F8000))
                    : null,
                onTap: () {
                  cubit.selectDonViBan(unit);
                  Navigator.pop(bottomSheetContext);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDateTimePicker(
    BuildContext context, 
    DateTime? initialDate,
    Function(DateTime) onSelected,
  ) async {
    final now = DateTime.now();
    
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2F8000)),
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
              colorScheme: const ColorScheme.light(primary: Color(0xFF2F8000)),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        final dateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        onSelected(dateTime);
      }
    }
  }
}
