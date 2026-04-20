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
        emit(DashboardError(e.toString()));
      }
    });

    on<GetDashboardV2Event>((event, emit) async {
      emit(DashboardLoading());
      try {
        final dashboard = await marketRepository.getDashboardV2();
        emit(DashboardV2Success(dashboard));
      } catch (e) {
        emit(DashboardError(e.toString()));
      }
    });

    on<UpdateStallStatusEvent>((event, emit) async {
      emit(UpdateStallStatusLoading());
      try {
        final data = {
          'status': event.status,
          'note': event.note,
        };
        print('DEBUG: Updating stall status - ID: ${event.stallId}, Data: $data');
        final response = await marketRepository.updateStallStatus(event.stallId, data);
        print('DEBUG: Update response - Success: ${response.success}, Message: ${response.message}');
        
        if (response.success) {
          emit(UpdateStallStatusSuccess(response.message));
          add(GetDashboardV2Event());
        } else {
          emit(DashboardError(response.message));
        }
      } catch (e) {
        print('DEBUG: Update error: $e');
        emit(DashboardError(e.toString()));
      }
    });
  }
}
