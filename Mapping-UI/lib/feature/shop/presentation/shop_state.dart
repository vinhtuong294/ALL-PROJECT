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

  const ShopLoaded({
    required this.shopInfo,
    required this.products,
    this.selectedTabIndex = 0,
  });

  @override
  List<Object?> get props => [shopInfo, products, selectedTabIndex];

  ShopLoaded copyWith({
    ShopInfo? shopInfo,
    List<ShopProduct>? products,
    int? selectedTabIndex,
  }) {
    return ShopLoaded(
      shopInfo: shopInfo ?? this.shopInfo,
      products: products ?? this.products,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }
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

/// Model cho thông tin cửa hàng
class ShopInfo {
  final String shopId;
  final String shopName;
  final String shopImage;
  final double shopRating;
  final int soldCount;
  final int productCount;
  final List<String> categories;

  const ShopInfo({
    required this.shopId,
    required this.shopName,
    required this.shopImage,
    this.shopRating = 5.0,
    this.soldCount = 120,
    this.productCount = 30,
    this.categories = const ['Gia vị', 'Thịt heo'],
  });
}

/// Model cho sản phẩm của cửa hàng
class ShopProduct {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final String badge; // 'Flash sale', 'Đang bán chạy', 'Đã bán 129'
  final int soldCount;
  final bool isFavorite;
  final String shopId;

  const ShopProduct({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    this.badge = '',
    this.soldCount = 0,
    this.isFavorite = false,
    required this.shopId,
  });

  ShopProduct copyWith({
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    String? badge,
    int? soldCount,
    bool? isFavorite,
    String? shopId,
  }) {
    return ShopProduct(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      badge: badge ?? this.badge,
      soldCount: soldCount ?? this.soldCount,
      isFavorite: isFavorite ?? this.isFavorite,
      shopId: shopId ?? this.shopId,
    );
  }
}
