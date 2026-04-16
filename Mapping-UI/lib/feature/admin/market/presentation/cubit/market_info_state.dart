import 'package:equatable/equatable.dart';
import '../../../../../core/models/market_info_model.dart';

class MarketInfoState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final MarketInfoModel? marketInfo;

  const MarketInfoState({
    this.isLoading = false,
    this.errorMessage,
    this.marketInfo,
  });

  factory MarketInfoState.initial() {
    return const MarketInfoState(isLoading: true);
  }

  MarketInfoState copyWith({
    bool? isLoading,
    String? errorMessage,
    MarketInfoModel? marketInfo,
  }) {
    return MarketInfoState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      marketInfo: marketInfo ?? this.marketInfo,
    );
  }

  @override
  List<Object?> get props => [isLoading, errorMessage, marketInfo];
}
