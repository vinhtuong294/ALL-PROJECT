import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/services/market_manager_service.dart';
import 'admin_home_state.dart';

class AdminHomeCubit extends Cubit<AdminHomeState> {
  final MarketManagerService _service;

  AdminHomeCubit({MarketManagerService? service})
      : _service = service ?? MarketManagerService(),
        super(const AdminHomeState());

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year - $hour:$minute';
  }

  Future<void> loadData() async {
    emit(state.copyWith(isLoading: true));

    try {
      // Fetch market info
      final marketInfo = await _service.getMarketInfo();
      
      // Fetch sellers to get counts
      final sellersResponse = await _service.getSellers(page: 1, limit: 1);
      
      // Count active and locked sellers from total
      final totalSellers = sellersResponse.pagination.total;

      emit(state.copyWith(
        isLoading: false,
        managerName: 'Quản lý chợ',
        marketLocation: marketInfo.data?.tenCho ?? 'Chợ',
        activeSellers: totalSellers,
        ordersToday: 0,
        lastMapUpdate: _formatDateTime(DateTime.now()),
        isMapUpdated: true,
        lockedSellers: 0,
      ));
    } catch (e) {
      debugPrint('❌ [ADMIN HOME] Error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải dữ liệu: ${e.toString()}',
      ));
    }
  }

  Future<void> updateMap() async {
    emit(state.copyWith(
      isMapUpdated: true,
      lastMapUpdate: _formatDateTime(DateTime.now()),
    ));
  }
}

