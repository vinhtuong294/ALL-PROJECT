import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/shipper_api_service.dart';
import '../../data/models/shipper_order_model.dart';
import 'package:equatable/equatable.dart';

// --- STATE ---
abstract class ShipperState extends Equatable {
  const ShipperState();

  @override
  List<Object> get props => [];
}

class ShipperInitial extends ShipperState {}
class ShipperLoading extends ShipperState {}
class ShipperLoaded extends ShipperState {
  final List<ShipperOrder> availableOrders;
  const ShipperLoaded({required this.availableOrders});

  @override
  List<Object> get props => [availableOrders];
}
class ShipperError extends ShipperState {
  final String message;
  const ShipperError(this.message);

  @override
  List<Object> get props => [message];
}

class ShipperAcceptingOrder extends ShipperState {}
class ShipperAcceptSuccess extends ShipperState {
  final String orderId;
  const ShipperAcceptSuccess(this.orderId);
  @override
  List<Object> get props => [orderId];
}

// --- CUBIT ---
class ShipperCubit extends Cubit<ShipperState> {
  final ShipperApiService apiService;

  ShipperCubit({required this.apiService}) : super(ShipperInitial());

  Future<void> fetchAvailableOrders() async {
    try {
      emit(ShipperLoading());
      final orders = await apiService.getAvailableOrders();
      emit(ShipperLoaded(availableOrders: orders));
    } catch (e) {
      emit(const ShipperError('Lỗi khi tải danh sách đơn. Vui lòng kiểm tra mạng.'));
    }
  }

  Future<void> acceptOrder(String orderId) async {
    try {
      emit(ShipperAcceptingOrder());
      final success = await apiService.acceptOrder(orderId);
      if (success) {
        emit(ShipperAcceptSuccess(orderId));
        // Tải lại danh sách sau khi lấy thành công
        fetchAvailableOrders();
      } else {
        emit(const ShipperError('Có lỗi xảy ra khi nhận đơn.'));
      }
    } catch (e) {
      emit(ShipperError(e.toString()));
      fetchAvailableOrders(); // Quay vòng lại state loaded
    }
  }
}
