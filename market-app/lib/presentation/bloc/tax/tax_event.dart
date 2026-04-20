import 'package:equatable/equatable.dart';

abstract class TaxEvent extends Equatable {
  const TaxEvent();
  @override
  List<Object?> get props => [];
}

class LoadStallFeesEvent extends TaxEvent {
  final String? month;      // "YYYY-MM"
  final String? status;     // da_nop / chua_nop / null
  final String? search;
  final int page;
  final int limit;

  const LoadStallFeesEvent({
    this.month,
    this.status,
    this.search,
    this.page = 1,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [month, status, search, page, limit];
}

class LoadTaxDetailEvent extends TaxEvent {
  final String feeId;

  const LoadTaxDetailEvent({required this.feeId});

  @override
  List<Object?> get props => [feeId];
}

class ConfirmTaxPaymentEvent extends TaxEvent {
  final String feeId;
  final String paymentMethod;
  final double amount;
  final String? note;

  const ConfirmTaxPaymentEvent({
    required this.feeId,
    required this.paymentMethod,
    required this.amount,
    this.note,
  });

  @override
  List<Object?> get props => [feeId, paymentMethod, amount, note];
}
