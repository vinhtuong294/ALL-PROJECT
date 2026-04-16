import 'package:equatable/equatable.dart';
import '../../../../../core/models/market_map_model.dart';

class AdminMapState extends Equatable {
  final bool isLoading;
  final bool isSavingConfig;
  final String? errorMessage;
  final String? successMessage;
  final MapMarketInfo? market;
  final MapGridInfo? grid;
  final List<MapStoreInfo> stores;
  final String? selectedStoreId;
  final double zoomLevel;

  const AdminMapState({
    this.isLoading = false,
    this.isSavingConfig = false,
    this.errorMessage,
    this.successMessage,
    this.market,
    this.grid,
    this.stores = const [],
    this.selectedStoreId,
    this.zoomLevel = 1.0,
  });

  AdminMapState copyWith({
    bool? isLoading,
    bool? isSavingConfig,
    String? errorMessage,
    String? successMessage,
    MapMarketInfo? market,
    MapGridInfo? grid,
    List<MapStoreInfo>? stores,
    String? selectedStoreId,
    double? zoomLevel,
  }) {
    return AdminMapState(
      isLoading: isLoading ?? this.isLoading,
      isSavingConfig: isSavingConfig ?? this.isSavingConfig,
      errorMessage: errorMessage,
      successMessage: successMessage,
      market: market ?? this.market,
      grid: grid ?? this.grid,
      stores: stores ?? this.stores,
      selectedStoreId: selectedStoreId ?? this.selectedStoreId,
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }

  /// Gian hàng đang được chọn
  MapStoreInfo? get selectedStore {
    if (selectedStoreId == null) return null;
    try {
      return stores.firstWhere((s) => s.maGianHang == selectedStoreId);
    } catch (e) {
      return null;
    }
  }

  /// Danh sách gian hàng đã có vị trí trên grid
  List<MapStoreInfo> get positionedStores =>
      stores.where((s) => s.hasPosition).toList();

  /// Danh sách gian hàng chưa có vị trí
  List<MapStoreInfo> get unpositionedStores =>
      stores.where((s) => !s.hasPosition).toList();

  @override
  List<Object?> get props => [
        isLoading,
        isSavingConfig,
        errorMessage,
        successMessage,
        market,
        grid,
        stores,
        selectedStoreId,
        zoomLevel,
      ];
}
