import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/gian_hang_service.dart';
import '../../../../core/services/cart_api_service.dart';
import '../../../../core/models/shop_detail_model.dart';
import '../../../../core/dependency/injection.dart';

part 'shop_state.dart';

/// Shop Cubit quản lý logic nghiệp vụ của trang gian hàng
class ShopCubit extends Cubit<ShopState> {
  final GianHangService _gianHangService = getIt<GianHangService>();
  final CartApiService _cartApiService = CartApiService();

  String? _currentShopId;

  ShopCubit() : super(ShopInitial());

  /// Tải thông tin cửa hàng và sản phẩm theo shopId
  Future<void> loadShop(String shopId) async {
    if (AppConfig.enableApiLogging) {
      AppLogger.info('🏪 [SHOP] Bắt đầu tải thông tin cửa hàng: $shopId');
    }

    _currentShopId = shopId;

    try {
      emit(ShopLoading());

      // Gọi API để lấy thông tin cửa hàng
      final response = await _gianHangService.getShopDetail(shopId);

      if (isClosed) return;

      // Convert API response to state models
      final shopInfo = _convertToShopInfo(response.detail);
      final products = _convertToShopProducts(response.sanPham.data, shopId);

      if (AppConfig.enableApiLogging) {
        AppLogger.info('✅ [SHOP] Tải thành công: ${shopInfo.shopName}');
        AppLogger.info('   Số sản phẩm: ${products.length}');
        AppLogger.info('   Tổng sản phẩm: ${response.sanPham.meta.total}');
      }

      emit(ShopLoaded(
        shopInfo: shopInfo,
        products: products,
        hasMore: response.sanPham.meta.hasNext,
        currentPage: response.sanPham.meta.page,
      ));
    } catch (e) {
      if (AppConfig.enableApiLogging) {
        AppLogger.error('❌ [SHOP] Lỗi khi tải cửa hàng: ${e.toString()}');
      }
      if (!isClosed) {
        emit(ShopFailure(
          errorMessage: 'Không thể tải thông tin cửa hàng: ${e.toString()}',
        ));
      }
    }
  }

  /// Convert ShopDetail từ API sang ShopInfo
  ShopInfo _convertToShopInfo(ShopDetail detail) {
    ShopChoInfo? choInfo;
    if (detail.cho != null) {
      choInfo = ShopChoInfo(
        maCho: detail.cho!.maCho,
        tenCho: detail.cho!.tenCho,
        diaChi: detail.cho!.diaChi,
        hinhAnh: detail.cho!.hinhAnh,
        phuong: detail.cho!.khuVuc?.phuong,
      );
    }

    return ShopInfo(
      shopId: detail.maGianHang,
      shopName: detail.tenGianHang,
      shopImage: detail.hinhAnh,
      shopRating: detail.danhGiaTb,
      productCount: detail.soSanPham,
      reviewCount: detail.soDanhGia,
      viTri: detail.viTri,
      ngayDangKy: detail.ngayDangKy,
      cho: choInfo,
    );
  }

  /// Convert danh sách sản phẩm từ API
  List<ShopProduct> _convertToShopProducts(
      List<ShopProductItem> items, String shopId) {
    return items.map((item) {
      return ShopProduct(
        productId: item.maNguyenLieu,
        productName: item.tenNguyenLieu,
        productImage: item.hinhAnh,
        price: item.giaCuoi,
        originalPrice: item.giaGoc,
        unit: item.donVi,
        categoryId: item.maNhomNguyenLieu,
        categoryName: item.tenNhomNguyenLieu,
        soldCount: item.soLuongBan,
        discountPercent: item.phanTramGiamGia,
        shopId: shopId,
      );
    }).toList();
  }

  /// Toggle yêu thích sản phẩm
  void toggleProductFavorite(String productId) {
    if (state is ShopLoaded) {
      final currentState = state as ShopLoaded;

      final updatedProducts = currentState.products.map((product) {
        if (product.productId == productId) {
          if (AppConfig.enableApiLogging) {
            AppLogger.info(
                '❤️ [SHOP] Toggle yêu thích: $productId (${!product.isFavorite})');
          }
          return product.copyWith(isFavorite: !product.isFavorite);
        }
        return product;
      }).toList();

      emit(currentState.copyWith(products: updatedProducts));
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
  Future<bool> addToCart(String productId, int quantity) async {
    if (state is ShopLoaded && _currentShopId != null) {
      final currentState = state as ShopLoaded;
      final product =
          currentState.products.firstWhere((p) => p.productId == productId);

      if (AppConfig.enableApiLogging) {
        AppLogger.info(
            '🛒 [SHOP] Thêm vào giỏ hàng: ${product.productName} x$quantity');
      }

      try {
        await _cartApiService.addToCart(
          maNguyenLieu: productId,
          maGianHang: _currentShopId!,
          soLuong: quantity.toDouble(),
        );

        if (AppConfig.enableApiLogging) {
          AppLogger.info('✅ [SHOP] Thêm giỏ hàng thành công');
        }
        return true;
      } catch (e) {
        if (AppConfig.enableApiLogging) {
          AppLogger.error('❌ [SHOP] Lỗi khi thêm giỏ hàng: $e');
        }
        return false;
      }
    }
    return false;
  }
}
