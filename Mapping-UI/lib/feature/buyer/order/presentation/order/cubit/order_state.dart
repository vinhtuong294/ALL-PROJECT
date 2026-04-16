part of 'order_cubit.dart';

/// Base state cho Order
abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

/// State khởi tạo ban đầu
class OrderInitial extends OrderState {
  const OrderInitial();
}

/// State đang tải dữ liệu
class OrderLoading extends OrderState {
  const OrderLoading();
}

/// State đã tải dữ liệu thành công
class OrderLoaded extends OrderState {
  final List<Order> orders;
  final OrderFilterType filterType;
  final int pendingCount;
  final int processingCount;
  final int shippingCount;
  final int deliveredCount;

  const OrderLoaded({
    required this.orders,
    required this.filterType,
    required this.pendingCount,
    required this.processingCount,
    required this.shippingCount,
    required this.deliveredCount,
  });

  @override
  List<Object?> get props => [
        orders,
        filterType,
        pendingCount,
        processingCount,
        shippingCount,
        deliveredCount,
      ];
}

/// State thất bại
class OrderFailure extends OrderState {
  final String errorMessage;

  const OrderFailure({
    required this.errorMessage,
  });

  @override
  List<Object?> get props => [errorMessage];
}

/// Enum cho loại lọc đơn hàng
enum OrderFilterType {
  all,        // Tất cả
  pending,    // Chờ xác nhận
  processing, // Đang xử lý
  shipping,   // Đang giao
  delivered,  // Giao thành công
}

/// Extension để lấy tên hiển thị của filter
extension OrderFilterTypeExtension on OrderFilterType {
  String get displayName {
    switch (this) {
      case OrderFilterType.all:
        return 'Tất cả';
      case OrderFilterType.pending:
        return 'Chờ Xác Nhận';
      case OrderFilterType.processing:
        return 'Đang Xử Lý';
      case OrderFilterType.shipping:
        return 'Đang Giao';
      case OrderFilterType.delivered:
        return 'Giao Thành Công';
    }
  }
}

/// Enum cho trạng thái đơn hàng
enum OrderStatusType {
  pending,    // Chờ xác nhận
  processing, // Đang xử lý
  shipping,   // Đang giao
  delivered,  // Đã giao
  cancelled,  // Đã hủy
}

/// Extension cho OrderStatusType
extension OrderStatusTypeExtension on OrderStatusType {
  String get displayName {
    switch (this) {
      case OrderStatusType.pending:
        return 'Chờ xác nhận';
      case OrderStatusType.processing:
        return 'Đang xử lý';
      case OrderStatusType.shipping:
        return 'Đang giao';
      case OrderStatusType.delivered:
        return 'Đã giao';
      case OrderStatusType.cancelled:
        return 'Đã hủy';
    }
  }
}

/// Model cho đơn hàng
class Order extends Equatable {
  final String orderId;
  final String shopName;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatusType status;
  final DateTime orderDate;
  final bool isExpanded;
  final String? paymentStatus;
  final String? paymentMethod;

  const Order({
    required this.orderId,
    required this.shopName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.isExpanded = false,
    this.paymentStatus,
    this.paymentMethod,
  });

  Order copyWith({
    String? orderId,
    String? shopName,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatusType? status,
    DateTime? orderDate,
    bool? isExpanded,
    String? paymentStatus,
    String? paymentMethod,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      shopName: shopName ?? this.shopName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      orderDate: orderDate ?? this.orderDate,
      isExpanded: isExpanded ?? this.isExpanded,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  /// Check trạng thái thanh toán
  bool get isPaid => paymentStatus == 'da_thanh_toan';
  
  /// Hiển thị trạng thái thanh toán đã format
  String get paymentStatusDisplay {
    if (paymentStatus == null || paymentStatus!.isEmpty) return 'N/A';
    return StatusFormatter.formatOrderStatus(paymentStatus);
  }

  @override
  List<Object?> get props => [
        orderId,
        shopName,
        items,
        totalAmount,
        status,
        orderDate,
        isExpanded,
        paymentStatus,
        paymentMethod,
      ];
}

/// Model cho item trong đơn hàng
class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final String productImage;
  final double weight;
  final String unit;
  final double price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.weight,
    required this.unit,
    required this.price,
    required this.quantity,
  });

  double get totalPrice => price * quantity;

  @override
  List<Object?> get props => [
        productId,
        productName,
        productImage,
        weight,
        unit,
        price,
        quantity,
      ];
}
