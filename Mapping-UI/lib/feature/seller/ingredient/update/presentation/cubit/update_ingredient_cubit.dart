import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/services/nhom_nguyen_lieu_service.dart';
import '../../../../../seller/ingredient/presentation/cubit/ingredient_state.dart';
import 'update_ingredient_state.dart';

class UpdateIngredientCubit extends Cubit<UpdateIngredientState> {
  final ImagePicker _imagePicker = ImagePicker();

  UpdateIngredientCubit() : super(UpdateIngredientState.initial());

  /// Khởi tạo với dữ liệu sản phẩm hiện tại
  void initialize(SellerIngredient ingredient) {
    debugPrint('[UPDATE_CUBIT] Initializing with: ${ingredient.id}');
    
    emit(state.copyWith(
      isLoading: false,
      maNguyenLieu: ingredient.id,
      tenNguyenLieu: ingredient.name,
      currentImageUrl: ingredient.imageUrl,
      giaGoc: ingredient.price.toStringAsFixed(0),
      soLuongBan: ingredient.availableQuantity.toString(),
      donViBan: ingredient.unit,
      phanTramGiamGia: ingredient.discountPercent.toString(),
    ));
  }

  /// Chọn ảnh mới từ gallery
  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        emit(state.copyWith(newImages: [File(pickedFile.path)]));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Không thể chọn ảnh: ${e.toString()}',
      ));
    }
  }

  /// Chụp ảnh mới từ camera
  Future<void> takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (photo != null) {
        emit(state.copyWith(newImages: [File(photo.path)]));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Không thể chụp ảnh: ${e.toString()}',
      ));
    }
  }

  /// Xóa ảnh mới đã chọn
  void removeNewImage() {
    emit(state.copyWith(newImages: []));
  }

  /// Cập nhật giá gốc
  void updateGiaGoc(String giaGoc) {
    emit(state.copyWith(giaGoc: giaGoc));
  }

  /// Cập nhật số lượng bán
  void updateSoLuongBan(String soLuong) {
    emit(state.copyWith(soLuongBan: soLuong));
  }

  /// Chọn đơn vị bán
  void selectDonViBan(String donVi) {
    emit(state.copyWith(donViBan: donVi));
  }

  /// Cập nhật phần trăm giảm giá
  void updatePhanTramGiamGia(String phanTram) {
    emit(state.copyWith(phanTramGiamGia: phanTram));
  }

  /// Cập nhật thời gian bắt đầu giảm giá
  void updateThoiGianBatDauGiam(DateTime? dateTime) {
    emit(state.copyWith(thoiGianBatDauGiam: dateTime));
  }

  /// Cập nhật thời gian kết thúc giảm giá
  void updateThoiGianKetThucGiam(DateTime? dateTime) {
    emit(state.copyWith(thoiGianKetThucGiam: dateTime));
  }

  /// Cập nhật sản phẩm
  Future<void> submitUpdate() async {
    debugPrint('========== UPDATE PRODUCT DEBUG ==========');
    debugPrint('[UPDATE] maNguyenLieu: ${state.maNguyenLieu}');
    debugPrint('[UPDATE] giaGoc: ${state.giaGoc}');
    debugPrint('[UPDATE] soLuongBan: ${state.soLuongBan}');
    debugPrint('[UPDATE] donViBan: ${state.donViBan}');
    debugPrint('[UPDATE] phanTramGiamGia: ${state.phanTramGiamGia}');
    debugPrint('[UPDATE] hasNewImages: ${state.hasNewImages}');
    debugPrint('[UPDATE] isFormValid: ${state.isFormValid}');

    if (!state.isFormValid) {
      debugPrint('[UPDATE] ❌ FAILED - Form invalid');
      emit(state.copyWith(
        errorMessage: 'Vui lòng điền đầy đủ thông tin bắt buộc',
      ));
      return;
    }

    // Kiểm tra nếu có giảm giá thì phải có thời gian
    if (state.hasDiscount) {
      if (state.thoiGianBatDauGiam == null || state.thoiGianKetThucGiam == null) {
        debugPrint('[UPDATE] ❌ FAILED - Discount time not set');
        emit(state.copyWith(
          errorMessage: 'Vui lòng chọn thời gian giảm giá',
        ));
        return;
      }
    }

    debugPrint('[UPDATE] ✅ Validation passed - Processing...');
    emit(state.copyWith(isSubmitting: true));

    try {
      // Step 1: Upload ảnh mới nếu có
      String? imageUrl;
      if (state.hasNewImages) {
        debugPrint('[UPDATE] Step 1: Uploading new image...');
        
        final uploadResponse = await NhomNguyenLieuService.uploadImages(
          files: state.newImages,
          folder: 'products',
        );

        if (uploadResponse.success && uploadResponse.urls.isNotEmpty) {
          imageUrl = uploadResponse.urls.first;
          debugPrint('[UPDATE] ✅ Image uploaded - URL: $imageUrl');
        } else {
          debugPrint('[UPDATE] ⚠️ Image upload failed: ${uploadResponse.message}');
        }
      }

      // Step 2: Gọi API cập nhật sản phẩm
      // Nếu không có ảnh mới, dùng ảnh hiện tại
      final finalImageUrl = imageUrl ?? state.currentImageUrl;
      debugPrint('[UPDATE] Step 2: Calling updateProduct API...');
      debugPrint('[UPDATE] Final image URL: $finalImageUrl');
      
      final response = await NhomNguyenLieuService.updateProduct(
        maNguyenLieu: state.maNguyenLieu,
        giaGoc: int.tryParse(state.giaGoc) ?? 0,
        soLuongBan: int.tryParse(state.soLuongBan) ?? 0,
        donViBan: state.donViBan!,
        phanTramGiamGia: int.tryParse(state.phanTramGiamGia) ?? 0,
        thoiGianBatDauGiam: state.thoiGianBatDauGiam,
        thoiGianKetThucGiam: state.thoiGianKetThucGiam,
        hinhAnh: finalImageUrl.isNotEmpty ? finalImageUrl : null,
      );

      debugPrint('[UPDATE] API Response - success: ${response.success}, message: ${response.message}');

      if (response.success) {
        debugPrint('[UPDATE] ✅ SUCCESS');
        emit(state.copyWith(
          isSubmitting: false,
          successMessage: response.message ?? 'Cập nhật sản phẩm thành công!',
        ));
      } else {
        debugPrint('[UPDATE] ❌ API returned error: ${response.message}');
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: response.message ?? 'Không thể cập nhật sản phẩm',
        ));
      }
    } catch (e, stackTrace) {
      debugPrint('[UPDATE] ❌ EXCEPTION: $e');
      debugPrint('[UPDATE] Stack trace: $stackTrace');
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Không thể cập nhật sản phẩm: ${e.toString()}',
      ));
    }
    debugPrint('==========================================');
  }

  /// Clear messages
  void clearMessages() {
    emit(state.copyWith(
      errorMessage: null,
      successMessage: null,
    ));
  }
}
