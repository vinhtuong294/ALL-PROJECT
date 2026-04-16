import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'all_shops_state.dart';
import '../../../../../core/services/gian_hang_service.dart';
import '../../../../../core/dependency/injection.dart';

/// Cubit quản lý state cho All Shops Screen
class AllShopsCubit extends Cubit<AllShopsState> {
  GianHangService? _gianHangService;

  AllShopsCubit() : super(const AllShopsInitial()) {
    try {
      _gianHangService = getIt<GianHangService>();
    } catch (e) {
      debugPrint('⚠️ GianHangService not registered');
    }
  }

  /// Load tất cả gian hàng
  Future<void> loadAllShops() async {
    emit(const AllShopsLoading());

    try {
      if (_gianHangService == null) {
        throw Exception('GianHangService not available');
      }

      debugPrint('🔍 [AllShopsCubit] Loading all shops...');

      final response = await _gianHangService!.getGianHangList(
        page: 1,
        limit: 20,
        sort: 'ten_gian_hang',
        order: 'asc',
      );

      if (isClosed) return;

      final shops = response.data.map((item) {
        return ShopItem(
          maGianHang: item.maGianHang,
          tenGianHang: item.tenGianHang,
          hinhAnh: item.hinhAnh,
          viTri: item.viTri,
          danhGiaTb: item.danhGiaTb,
        );
      }).toList();

      debugPrint('✅ [AllShopsCubit] Loaded ${shops.length} shops');

      emit(AllShopsLoaded(
        shops: shops,
        currentPage: 1,
        hasMore: response.meta.hasNext,
        isLoadingMore: false,
      ));
    } catch (e) {
      debugPrint('❌ [AllShopsCubit] Error: $e');
      if (!isClosed) {
        emit(AllShopsError('Lỗi khi tải gian hàng: $e'));
      }
    }
  }

  /// Load more shops
  Future<void> loadMore() async {
    if (state is! AllShopsLoaded) return;

    final currentState = state as AllShopsLoaded;
    if (currentState.isLoadingMore || !currentState.hasMore) return;

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      if (_gianHangService == null) return;

      final nextPage = currentState.currentPage + 1;
      final response = await _gianHangService!.getGianHangList(
        page: nextPage,
        limit: 20,
        sort: 'ten_gian_hang',
        order: 'asc',
      );

      if (isClosed) return;

      final newShops = response.data.map((item) {
        return ShopItem(
          maGianHang: item.maGianHang,
          tenGianHang: item.tenGianHang,
          hinhAnh: item.hinhAnh,
          viTri: item.viTri,
          danhGiaTb: item.danhGiaTb,
        );
      }).toList();

      emit(currentState.copyWith(
        shops: [...currentState.shops, ...newShops],
        currentPage: nextPage,
        hasMore: response.meta.hasNext,
        isLoadingMore: false,
      ));
    } catch (e) {
      debugPrint('❌ [AllShopsCubit] Load more error: $e');
      if (!isClosed && state is AllShopsLoaded) {
        emit((state as AllShopsLoaded).copyWith(isLoadingMore: false));
      }
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadAllShops();
  }
}
