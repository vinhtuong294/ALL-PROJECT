import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class GetDashboardStatsEvent extends DashboardEvent {}

class GetDashboardV2Event extends DashboardEvent {}

class UpdateStallStatusEvent extends DashboardEvent {
  final String stallId;
  final String status;
  final String? note;

  const UpdateStallStatusEvent({
    required this.stallId,
    required this.status,
    this.note,
  });

  @override
  List<Object?> get props => [stallId, status, note];
}
