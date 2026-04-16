import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'market_info_state.dart';
import '../../../../../core/services/market_manager_service.dart';

class MarketInfoCubit extends Cubit<MarketInfoState> {
  final MarketManagerService _service = MarketManagerService();

  MarketInfoCubit() : super(MarketInfoState.initial());

  Future<void> loadMarketInfo() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await _service.getMarketInfo();

      if (response.success && response.data != null) {
        emit(state.copyWith(
          isLoading: false,
          marketInfo: response.data,
        ));
        debugPrint('✅ [MARKET INFO] Loaded: ${response.data!.tenCho}');
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải thông tin chợ',
        ));
      }
    } catch (e) {
      debugPrint('❌ [MARKET INFO] Error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải thông tin chợ: $e',
      ));
    }
  }
}
