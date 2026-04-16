part of 'shop_cubit.dart';

/// Base class cho tất cả các state của Shop
abstract class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => [];
}

/// State khởi tạo ban đầu
class ShopInitial extends ShopState {}

/// State đang tải thông tin cửa hàng
class ShopLoading extends ShopState {}

/// State tải thông tin cửa hàng thành công
class ShopLoaded extends ShopState {
  final ShopInfo shopInfo;
  final List<ShopProduct> products;
  final int selectedTabIndex;
  final bool hasMore;
  final int currentPage;

  const ShopLoaded({
    required this.shopInfo,
    required this.products,
    this.selectedTabIndex = 0,
    this.hasMore = false,
    this.currentPage = 1,
  });

  @override
  List<Object?> get props =>
      [shopInfo, products, selectedTabIndex, hasMore, currentPage];

  ShopLoaded copyWith({
    ShopInfo? shopInfo,
    List<ShopProduct>? products,
    int? selectedTabIndex,
    bool? hasMore,
    int? currentPage,
  }) {
    return ShopLoaded(
      shopInfo: shopInfo ?? this.shopInfo,
      products: products ?? this.products,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// State đang load thêm sản phẩm
class ShopLoadingMore extends ShopState {
  final ShopInfo shopInfo;
  final List<ShopProduct> products;
  final int selectedTabIndex;

  const ShopLoadingMore({
    required this.shopInfo,
    required this.products,
    this.selectedTabIndex = 0,
  });

  @override
  List<Object?> get props => [shopInfo, products, selectedTabIndex];
}

/// State lỗi
class ShopFailure extends ShopState {
  final String errorMessage;

  const ShopFailure({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

/// State khi toggle yêu thích
class ShopProductFavoriteToggled extends ShopState {
  final String productId;
  final bool isFavorite;

  const ShopProductFavoriteToggled({
    required this.productId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [productId, isFavorite];
}

/// Model cho thông tin cửa hàng (từ API)
class ShopInfo {
  final String shopId;
  final String shopName;
  final String? shopImage;
  final double shopRating;
  final int productCount;
  final int reviewCount;
  final String viTri;
  final DateTime? ngayDangKy;
  final ShopChoInfo? cho;

  const ShopInfo({
    required this.shopId,
    required this.shopName,
    this.shopImage,
    this.shopRating = 0.0,
    this.productCount = 0,
    this.reviewCount = 0,
    this.viTri = '',
    this.ngayDangKy,
    this.cho,
  });
}

/// Model cho thông tin chợ
class ShopChoInfo {
  final String maCho;
  final String tenCho;
  final String diaChi;
  final String? hinhAnh;
  final String? phuong;

  const ShopChoInfo({
    required this.maCho,
    required this.tenCho,
    required this.diaChi,
    this.hinhAnh,
    this.phuong,
  });
}

/// Model cho sản phẩm của cửa hàng
class ShopProduct {
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final double originalPrice;
  final String unit;
  final String categoryId;
  final String categoryName;
  final double soldCount;
  final double discountPercent;
  final bool isFavorite;
  final String shopId;

  const ShopProduct({
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    this.originalPrice = 0,
    this.unit = '',
    this.categoryId = '',
    this.categoryName = '',
    this.soldCount = 0,
    this.discountPercent = 0,
    this.isFavorite = false,
    required this.shopId,
  });

  /// Kiểm tra có giảm giá không
  bool get hasDiscount => discountPercent > 0;

  /// Badge text
  String get badge {
    if (discountPercent > 0) {
      return '-${discountPercent.toStringAsFixed(0)}%';
    }
    if (soldCount > 100) {
      return 'Bán chạy';
    }
    if (soldCount > 0) {
      return 'Đã bán ${soldCount.toStringAsFixed(0)}';
    }
    return '';
  }

  ShopProduct copyWith({
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    double? originalPrice,
    String? unit,
    String? categoryId,
    String? categoryName,
    double? soldCount,
    double? discountPercent,
    bool? isFavorite,
    String? shopId,
  }) {
    return ShopProduct(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      soldCount: soldCount ?? this.soldCount,
      discountPercent: discountPercent ?? this.discountPercent,
      isFavorite: isFavorite ?? this.isFavorite,
      shopId: shopId ?? this.shopId,
    );
  }
}
