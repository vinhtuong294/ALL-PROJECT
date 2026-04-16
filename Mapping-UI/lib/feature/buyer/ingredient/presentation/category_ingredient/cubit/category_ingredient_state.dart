import 'package:equatable/equatable.dart';

/// State cho Category Ingredient Screen
abstract class CategoryIngredientState extends Equatable {
  const CategoryIngredientState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CategoryIngredientInitial extends CategoryIngredientState {
  const CategoryIngredientInitial();
}

/// Loading state
class CategoryIngredientLoading extends CategoryIngredientState {
  const CategoryIngredientLoading();
}

/// Loaded state
class CategoryIngredientLoaded extends CategoryIngredientState {
  final String categoryId;
  final String categoryName;
  final List<CategoryIngredientItem> ingredients;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  const CategoryIngredientLoaded({
    required this.categoryId,
    required this.categoryName,
    this.ingredients = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  CategoryIngredientLoaded copyWith({
    String? categoryId,
    String? categoryName,
    List<CategoryIngredientItem>? ingredients,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return CategoryIngredientLoaded(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      ingredients: ingredients ?? this.ingredients,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        ingredients,
        currentPage,
        hasMore,
        isLoadingMore,
      ];
}

/// Error state
class CategoryIngredientError extends CategoryIngredientState {
  final String message;

  const CategoryIngredientError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Model cho nguyên liệu trong danh mục
class CategoryIngredientItem extends Equatable {
  final String maNguyenLieu;
  final String tenNguyenLieu;
  final String? hinhAnh;
  final String price;
  final String? originalPrice;
  final bool hasDiscount;
  final String tenNhomNguyenLieu;
  final int soGianHang;

  const CategoryIngredientItem({
    required this.maNguyenLieu,
    required this.tenNguyenLieu,
    this.hinhAnh,
    required this.price,
    this.originalPrice,
    this.hasDiscount = false,
    required this.tenNhomNguyenLieu,
    required this.soGianHang,
  });

  @override
  List<Object?> get props => [
        maNguyenLieu,
        tenNguyenLieu,
        hinhAnh,
        price,
        originalPrice,
        hasDiscount,
        tenNhomNguyenLieu,
        soGianHang,
      ];
}
