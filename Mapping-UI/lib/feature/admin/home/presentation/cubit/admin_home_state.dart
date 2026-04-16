import 'package:equatable/equatable.dart';

class AdminHomeState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String managerName;
  final String marketLocation;
  final int activeSellers;
  final int ordersToday;
  final String lastMapUpdate;
  final bool isMapUpdated;
  final int lockedSellers;

  const AdminHomeState({
    this.isLoading = false,
    this.errorMessage,
    this.managerName = 'Nguyễn Văn A',
    this.marketLocation = 'Chợ Bắc Mỹ An - Đà Nẵng',
    this.activeSellers = 42,
    this.ordersToday = 128,
    this.lastMapUpdate = '15/01/2025 - 14:30',
    this.isMapUpdated = true,
    this.lockedSellers = 3,
  });

  AdminHomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? managerName,
    String? marketLocation,
    int? activeSellers,
    int? ordersToday,
    String? lastMapUpdate,
    bool? isMapUpdated,
    int? lockedSellers,
  }) {
    return AdminHomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      managerName: managerName ?? this.managerName,
      marketLocation: marketLocation ?? this.marketLocation,
      activeSellers: activeSellers ?? this.activeSellers,
      ordersToday: ordersToday ?? this.ordersToday,
      lastMapUpdate: lastMapUpdate ?? this.lastMapUpdate,
      isMapUpdated: isMapUpdated ?? this.isMapUpdated,
      lockedSellers: lockedSellers ?? this.lockedSellers,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        managerName,
        marketLocation,
        activeSellers,
        ordersToday,
        lastMapUpdate,
        isMapUpdated,
        lockedSellers,
      ];
}

