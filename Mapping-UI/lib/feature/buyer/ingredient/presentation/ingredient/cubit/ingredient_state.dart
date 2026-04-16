import 'package:equatable/equatable.dart';

/// Base state for Ingredient Screen
abstract class IngredientState extends Equatable {
  const IngredientState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class IngredientInitial extends IngredientState {
  const IngredientInitial();
}

/// Loading state
class IngredientLoading extends IngredientState {
  const IngredientLoading();
}

/// Loaded state
class IngredientLoaded extends IngredientState {
  final String? selectedRegion; // Tên khu vực
  final String? selectedRegionMa; // Mã khu vực
  final String? selectedMarket; // Tên chợ
  final String? selectedMarketMa; // Mã chợ
  final String searchQuery;
  final List<Category> categories;
  final List<Category> additionalCategories;
  final List<Shop> shops;
  final List<Product> products;
  final List<String> shopNames;
  final int selectedBottomNavIndex;
  final int cartItemCount;
  
  // Pagination fields
  final int currentPage;
  final bool hasMoreProducts;
  final bool isLoadingMore;

  const IngredientLoaded({
    this.selectedRegion,
    this.selectedRegionMa,
    this.selectedMarket,
    this.selectedMarketMa,
    this.searchQuery = '',
    this.categories = const [],
    this.additionalCategories = const [],
    this.shops = const [],
    this.products = const [],
    this.shopNames = const [],
    this.selectedBottomNavIndex = 1,
    this.cartItemCount = 0,
    this.currentPage = 1,
    this.hasMoreProducts = true,
    this.isLoadingMore = false,
  });

  IngredientLoaded copyWith({
    String? selectedRegion,
    String? selectedRegionMa,
    String? selectedMarket,
    String? selectedMarketMa,
    String? searchQuery,
    List<Category>? categories,
    List<Category>? additionalCategories,
    List<Shop>? shops,
    List<Product>? products,
    List<String>? shopNames,
    int? selectedBottomNavIndex,
    int? cartItemCount,
    int? currentPage,
    bool? hasMoreProducts,
    bool? isLoadingMore,
  }) {
    return IngredientLoaded(
      selectedRegion: selectedRegion ?? this.selectedRegion,
      selectedRegionMa: selectedRegionMa ?? this.selectedRegionMa,
      selectedMarket: selectedMarket ?? this.selectedMarket,
      selectedMarketMa: selectedMarketMa ?? this.selectedMarketMa,
      searchQuery: searchQuery ?? this.searchQuery,
      categories: categories ?? this.categories,
      additionalCategories: additionalCategories ?? this.additionalCategories,
      shops: shops ?? this.shops,
      products: products ?? this.products,
      shopNames: shopNames ?? this.shopNames,
      selectedBottomNavIndex: selectedBottomNavIndex ?? this.selectedBottomNavIndex,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      currentPage: currentPage ?? this.currentPage,
      hasMoreProducts: hasMoreProducts ?? this.hasMoreProducts,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        selectedRegion,
        selectedRegionMa,
        selectedMarket,
        selectedMarketMa,
        searchQuery,
        categories,
        additionalCategories,
        shops,
        products,
        shopNames,
        selectedBottomNavIndex,
        cartItemCount,
        currentPage,
        hasMoreProducts,
        isLoadingMore,
      ];
}

/// Error state
class IngredientError extends IngredientState {
  final String message;

  const IngredientError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Category model
class Category extends Equatable {
  final String? maNhomNguyenLieu; // Mã nhóm nguyên liệu
  final String name;
  final String imagePath;

  const Category({
    this.maNhomNguyenLieu,
    required this.name,
    required this.imagePath,
  });

  @override
  List<Object?> get props => [maNhomNguyenLieu, name, imagePath];
}

/// Product model
class Product extends Equatable {
  final String? maNguyenLieu; // Thêm mã nguyên liệu
  final String name;
  final String price;
  final String imagePath;
  final String shopName;
  final String? badge;
  final bool hasDiscount;
  final String? originalPrice;

  const Product({
    this.maNguyenLieu,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.shopName,
    this.badge,
    this.hasDiscount = false,
    this.originalPrice,
  });

  @override
  List<Object?> get props => [
        maNguyenLieu,
        name,
        price,
        imagePath,
        shopName,
        badge,
        hasDiscount,
        originalPrice,
      ];
}

/// Shop model
class Shop extends Equatable {
  final String id;
  final String name;
  final String? imagePath;
  final String? rating;
  final String? distance;

  const Shop({
    required this.id,
    required this.name,
    this.imagePath,
    this.rating,
    this.distance,
  });

  @override
  List<Object?> get props => [id, name, imagePath, rating, distance];
}
