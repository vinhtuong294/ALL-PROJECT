import 'package:equatable/equatable.dart';
import '../../../../../../core/models/market_map_model.dart';

class UpdateStallState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final MapStoreInfo? store;
  final String name;
  final String? viTri;
  final int? gridRow;
  final int? gridCol;
  final bool isNewStall;

  const UpdateStallState({
    this.isLoading = false,
    this.errorMessage,
    this.store,
    this.name = '',
    this.viTri,
    this.gridRow,
    this.gridCol,
    this.isNewStall = false,
  });

  UpdateStallState copyWith({
    bool? isLoading,
    String? errorMessage,
    MapStoreInfo? store,
    String? name,
    String? viTri,
    int? gridRow,
    int? gridCol,
    bool? isNewStall,
  }) {
    return UpdateStallState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      store: store ?? this.store,
      name: name ?? this.name,
      viTri: viTri ?? this.viTri,
      gridRow: gridRow ?? this.gridRow,
      gridCol: gridCol ?? this.gridCol,
      isNewStall: isNewStall ?? this.isNewStall,
    );
  }

  factory UpdateStallState.fromStore(MapStoreInfo store) {
    return UpdateStallState(
      store: store,
      name: store.tenGianHang,
      viTri: store.viTri,
      gridRow: store.gridRow,
      gridCol: store.gridCol,
      isNewStall: false,
    );
  }

  factory UpdateStallState.newStall() {
    return const UpdateStallState(
      isNewStall: true,
      name: '',
      viTri: null,
      gridRow: null,
      gridCol: null,
    );
  }

  bool get isValid {
    return name.isNotEmpty;
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        store,
        name,
        viTri,
        gridRow,
        gridCol,
        isNewStall,
      ];
}
