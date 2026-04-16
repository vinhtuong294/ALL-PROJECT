import 'package:equatable/equatable.dart';
import '../../../../../core/models/category_model.dart';
import '../../../../../core/models/mon_an_model.dart';
import '../../../../../core/models/khu_vuc_model.dart';
import '../../../../../core/models/cho_model.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<CategoryModel> categories;
  final List<MonAnWithImage> monAnList; // Danh sách món ăn kèm URL ảnh
  final String selectedCategory;
  final String searchQuery;
  final int selectedBottomNavIndex;
  final List<String> selectedFilters; // Bộ lọc: Công thức, Món ngon, Yêu thích
  final int currentPage; // Trang hiện tại
  final bool hasMore; // Còn dữ liệu để load không
  final bool isLoadingMore; // Đang load thêm dữ liệu

  final int cartItemCount;
  
  // Thêm fields cho khu vực và chợ
  final String? selectedRegionMa; // Mã khu vực đã chọn (KV01, KV02...)
  final String? selectedRegion; // Tên khu vực đã chọn
  final String? selectedMarketMa; // Mã chợ đã chọn
  final String? selectedMarket; // Tên chợ đã chọn
  final List<KhuVucModel> khuVucList; // Danh sách khu vực từ API
  final List<ChoModel> choList; // Danh sách chợ từ API

  const ProductLoaded({
    this.categories = const [],
    this.monAnList = const [],
    this.selectedCategory = 'Tất cả',
    this.searchQuery = '',
    this.selectedBottomNavIndex = 1, // 1 = Sản phẩm tab
    this.selectedFilters = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.cartItemCount = 0,
    this.selectedRegionMa,
    this.selectedRegion,
    this.selectedMarketMa,
    this.selectedMarket,
    this.khuVucList = const [],
    this.choList = const [],
  });

  ProductLoaded copyWith({
    List<CategoryModel>? categories,
    List<MonAnWithImage>? monAnList,
    String? selectedCategory,
    String? searchQuery,
    int? selectedBottomNavIndex,
    List<String>? selectedFilters,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    int? cartItemCount,
    String? selectedRegionMa,
    String? selectedRegion,
    String? selectedMarketMa,
    String? selectedMarket,
    List<KhuVucModel>? khuVucList,
    List<ChoModel>? choList,
  }) {
    return ProductLoaded(
      categories: categories ?? this.categories,
      monAnList: monAnList ?? this.monAnList,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedBottomNavIndex:
          selectedBottomNavIndex ?? this.selectedBottomNavIndex,
      selectedFilters: selectedFilters ?? this.selectedFilters,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      selectedRegionMa: selectedRegionMa ?? this.selectedRegionMa,
      selectedRegion: selectedRegion ?? this.selectedRegion,
      selectedMarketMa: selectedMarketMa ?? this.selectedMarketMa,
      selectedMarket: selectedMarket ?? this.selectedMarket,
      khuVucList: khuVucList ?? this.khuVucList,
      choList: choList ?? this.choList,
    );
  }

  @override
  List<Object?> get props =>
      [categories, monAnList, selectedCategory, searchQuery, selectedBottomNavIndex, selectedFilters, currentPage, hasMore, isLoadingMore, cartItemCount, selectedRegionMa, selectedRegion, selectedMarketMa, selectedMarket, khuVucList, choList];
}

/// Model kết hợp món ăn với URL ảnh và thông tin chi tiết
class MonAnWithImage {
  final MonAnModel monAn;
  final String imageUrl; // URL ảnh từ API detail
  final int? cookTime; // Thời gian nấu (phút) - từ khoang_thoi_gian
  final String? difficulty; // Độ khó - từ do_kho
  final int? servings; // Số khẩu phần - từ khau_phan_tieu_chuan

  MonAnWithImage({
    required this.monAn,
    required this.imageUrl,
    this.cookTime,
    this.difficulty,
    this.servings,
  });
}

class ProductError extends ProductState {
  final String message;
  final bool requiresLogin;

  const ProductError(this.message, {this.requiresLogin = false});

  @override
  List<Object?> get props => [message, requiresLogin];
}
