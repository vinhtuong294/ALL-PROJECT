import 'package:equatable/equatable.dart';
import 'dart:io';

/// State cho Update Ingredient
class UpdateIngredientState extends Equatable {
  // Product info
  final String maNguyenLieu;
  final String tenNguyenLieu;
  final String currentImageUrl;
  
  // Images
  final List<File> newImages;
  
  // Form fields
  final String giaGoc;
  final String soLuongBan;
  final String? donViBan;
  final List<String> units;
  final String phanTramGiamGia;
  final DateTime? thoiGianBatDauGiam;
  final DateTime? thoiGianKetThucGiam;
  
  // Status
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const UpdateIngredientState({
    this.maNguyenLieu = '',
    this.tenNguyenLieu = '',
    this.currentImageUrl = '',
    this.newImages = const [],
    this.giaGoc = '',
    this.soLuongBan = '',
    this.donViBan,
    this.units = const ['kg', 'g', 'con', 'cái', 'bó', 'chục', 'lít'],
    this.phanTramGiamGia = '0',
    this.thoiGianBatDauGiam,
    this.thoiGianKetThucGiam,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  /// Factory tạo state ban đầu
  factory UpdateIngredientState.initial() {
    return const UpdateIngredientState(isLoading: true);
  }

  /// Kiểm tra form hợp lệ
  bool get isFormValid =>
      giaGoc.isNotEmpty &&
      soLuongBan.isNotEmpty &&
      donViBan != null;

  /// Kiểm tra có giảm giá không
  bool get hasDiscount => 
      phanTramGiamGia.isNotEmpty && 
      int.tryParse(phanTramGiamGia) != null &&
      int.parse(phanTramGiamGia) > 0;

  /// Có ảnh mới không
  bool get hasNewImages => newImages.isNotEmpty;

  UpdateIngredientState copyWith({
    String? maNguyenLieu,
    String? tenNguyenLieu,
    String? currentImageUrl,
    List<File>? newImages,
    String? giaGoc,
    String? soLuongBan,
    String? donViBan,
    List<String>? units,
    String? phanTramGiamGia,
    DateTime? thoiGianBatDauGiam,
    DateTime? thoiGianKetThucGiam,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
  }) {
    return UpdateIngredientState(
      maNguyenLieu: maNguyenLieu ?? this.maNguyenLieu,
      tenNguyenLieu: tenNguyenLieu ?? this.tenNguyenLieu,
      currentImageUrl: currentImageUrl ?? this.currentImageUrl,
      newImages: newImages ?? this.newImages,
      giaGoc: giaGoc ?? this.giaGoc,
      soLuongBan: soLuongBan ?? this.soLuongBan,
      donViBan: donViBan ?? this.donViBan,
      units: units ?? this.units,
      phanTramGiamGia: phanTramGiamGia ?? this.phanTramGiamGia,
      thoiGianBatDauGiam: thoiGianBatDauGiam ?? this.thoiGianBatDauGiam,
      thoiGianKetThucGiam: thoiGianKetThucGiam ?? this.thoiGianKetThucGiam,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        maNguyenLieu,
        tenNguyenLieu,
        currentImageUrl,
        newImages,
        giaGoc,
        soLuongBan,
        donViBan,
        units,
        phanTramGiamGia,
        thoiGianBatDauGiam,
        thoiGianKetThucGiam,
        isLoading,
        isSubmitting,
        errorMessage,
        successMessage,
      ];
}
