import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/shop_api_service.dart';

part 'shop_state.dart';

/// Shop Cubit quản lý logic nghiệp vụ của trang gian hàng
/// 
/// Chức năng chính:
/// - Tải thông tin cửa hàng từ API
/// - Tải danh sách sản phẩm của cửa hàng từ API
/// - Toggle yêu thích sản phẩm
/// - Chuyển đổi tab danh mục
class ShopCubit extends Cubit<ShopState> {
  final ShopApiService _apiService = ShopApiService();

  ShopCubit() : super(ShopInitial());

  /// Tải thông tin cửa hàng và sản phẩm theo shopId (maGianHang)
  Future<void> loadShop(String shopId) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('🏪 [SHOP] Bắt đầu tải thông tin cửa hàng: $shopId');
    }

    try {
      emit(ShopLoading());

      // Fetch shop detail
      final shopDetailResponse = await _apiService.getShopDetail(shopId);
      final shopDetail = shopDetailResponse.shop;

      // Fetch shop products
      final productsResponse = await _apiService.getShopProducts(shopId);

      // Convert API response to ShopInfo
      final shopInfo = ShopInfo(
        shopId: shopDetail.maGianHang,
        shopName: shopDetail.tenGianHang,
        shopImage: shopDetail.hinhAnh ?? 'assets/img/shop_seller_1.png',
        shopRating: shopDetail.danhGia ?? 5.0,
        soldCount: shopDetail.soDonHangBan ?? 120,
        productCount: shopDetail.soMatHangBan ?? productsResponse.products.length,
        categories: const ['Tất cả', 'Gia vị', 'Thịt heo'],
      );

      // Convert API products to ShopProduct
      final products = productsResponse.products.map((apiProduct) {
        return ShopProduct(
          productId: apiProduct.maNguyenLieu,
          productName: apiProduct.tenNguyenLieu,
          productImage: apiProduct.hinhAnh ?? 'assets/img/shop_product_1.png',
          price: apiProduct.giaCuoi,
          badge: '', // Will add badge logic later
          shopId: shopId,
        );
      }).toList();

      if (AppConfig.enableApiLogging) {
        AppLogger.info('✅ [SHOP] Tải thành công: ${shopInfo.shopName}');
        AppLogger.info('   Số sản phẩm: ${products.length}');
      }

      emit(ShopLoaded(
        shopInfo: shopInfo,
        products: products,
      ));
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [SHOP] Lỗi khi tải cửa hàng: ${e.toString()}');
      }
      emit(ShopFailure(
        errorMessage: 'Không thể tải thông tin cửa hàng: ${e.toString()}',
      ));
    }
  }

  /// Toggle yêu thích sản phẩm
  void toggleProductFavorite(String productId) {
    if (state is ShopLoaded) {
      final currentState = state as ShopLoaded;
      
      // Tìm sản phẩm và toggle trạng thái yêu thích
      final updatedProducts = currentState.products.map((product) {
        if (product.productId == productId) {
          if (AppConfig.enableApiLogging) {
            AppLogger.info('❤️ [SHOP] Toggle yêu thích: $productId (${!product.isFavorite})');
          }
          return product.copyWith(isFavorite: !product.isFavorite);
        }
        return product;
      }).toList();

      emit(currentState.copyWith(products: updatedProducts));
      emit(ShopProductFavoriteToggled(
        productId: productId,
        isFavorite: updatedProducts
            .firstWhere((p) => p.productId == productId)
            .isFavorite,
      ));
    }
  }

  /// Chuyển đổi tab danh mục
  void selectCategory(int tabIndex) {
    if (state is ShopLoaded) {
      final currentState = state as ShopLoaded;
      
      if (AppConfig.enableApiLogging) {
        AppLogger.info('📂 [SHOP] Chọn tab: $tabIndex');
      }

      emit(currentState.copyWith(selectedTabIndex: tabIndex));
    }
  }

  /// Thêm sản phẩm vào giỏ hàng
  Future<void> addToCart(String productId, int quantity) async {
    if (state is ShopLoaded) {
      final currentState = state as ShopLoaded;
      final product = currentState.products
          .firstWhere((p) => p.productId == productId);

      if (AppConfig.enableApiLogging) {
        AppLogger.info('🛒 [SHOP] Thêm vào giỏ hàng: ${product.productName} x$quantity');
      }

      try {
        // TODO: Gọi API để thêm vào giỏ hàng
        await Future.delayed(const Duration(milliseconds: 300));

        if (AppConfig.enableApiLogging) {
          AppLogger.info('✅ [SHOP] Thêm giỏ hàng thành công');
        }
      } catch (e) {
        if (AppConfig.enableApiLogging) {
          AppLogger.error('❌ [SHOP] Lỗi khi thêm giỏ hàng: $e');
        }
      }
    }
  }
}
