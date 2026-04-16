import 'package:equatable/equatable.dart';
import 'dart:io';
import '../../../../../../core/models/nhom_nguyen_lieu_model.dart';
export '../../../../../../core/models/nhom_nguyen_lieu_model.dart';

/// Model đại diện cho nguyên liệu
class Ingredient extends Equatable {
  final String maNguyenLieu;
  final String tenNguyenLieu;

  const Ingredient({
    required this.maNguyenLieu,
    required this.tenNguyenLieu,
  });

  @override
  List<Object?> get props => [maNguyenLieu, tenNguyenLieu];
}

/// Model đại diện cho danh mục
class IngredientCategory extends Equatable {
  final String id;
  final String name;

  const IngredientCategory({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}

/// State cho Add Ingredient
class AddIngredientState extends Equatable {
  // Images
  final List<File> selectedImages;
  
  // Form fields - theo API
  final String tenNguyenLieu;            // ten_nguyen_lieu (nhập tay)
  final Ingredient? selectedIngredient;  // ma_nguyen_lieu (nếu chọn từ danh sách)
  final List<Ingredient> ingredients;    // danh sách nguyên liệu để chọn
  final IngredientCategory? selectedCategory;      // danh mục đã chọn
  final List<IngredientCategory> categories;       // danh sách danh mục
  final NhomNguyenLieu? selectedNhomNguyenLieu;  // nhóm nguyên liệu đã chọn
  final List<NhomNguyenLieu> nhomNguyenLieuList; // danh sách nhóm nguyên liệu từ API
  final NguyenLieuTheoNhom? selectedNguyenLieuTheoNhom; // nguyên liệu đã chọn theo nhóm
  final List<NguyenLieuTheoNhom> nguyenLieuTheoNhomList; // danh sách nguyên liệu theo nhóm
  final bool isLoadingNguyenLieu;        // đang load nguyên liệu theo nhóm
  final String giaGoc;                   // gia_goc
  final String soLuongBan;               // so_luong_ban
  final String? donViBan;                // don_vi_ban
  final List<String> units;
  final String phanTramGiamGia;          // phan_tram_giam_gia
  final DateTime? thoiGianBatDauGiam;    // thoi_gian_bat_dau_giam
  final DateTime? thoiGianKetThucGiam;   // thoi_gian_ket_thuc_giam
  
  // Status
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const AddIngredientState({
    this.selectedImages = const [],
    this.tenNguyenLieu = '',
    this.selectedIngredient,
    this.ingredients = const [],
    this.selectedCategory,
    this.categories = const [
      IngredientCategory(id: 'DM001', name: 'Rau củ quả'),
      IngredientCategory(id: 'DM002', name: 'Thịt'),
      IngredientCategory(id: 'DM003', name: 'Hải sản'),
      IngredientCategory(id: 'DM004', name: 'Gia vị'),
      IngredientCategory(id: 'DM005', name: 'Đồ khô'),
      IngredientCategory(id: 'DM006', name: 'Trứng & Sữa'),
    ],
    this.selectedNhomNguyenLieu,
    this.nhomNguyenLieuList = const [],
    this.selectedNguyenLieuTheoNhom,
    this.nguyenLieuTheoNhomList = const [],
    this.isLoadingNguyenLieu = false,
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
  factory AddIngredientState.initial() {
    return const AddIngredientState(isLoading: true);
  }

  /// Kiểm tra form hợp lệ
  bool get isFormValid =>
      selectedNguyenLieuTheoNhom != null &&
      giaGoc.isNotEmpty &&
      soLuongBan.isNotEmpty &&
      donViBan != null;

  /// Kiểm tra có giảm giá không
  bool get hasDiscount => 
      phanTramGiamGia.isNotEmpty && 
      int.tryParse(phanTramGiamGia) != null &&
      int.parse(phanTramGiamGia) > 0;

  /// Số lượng ảnh đã chọn
  int get imageCount => selectedImages.length;

  /// Có thể thêm ảnh không
  bool get canAddMoreImages => selectedImages.length < 5;

  AddIngredientState copyWith({
    List<File>? selectedImages,
    String? tenNguyenLieu,
    Ingredient? selectedIngredient,
    List<Ingredient>? ingredients,
    IngredientCategory? selectedCategory,
    List<IngredientCategory>? categories,
    NhomNguyenLieu? selectedNhomNguyenLieu,
    List<NhomNguyenLieu>? nhomNguyenLieuList,
    NguyenLieuTheoNhom? selectedNguyenLieuTheoNhom,
    List<NguyenLieuTheoNhom>? nguyenLieuTheoNhomList,
    bool? isLoadingNguyenLieu,
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
    return AddIngredientState(
      selectedImages: selectedImages ?? this.selectedImages,
      tenNguyenLieu: tenNguyenLieu ?? this.tenNguyenLieu,
      selectedIngredient: selectedIngredient ?? this.selectedIngredient,
      ingredients: ingredients ?? this.ingredients,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      categories: categories ?? this.categories,
      selectedNhomNguyenLieu: selectedNhomNguyenLieu ?? this.selectedNhomNguyenLieu,
      nhomNguyenLieuList: nhomNguyenLieuList ?? this.nhomNguyenLieuList,
      selectedNguyenLieuTheoNhom: selectedNguyenLieuTheoNhom ?? this.selectedNguyenLieuTheoNhom,
      nguyenLieuTheoNhomList: nguyenLieuTheoNhomList ?? this.nguyenLieuTheoNhomList,
      isLoadingNguyenLieu: isLoadingNguyenLieu ?? this.isLoadingNguyenLieu,
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
        selectedImages,
        tenNguyenLieu,
        selectedIngredient,
        ingredients,
        selectedCategory,
        categories,
        selectedNhomNguyenLieu,
        nhomNguyenLieuList,
        selectedNguyenLieuTheoNhom,
        nguyenLieuTheoNhomList,
        isLoadingNguyenLieu,
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
