import 'package:equatable/equatable.dart';
import '../../../../../core/models/mon_an_model.dart';

/// Base state class for SearchResult feature
abstract class SearchResultState extends Equatable {
  const SearchResultState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class SearchResultInitial extends SearchResultState {}

/// State while loading search results
class SearchResultLoading extends SearchResultState {}

/// State when search results are successfully loaded
class SearchResultLoaded extends SearchResultState {
  final String searchQuery;
  final String selectedMarket;
  final String selectedLocation;
  final List<MonAnWithImage> monAnList; // Danh sách món ăn từ API
  final int selectedBottomNavIndex;
  final int currentPage; // Trang hiện tại
  final bool hasMore; // Còn dữ liệu để load không
  final bool isLoadingMore; // Đang load thêm dữ liệu

  const SearchResultLoaded({
    this.searchQuery = '',
    this.selectedMarket = 'MM, ĐÀ NẴNG',
    this.selectedLocation = 'Chợ Bắc Mỹ An',
    this.monAnList = const [],
    this.selectedBottomNavIndex = 0,
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  SearchResultLoaded copyWith({
    String? searchQuery,
    String? selectedMarket,
    String? selectedLocation,
    List<MonAnWithImage>? monAnList,
    int? selectedBottomNavIndex,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SearchResultLoaded(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMarket: selectedMarket ?? this.selectedMarket,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      monAnList: monAnList ?? this.monAnList,
      selectedBottomNavIndex:
          selectedBottomNavIndex ?? this.selectedBottomNavIndex,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        selectedMarket,
        selectedLocation,
        monAnList,
        selectedBottomNavIndex,
        currentPage,
        hasMore,
        isLoadingMore,
      ];
}

/// State when an error occurs
class SearchResultError extends SearchResultState {
  final String message;
  final bool requiresLogin;

  const SearchResultError(this.message, {this.requiresLogin = false});

  @override
  List<Object?> get props => [message, requiresLogin];
}

/// Model kết hợp món ăn với URL ảnh và thông tin chi tiết
class MonAnWithImage {
  final MonAnModel monAn;
  final String imageUrl;
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

/// Model for search result product
class SearchResultProduct extends Equatable {
  final String name;
  final String price;
  final String salesCount;
  final String shopName;
  final String imagePath;
  final String? badge; // Optional badge like "Đang bán chạy"
  final bool isHighlighted; // Whether product has special background color

  const SearchResultProduct({
    required this.name,
    required this.price,
    required this.salesCount,
    required this.shopName,
    required this.imagePath,
    this.badge,
    this.isHighlighted = false,
  });

  @override
  List<Object?> get props => [
        name,
        price,
        salesCount,
        shopName,
        imagePath,
        badge,
        isHighlighted,
      ];
}
