import 'package:equatable/equatable.dart';
import '../../../../data/models/dashboard_stats_model.dart';
import '../../../../data/models/market_dashboard_model.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardSuccess extends DashboardState {
  final DashboardStatsModel stats;

  const DashboardSuccess(this.stats);

  @override
  List<Object> get props => [stats];
}

class DashboardV2Success extends DashboardState {
  final MarketDashboardModel dashboard;

  const DashboardV2Success(this.dashboard);

  @override
  List<Object> get props => [dashboard];
}

class UpdateStallStatusLoading extends DashboardState {}

class UpdateStallStatusSuccess extends DashboardState {
  final String message;

  const UpdateStallStatusSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object> get props => [message];
}
