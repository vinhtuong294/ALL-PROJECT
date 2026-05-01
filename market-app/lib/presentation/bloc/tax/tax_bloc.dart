import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/market_repository.dart';
import 'tax_event.dart';
import 'tax_state.dart';

class TaxBloc extends Bloc<TaxEvent, TaxState> {
  final MarketRepository repository;

  TaxBloc({required this.repository}) : super(TaxInitial()) {
    on<LoadStallFeesEvent>(_onLoad);
    on<LoadTaxDetailEvent>(_onLoadDetail);
    on<ConfirmTaxPaymentEvent>(_onConfirmPayment);
  }

  Future<void> _onLoad(LoadStallFeesEvent event, Emitter<TaxState> emit) async {
    emit(TaxLoading());
    try {
      final result = await repository.getStallFees(
        month: event.month,
        status: event.status,
        search: event.search,
        page: event.page,
        limit: event.limit,
      );
      emit(TaxLoaded(
        fees: result.data,
        totalCollected: result.totalCollected,
        meta: result.meta,
      ));
    } catch (e) {
      emit(TaxError(_handleError(e)));
    }
  }

  Future<void> _onLoadDetail(
      LoadTaxDetailEvent event, Emitter<TaxState> emit) async {
    emit(TaxLoading());
    try {
      final result = await repository.getStallFeeDetail(event.feeId);
      emit(TaxDetailLoaded(result.data));
    } catch (e) {
      emit(TaxError(_handleError(e)));
    }
  }

  Future<void> _onConfirmPayment(
      ConfirmTaxPaymentEvent event, Emitter<TaxState> emit) async {
    emit(TaxLoading());
    try {
      final result = await repository.confirmStallFeePayment(event.feeId, {
        "payment_method": event.paymentMethod,
        "amount": event.amount,
        "note": event.note,
      });
      emit(TaxPaymentSuccess(result.message.isNotEmpty ? result.message : 'Xác nhận thành công'));
    } catch (e) {
      emit(TaxError(_handleError(e)));
    }
  }

  String _handleError(dynamic e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 401) return e.message ?? 'Phiên đăng nhập hết hạn. Vui lòng đăng xuất và đăng nhập lại.';
      if (status == 404) return 'Không tìm thấy dữ liệu (Lỗi 404). Vui lòng kiểm tra lại.';
      if (e.type == DioExceptionType.connectionTimeout) return 'Kết nối máy chủ quá hạn. Vui lòng kiểm tra mạng.';
      return e.message ?? 'Lỗi kết nối máy chủ';
    }
    return e.toString();
  }
}
