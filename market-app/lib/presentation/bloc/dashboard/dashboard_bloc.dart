import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/dashboard_stats_model.dart';
import '../../../../data/models/market_dashboard_model.dart';
import '../../../../data/models/stall_fee_model.dart';
import '../../../domain/repositories/market_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final MarketRepository marketRepository;

  DashboardBloc(this.marketRepository) : super(DashboardInitial()) {
    on<GetDashboardStatsEvent>((event, emit) async {
      emit(DashboardLoading());
      try {
        final stats = await marketRepository.getDashboardStats();
        emit(DashboardSuccess(stats));
      } catch (e) {
        emit(DashboardError(_friendlyError(e)));
      }
    });

    on<GetDashboardV2Event>((event, emit) async {
      emit(DashboardLoading());
      try {
        final dashboard = await marketRepository.getDashboardV2();
        emit(DashboardV2Success(dashboard));
      } catch (e) {
        emit(DashboardError(_friendlyError(e)));
      }
    });

    on<UpdateStallStatusEvent>((event, emit) async {
      emit(UpdateStallStatusLoading());
      try {
        final response = await marketRepository.updateStallStatus(event.stallId, {
          'status': event.status,
          'note': event.note,
        });
        if (response.success) {
          emit(UpdateStallStatusSuccess(response.message));
          add(GetDashboardV2Event());
        } else {
          emit(DashboardError(response.message));
        }
      } catch (e) {
        emit(DashboardError(_friendlyError(e)));
      }
    });
  }

  String _friendlyError(dynamic e) {
    if (e is DioException) {
      return e.message ?? 'Lỗi kết nối máy chủ';
    }
    return e.toString();
  }
}
