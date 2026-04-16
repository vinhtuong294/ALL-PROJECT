import 'package:equatable/equatable.dart';
import '../../../../../core/models/seller_order_model.dart';

enum OrderStatus {
  pending, // Chờ xác nhận (chua_xac_nhan)
  confirmed, // Đã xác nhận (da_xac_nhan)
  delivering, // Đang giao (dang_giao)
  completed, // Hoàn tất (hoan_tat)
  cancelled, // Đã hủy (da_huy)
}

/// Convert từ API status string sang enum
OrderStatus parseOrderStatus(String status) {
  switch (status) {
    case 'chua_xac_nhan':
      return OrderStatus.pending;
    case 'da_xac_nhan':
      return OrderStatus.confirmed;
    case 'dang_giao':
      return OrderStatus.delivering;
    case 'hoan_tat':
      return OrderStatus.completed;
    case 'da_huy':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}

class OrderProduct extends Equatable {
  final String maNguyenLieu;
  final String name;
  final int quantity;
  final double price;
  final double total;

  const OrderProduct({
    required this.maNguyenLieu,
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
  });

  @override
  List<Object?> get props => [maNguyenLieu, name, quantity, price, total];
}

class SellerOrder extends Equatable {
  final String id;
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String orderTime;
  final List<OrderProduct> products;
  final double amount;
  final OrderStatus status;
  final String paymentMethod;
  final bool isPaid;

  const SellerOrder({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.orderTime,
    required this.products,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.isPaid,
  });

  /// Tạo từ API model
  factory SellerOrder.fromApiModel(SellerOrderModel model) {
    return SellerOrder(
      id: model.maDonHang,
      orderId: model.maDonHang,
      customerName: model.diaChiGiaoHang?.name ?? model.nguoiMua?.tenNguoiDung ?? 'Khách hàng',
      customerPhone: model.diaChiGiaoHang?.phone ?? model.nguoiMua?.sdt ?? '',
      customerAddress: model.diaChiGiaoHang?.address ?? '',
      orderTime: _formatOrderTime(model.thoiGianGiaoHang),
      products: model.chiTietDonHang.map((item) => OrderProduct(
        maNguyenLieu: item.maNguyenLieu,
        name: item.tenNguyenLieu,
        quantity: item.soLuong,
        price: item.giaCuoi,
        total: item.thanhTien,
      )).toList(),
      amount: model.tongTien,
      status: parseOrderStatus(model.tinhTrangDonHang),
      paymentMethod: model.thanhToan?.hinhThucText ?? '',
      isPaid: model.thanhToan?.daThanhToan ?? false,
    );
  }

  static String _formatOrderTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  @override
  List<Object?> get props => [id, orderId, customerName, customerPhone, customerAddress, orderTime, products, amount, status, paymentMethod, isPaid];
}

class SellerOrderState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<SellerOrder> orders;
  final double totalToday;
  final int selectedNavIndex;
  final OrderStatus selectedTab;

  const SellerOrderState({
    this.isLoading = false,
    this.errorMessage,
    this.orders = const [],
    this.totalToday = 0,
    this.selectedNavIndex = 0,
    this.selectedTab = OrderStatus.pending,
  });

  /// Factory method để tạo state rỗng
  factory SellerOrderState.initial() {
    return const SellerOrderState(
      isLoading: true,
      selectedTab: OrderStatus.pending,
    );
  }

  SellerOrderState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<SellerOrder>? orders,
    double? totalToday,
    int? selectedNavIndex,
    OrderStatus? selectedTab,
  }) {
    return SellerOrderState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      orders: orders ?? this.orders,
      totalToday: totalToday ?? this.totalToday,
      selectedNavIndex: selectedNavIndex ?? this.selectedNavIndex,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }

  List<SellerOrder> get filteredOrders {
    if (selectedTab == OrderStatus.pending) {
      return orders.where((order) => order.status == OrderStatus.pending).toList();
    } else if (selectedTab == OrderStatus.confirmed || selectedTab == OrderStatus.delivering) {
      // Tab "Đang giao" bao gồm cả đã xác nhận và đang giao
      return orders.where((order) => 
        order.status == OrderStatus.confirmed || 
        order.status == OrderStatus.delivering
      ).toList();
    } else {
      return orders.where((order) => order.status == selectedTab).toList();
    }
  }

  int get pendingCount => orders.where((o) => o.status == OrderStatus.pending).length;
  int get deliveringCount => orders.where((o) => 
    o.status == OrderStatus.confirmed || o.status == OrderStatus.delivering
  ).length;
  int get completedCount => orders.where((o) => o.status == OrderStatus.completed).length;

  @override
  List<Object?> get props => [isLoading, errorMessage, orders, totalToday, selectedNavIndex, selectedTab];
}
