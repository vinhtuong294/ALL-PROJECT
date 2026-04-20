import 'package:equatable/equatable.dart';
import '../../../data/models/stall_fee_model.dart';

abstract class TaxState extends Equatable {
  const TaxState();
  @override
  List<Object?> get props => [];
}

class TaxInitial extends TaxState {}

class TaxLoading extends TaxState {}

class TaxLoaded extends TaxState {
  final List<StallFeeModel> fees;
  final double totalCollected;
  final StallFeeMetaModel meta;

  const TaxLoaded({
    required this.fees,
    required this.totalCollected,
    required this.meta,
  });

  @override
  List<Object?> get props => [fees, totalCollected, meta];
}

class TaxError extends TaxState {
  final String message;
  const TaxError(this.message);
  @override
  List<Object?> get props => [message];
}

class TaxDetailLoaded extends TaxState {
  final StallFeeDetailModel detail;
  const TaxDetailLoaded(this.detail);
  @override
  List<Object?> get props => [detail];
}

class TaxPaymentSuccess extends TaxState {
  final String message;
  const TaxPaymentSuccess(this.message);
  @override
  List<Object?> get props => [message];
}
