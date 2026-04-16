import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../core/models/market_map_model.dart';
import 'update_stall_state.dart';

class UpdateStallCubit extends Cubit<UpdateStallState> {
  UpdateStallCubit({MapStoreInfo? store})
      : super(store != null
            ? UpdateStallState.fromStore(store)
            : UpdateStallState.newStall());

  void updateName(String name) {
    emit(state.copyWith(name: name));
  }

  void updateViTri(String? viTri) {
    emit(state.copyWith(viTri: viTri));
  }

  void updateGridPosition(int? row, int? col) {
    emit(state.copyWith(gridRow: row, gridCol: col));
  }

  Future<void> saveStall() async {
    if (!state.isValid) {
      emit(state.copyWith(errorMessage: 'Vui lòng điền đầy đủ thông tin'));
      return;
    }

    emit(state.copyWith(isLoading: true));

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // TODO: Call API to save stall
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể lưu gian hàng: ${e.toString()}',
      ));
    }
  }
}
