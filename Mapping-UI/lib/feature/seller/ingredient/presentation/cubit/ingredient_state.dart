import 'package:equatable/equatable.dart';
import 'package:dngo/core/config/app_config.dart';

/// Model đại diện cho một nguyên liệu/sản phẩm của người bán
class SellerIngredient extends Equatable {
  final String id;
  final String name;
  final double price;
  final double finalPrice;
  final String unit;
  final int availableQuantity;
  final String imageUrl;
  final int discountPercent;
  final DateTime? updatedAt;

  const SellerIngredient({
    required this.id,
    required this.name,
    required this.price,
    required this.finalPrice,
    required this.unit,
    required this.availableQuantity,
    required this.imageUrl,
    this.discountPercent = 0,
    this.updatedAt,
  });

  /// Parse từ API response
  factory SellerIngredient.fromJson(Map<String, dynamic> json) {
    return SellerIngredient(
      id: json['ma_nguyen_lieu'] ?? '',
      name: json['ten_nguyen_lieu'] ?? '',
      price: (json['gia_goc'] ?? 0).toDouble(),
      finalPrice: double.tryParse(json['gia_cuoi']?.toString() ?? '0') ?? 0,
      unit: json['don_vi_ban'] ?? '',
      availableQuantity: json['so_luong_ban'] ?? 0,
      imageUrl: _parseImageUrl(json['hinh_anh'] ?? json['image'] ?? json['img']),
      discountPercent: json['phan_tram_giam_gia'] ?? 0,
      updatedAt: json['ngay_cap_nhat'] != null 
          ? DateTime.tryParse(json['ngay_cap_nhat']) 
          : null,
    );
  }

  static String _parseImageUrl(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';
    final path = value.toString();
    if (path.startsWith('http')) return path;
    
    final baseUrl = AppConfig.imageBaseUrl;
    return '$baseUrl${path.startsWith('/') ? '' : '/'}$path';
  }

  /// Format giá tiền
  String get formattedPrice {
    final formatted = finalPrice.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formatted ₫ / $unit';
  }

  /// Format giá gốc (nếu có giảm giá)
  String get formattedOriginalPrice {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formatted ₫';
  }

  /// Có giảm giá không
  bool get hasDiscount => discountPercent > 0;

  @override
  List<Object?> get props => [id, name, price, finalPrice, unit, availableQuantity, imageUrl, discountPercent, updatedAt];
}

/// State chính của Seller Ingredient
class SellerIngredientState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<SellerIngredient> ingredients;
  final String searchQuery;
  final int currentTabIndex;
  final int currentPage;
  final int totalItems;
  final bool hasNextPage;

  const SellerIngredientState({
    this.isLoading = false,
    this.errorMessage,
    this.ingredients = const [],
    this.searchQuery = '',
    this.currentTabIndex = 1, // Tab Sản phẩm mặc định
    this.currentPage = 1,
    this.totalItems = 0,
    this.hasNextPage = false,
  });

  /// Factory tạo state ban đầu
  factory SellerIngredientState.initial() {
    return const SellerIngredientState(isLoading: true);
  }

  /// Lọc danh sách theo search query
  List<SellerIngredient> get filteredIngredients {
    if (searchQuery.isEmpty) return ingredients;
    final query = searchQuery.toLowerCase();
    return ingredients.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query);
    }).toList();
  }

  SellerIngredientState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<SellerIngredient>? ingredients,
    String? searchQuery,
    int? currentTabIndex,
    int? currentPage,
    int? totalItems,
    bool? hasNextPage,
  }) {
    return SellerIngredientState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      ingredients: ingredients ?? this.ingredients,
      searchQuery: searchQuery ?? this.searchQuery,
      currentTabIndex: currentTabIndex ?? this.currentTabIndex,
      currentPage: currentPage ?? this.currentPage,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        ingredients,
        searchQuery,
        currentTabIndex,
        currentPage,
        totalItems,
        hasNextPage,
      ];
}
