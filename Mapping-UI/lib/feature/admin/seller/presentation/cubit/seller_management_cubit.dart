import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/market_manager_service.dart';
import 'seller_management_state.dart';

class SellerManagementCubit extends Cubit<SellerManagementState> {
  final MarketManagerService _service;
  static const int _limit = 10;

  SellerManagementCubit({MarketManagerService? service})
      : _service = service ?? MarketManagerService(),
        super(const SellerManagementState());

  Future<void> loadSellers() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await _service.getSellers(page: 1, limit: _limit);

      if (response.success) {
        emit(state.copyWith(
          isLoading: false,
          sellers: response.sellers,
          currentPage: response.pagination.page,
          totalPages: response.pagination.totalPages,
          total: response.pagination.total,
          hasMore: response.pagination.hasMore,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải danh sách tiểu thương',
        ));
      }
    } catch (e) {
      debugPrint('❌ [SELLER MANAGEMENT] Error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Lỗi: ${e.toString()}',
      ));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final nextPage = state.currentPage + 1;
      final response = await _service.getSellers(page: nextPage, limit: _limit);

      if (response.success) {
        final updatedSellers = [...state.sellers, ...response.sellers];
        emit(state.copyWith(
          isLoadingMore: false,
          sellers: updatedSellers,
          currentPage: response.pagination.page,
          totalPages: response.pagination.totalPages,
          total: response.pagination.total,
          hasMore: response.pagination.hasMore,
        ));
      } else {
        emit(state.copyWith(isLoadingMore: false));
      }
    } catch (e) {
      debugPrint('❌ [SELLER MANAGEMENT] Load more error: $e');
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() async {
    await loadSellers();
  }

  Future<bool> addSeller({
    required String tenDangNhap,
    required String matKhau,
    required String tenNguoiDung,
    required String sdt,
    required String diaChi,
    required String gioiTinh,
    required String tenGianHang,
    required String viTri,
  }) async {
    try {
      final success = await _service.addSeller(
        tenDangNhap: tenDangNhap,
        matKhau: matKhau,
        tenNguoiDung: tenNguoiDung,
        sdt: sdt,
        diaChi: diaChi,
        gioiTinh: gioiTinh,
        tenGianHang: tenGianHang,
        viTri: viTri,
      );

      if (success) {
        // Reload danh sách sau khi thêm thành công
        await loadSellers();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [SELLER MANAGEMENT] Add seller error: $e');
      return false;
    }
  }
}
