import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'order_state.dart';
import '../../../../../core/services/seller_order_service.dart';

import '../../../../../core/models/seller_order_model.dart';

/// Kết quả xác nhận đơn hàng
class ConfirmOrderResult {
  final bool success;
  final String message;
  final String? shipperName;
  final String? shipperPhone;

  ConfirmOrderResult({
    required this.success,
    required this.message,
    this.shipperName,
    this.shipperPhone,
  });
}

/// Kết quả từ chối đơn hàng
class RejectOrderResult {
  final bool success;
  final String message;
  final String? lyDoHuy;

  RejectOrderResult({
    required this.success,
    required this.message,
    this.lyDoHuy,
  });
}

class SellerOrderCubit extends Cubit<SellerOrderState> {
  final SellerOrderService _orderService = SellerOrderService();

  SellerOrderCubit() : super(SellerOrderState.initial());

  Future<void> loadOrders() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final response = await _orderService.getOrders(limit: 50);
      
      if (response.success) {
        final orders = response.items.map((item) => SellerOrder.fromApiModel(item)).toList();
        
        // Tính tổng tiền hôm nay (đơn hàng trong ngày)
        final today = DateTime.now();
        final todayOrders = response.items.where((item) {
          if (item.thoiGianGiaoHang == null) return false;
          return item.thoiGianGiaoHang!.year == today.year &&
                 item.thoiGianGiaoHang!.month == today.month &&
                 item.thoiGianGiaoHang!.day == today.day;
        });
        final totalToday = todayOrders.fold<double>(0, (sum, item) => sum + item.tongTien);

        emit(state.copyWith(
          isLoading: false,
          orders: orders,
          totalToday: totalToday,
        ));
        
        debugPrint('✅ [SELLER ORDER] Loaded ${orders.length} orders');
      } else {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải danh sách đơn hàng',
        ));
      }
    } catch (e) {
      debugPrint('❌ [SELLER ORDER] Error: $e');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách đơn hàng: $e',
      ));
    }
  }

  void selectTab(OrderStatus tab) {
    emit(state.copyWith(selectedTab: tab));
  }

  /// Xác nhận đơn hàng và trả về response
  Future<ConfirmOrderResult?> confirmOrder(String orderId) async {
    try {
      final response = await _orderService.confirmOrder(orderId);
      
      if (response.success) {
        await loadOrders();
        return ConfirmOrderResult(
          success: true,
          message: response.message,
          shipperName: response.shipperAssigned?.tenShipper,
          shipperPhone: response.shipperAssigned?.sdt,
        );
      }
      return ConfirmOrderResult(success: false, message: response.message);
    } catch (e) {
      debugPrint('❌ [SELLER ORDER] Confirm error: $e');
      return ConfirmOrderResult(success: false, message: 'Có lỗi xảy ra: $e');
    }
  }

  /// Lấy danh sách lý do từ chối
  Future<List<RejectionReason>> getRejectionReasons() async {
    try {
      final response = await _orderService.getRejectionReasons();
      if (response.success) {
        return response.reasons;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [SELLER ORDER] Get rejection reasons error: $e');
      return [];
    }
  }

  /// Từ chối đơn hàng
  Future<RejectOrderResult?> rejectOrder(String orderId, {required String reasonCode}) async {
    try {
      final response = await _orderService.rejectOrder(orderId, reasonCode: reasonCode);
      
      if (response.success) {
        await loadOrders();
        return RejectOrderResult(
          success: true,
          message: response.message,
          lyDoHuy: response.lyDoHuy,
        );
      }
      return RejectOrderResult(success: false, message: response.message);
    } catch (e) {
      debugPrint('❌ [SELLER ORDER] Reject error: $e');
      return RejectOrderResult(success: false, message: 'Có lỗi xảy ra: $e');
    }
  }

  void setSelectedNavIndex(int index) {
    emit(state.copyWith(selectedNavIndex: index));
  }
}
