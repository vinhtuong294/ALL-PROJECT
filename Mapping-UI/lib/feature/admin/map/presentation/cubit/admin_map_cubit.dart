import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/market_manager_service.dart';
import 'admin_map_state.dart';

class AdminMapCubit extends Cubit<AdminMapState> {
  final MarketManagerService _marketManagerService;

  AdminMapCubit({MarketManagerService? marketManagerService})
      : _marketManagerService = marketManagerService ?? MarketManagerService(),
        super(const AdminMapState());

  Future<void> loadMapData() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await _marketManagerService.getMapData();

      if (response.success) {
        emit(state.copyWith(
          isLoading: false,
          market: response.market,
          grid: response.grid,
          stores: response.stores,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải dữ liệu sơ đồ',
        ));
      }
    } catch (e) {
      debugPrint('❌ [ADMIN MAP] Error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải dữ liệu sơ đồ: ${e.toString()}',
      ));
    }
  }

  void selectStore(String? storeId) {
    emit(state.copyWith(selectedStoreId: storeId));
  }

  void clearSelection() {
    emit(state.copyWith(selectedStoreId: null));
  }

  void clearMessages() {
    emit(state.copyWith(errorMessage: null, successMessage: null));
  }

  void zoomIn() {
    if (state.zoomLevel < 2.0) {
      emit(state.copyWith(zoomLevel: state.zoomLevel + 0.2));
    }
  }

  void zoomOut() {
    if (state.zoomLevel > 0.5) {
      emit(state.copyWith(zoomLevel: state.zoomLevel - 0.2));
    }
  }

  void resetZoom() {
    emit(state.copyWith(zoomLevel: 1.0));
  }

  Future<bool> updateGridConfig({
    required int cellWidth,
    required int cellHeight,
    required int columns,
    required int rows,
  }) async {
    emit(state.copyWith(isSavingConfig: true, errorMessage: null, successMessage: null));

    try {
      final success = await _marketManagerService.updateGridConfig(
        gridCellWidth: cellWidth,
        gridCellHeight: cellHeight,
        gridColumns: columns,
        gridRows: rows,
      );

      if (success) {
        emit(state.copyWith(
          isSavingConfig: false,
          successMessage: 'Cập nhật cấu hình thành công',
        ));
        // Reload map data to get updated grid
        await loadMapData();
        return true;
      } else {
        emit(state.copyWith(
          isSavingConfig: false,
          errorMessage: 'Không thể cập nhật cấu hình',
        ));
        return false;
      }
    } catch (e) {
      debugPrint('❌ [ADMIN MAP] Update config error: $e');
      emit(state.copyWith(
        isSavingConfig: false,
        errorMessage: 'Lỗi cập nhật cấu hình: ${e.toString()}',
      ));
      return false;
    }
  }

  Future<bool> updateStorePosition({
    required String maGianHang,
    required int gridRow,
    required int gridCol,
  }) async {
    emit(state.copyWith(isSavingConfig: true, errorMessage: null, successMessage: null));

    try {
      final success = await _marketManagerService.updateStorePosition(
        maGianHang: maGianHang,
        gridRow: gridRow,
        gridCol: gridCol,
      );

      if (success) {
        emit(state.copyWith(
          isSavingConfig: false,
          successMessage: 'Đã cập nhật vị trí gian hàng',
        ));
        // Reload map data to get updated positions
        await loadMapData();
        return true;
      } else {
        emit(state.copyWith(
          isSavingConfig: false,
          errorMessage: 'Không thể cập nhật vị trí',
        ));
        return false;
      }
    } catch (e) {
      debugPrint('❌ [ADMIN MAP] Update position error: $e');
      emit(state.copyWith(
        isSavingConfig: false,
        errorMessage: 'Lỗi cập nhật vị trí: ${e.toString()}',
      ));
      return false;
    }
  }
}
