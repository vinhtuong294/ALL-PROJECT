import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';
import '../../../../../../core/services/nhom_nguyen_lieu_service.dart';
import 'add_ingredient_state.dart';

class AddIngredientCubit extends Cubit<AddIngredientState> {
  final ImagePicker _imagePicker = ImagePicker();

  AddIngredientCubit() : super(AddIngredientState.initial());

  /// Khởi tạo và load danh sách nguyên liệu + nhóm nguyên liệu
  Future<void> initialize() async {
    emit(state.copyWith(isLoading: true));

    try {
      // Load nhóm nguyên liệu từ API
      final nhomNguyenLieuResponse = await NhomNguyenLieuService.getNhomNguyenLieu();
      
      debugPrint('AddIngredientCubit: Loaded ${nhomNguyenLieuResponse.data.length} nhom nguyen lieu');

      // Mock ingredients (có thể thay bằng API sau)
      const mockIngredients = [
        Ingredient(maNguyenLieu: 'NL001', tenNguyenLieu: 'Cá hồi'),
        Ingredient(maNguyenLieu: 'NL002', tenNguyenLieu: 'Thịt bò'),
        Ingredient(maNguyenLieu: 'NL003', tenNguyenLieu: 'Rau muống'),
        Ingredient(maNguyenLieu: 'NL004', tenNguyenLieu: 'Cà chua'),
        Ingredient(maNguyenLieu: 'NL005', tenNguyenLieu: 'Hành tây'),
        Ingredient(maNguyenLieu: 'NL006', tenNguyenLieu: 'Tôm sú'),
      ];

      emit(state.copyWith(
        isLoading: false,
        ingredients: mockIngredients,
        nhomNguyenLieuList: nhomNguyenLieuResponse.data,
      ));
    } catch (e) {
      debugPrint('AddIngredientCubit: Error - $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách nguyên liệu: ${e.toString()}',
      ));
    }
  }

  /// Chọn ảnh từ gallery
  Future<void> pickImages() async {
    if (!state.canAddMoreImages) {
      emit(state.copyWith(
        errorMessage: 'Đã đạt tối đa 5 ảnh',
      ));
      return;
    }

    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (pickedFiles.isNotEmpty) {
        final remainingSlots = 5 - state.selectedImages.length;
        final filesToAdd = pickedFiles.take(remainingSlots).toList();
        
        final newImages = [
          ...state.selectedImages,
          ...filesToAdd.map((xFile) => File(xFile.path)),
        ];

        emit(state.copyWith(selectedImages: newImages));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Không thể chọn ảnh: ${e.toString()}',
      ));
    }
  }

  /// Chụp ảnh từ camera
  Future<void> takePhoto() async {
    if (!state.canAddMoreImages) {
      emit(state.copyWith(
        errorMessage: 'Đã đạt tối đa 5 ảnh',
      ));
      return;
    }

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (photo != null) {
        final newImages = [...state.selectedImages, File(photo.path)];
        emit(state.copyWith(selectedImages: newImages));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Không thể chụp ảnh: ${e.toString()}',
      ));
    }
  }

  /// Xóa ảnh
  void removeImage(int index) {
    if (index >= 0 && index < state.selectedImages.length) {
      final newImages = List<File>.from(state.selectedImages);
      newImages.removeAt(index);
      emit(state.copyWith(selectedImages: newImages));
    }
  }

  /// Chọn nguyên liệu
  void selectIngredient(Ingredient ingredient) {
    emit(state.copyWith(selectedIngredient: ingredient));
  }

  /// Cập nhật tên nguyên liệu
  void updateTenNguyenLieu(String tenNguyenLieu) {
    emit(state.copyWith(tenNguyenLieu: tenNguyenLieu));
  }

  /// Chọn danh mục
  void selectCategory(IngredientCategory category) {
    emit(state.copyWith(selectedCategory: category));
  }

  /// Chọn nhóm nguyên liệu và load danh sách nguyên liệu theo nhóm
  Future<void> selectNhomNguyenLieu(NhomNguyenLieu nhomNguyenLieu) async {
    // Reset nguyên liệu đã chọn khi đổi nhóm
    emit(state.copyWith(
      selectedNhomNguyenLieu: nhomNguyenLieu,
      selectedNguyenLieuTheoNhom: null,
      nguyenLieuTheoNhomList: [],
      isLoadingNguyenLieu: true,
    ));

    try {
      final response = await NhomNguyenLieuService.getNguyenLieuTheoNhom(
        nhomNguyenLieu.maNhomNguyenLieu,
      );
      
      debugPrint('AddIngredientCubit: Loaded ${response.data.length} nguyen lieu theo nhom');

      emit(state.copyWith(
        nguyenLieuTheoNhomList: response.data,
        isLoadingNguyenLieu: false,
      ));
    } catch (e) {
      debugPrint('AddIngredientCubit: Error loading nguyen lieu - $e');
      emit(state.copyWith(
        isLoadingNguyenLieu: false,
        errorMessage: 'Không thể tải danh sách nguyên liệu',
      ));
    }
  }

  /// Chọn nguyên liệu theo nhóm
  void selectNguyenLieuTheoNhom(NguyenLieuTheoNhom nguyenLieu) {
    emit(state.copyWith(
      selectedNguyenLieuTheoNhom: nguyenLieu,
      tenNguyenLieu: nguyenLieu.tenNguyenLieu,
    ));
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

  /// Đăng sản phẩm
  Future<void> submitProduct() async {
    debugPrint('========== SUBMIT PRODUCT DEBUG ==========');
    debugPrint('[SUBMIT] Button pressed - Starting validation...');
    debugPrint('[SUBMIT] selectedNguyenLieuTheoNhom: ${state.selectedNguyenLieuTheoNhom?.maNguyenLieu}');
    debugPrint('[SUBMIT] tenNguyenLieu: ${state.tenNguyenLieu}');
    debugPrint('[SUBMIT] giaGoc: ${state.giaGoc}');
    debugPrint('[SUBMIT] soLuongBan: ${state.soLuongBan}');
    debugPrint('[SUBMIT] donViBan: ${state.donViBan}');
    debugPrint('[SUBMIT] phanTramGiamGia: ${state.phanTramGiamGia}');
    debugPrint('[SUBMIT] selectedImages count: ${state.selectedImages.length}');
    debugPrint('[SUBMIT] isFormValid: ${state.isFormValid}');
    
    // Kiểm tra nguyên liệu đã chọn
    if (state.selectedNguyenLieuTheoNhom == null) {
      debugPrint('[SUBMIT] ❌ FAILED - No ingredient selected');
      emit(state.copyWith(
        errorMessage: 'Vui lòng chọn nguyên liệu',
      ));
      return;
    }

    if (!state.isFormValid) {
      debugPrint('[SUBMIT] ❌ FAILED - Form invalid');
      emit(state.copyWith(
        errorMessage: 'Vui lòng điền đầy đủ thông tin bắt buộc',
      ));
      return;
    }

    // Kiểm tra nếu có giảm giá thì phải có thời gian
    if (state.hasDiscount) {
      if (state.thoiGianBatDauGiam == null || state.thoiGianKetThucGiam == null) {
        debugPrint('[SUBMIT] ❌ FAILED - Discount time not set');
        emit(state.copyWith(
          errorMessage: 'Vui lòng chọn thời gian giảm giá',
        ));
        return;
      }
    }

    debugPrint('[SUBMIT] ✅ Validation passed - Processing...');
    emit(state.copyWith(isSubmitting: true));

    try {
      // Step 1: Upload ảnh nếu có
      String? imageUrl;
      if (state.selectedImages.isNotEmpty) {
        debugPrint('[SUBMIT] Step 1: Uploading ${state.selectedImages.length} images...');
        
        final uploadResponse = await NhomNguyenLieuService.uploadImages(
          files: state.selectedImages,
          folder: 'products',
        );

        if (uploadResponse.success && uploadResponse.urls.isNotEmpty) {
          imageUrl = uploadResponse.urls.first;
          debugPrint('[SUBMIT] ✅ Image uploaded - URL: $imageUrl');
        } else {
          debugPrint('[SUBMIT] ⚠️ Image upload failed: ${uploadResponse.message}');
          // Tiếp tục thêm sản phẩm không có ảnh
        }
      }

      // Step 2: Gọi API thêm sản phẩm
      debugPrint('[SUBMIT] Step 2: Calling addProduct API...');
      final response = await NhomNguyenLieuService.addProduct(
        maNguyenLieu: state.selectedNguyenLieuTheoNhom!.maNguyenLieu,
        giaGoc: int.tryParse(state.giaGoc) ?? 0,
        soLuongBan: int.tryParse(state.soLuongBan) ?? 0,
        donViBan: state.donViBan!,
        phanTramGiamGia: int.tryParse(state.phanTramGiamGia) ?? 0,
        thoiGianBatDauGiam: state.thoiGianBatDauGiam,
        thoiGianKetThucGiam: state.thoiGianKetThucGiam,
        hinhAnh: imageUrl,
      );

      debugPrint('[SUBMIT] API Response - success: ${response.success}, message: ${response.message}');

      if (response.success) {
        debugPrint('[SUBMIT] ✅ SUCCESS');
        emit(state.copyWith(
          isSubmitting: false,
          successMessage: response.message ?? 'Thêm nguyên liệu thành công!',
        ));
      } else {
        debugPrint('[SUBMIT] ❌ API returned error: ${response.message}');
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: response.message ?? 'Không thể thêm nguyên liệu',
        ));
      }
    } catch (e, stackTrace) {
      debugPrint('[SUBMIT] ❌ EXCEPTION: $e');
      debugPrint('[SUBMIT] Stack trace: $stackTrace');
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Không thể thêm nguyên liệu: ${e.toString()}',
      ));
    }
    debugPrint('==========================================');
  }

  /// Hủy bỏ
  void cancel() {
    // Reset state
    emit(const AddIngredientState());
  }

  /// Clear messages
  void clearMessages() {
    emit(state.copyWith(
      errorMessage: null,
      successMessage: null,
    ));
  }
}
  