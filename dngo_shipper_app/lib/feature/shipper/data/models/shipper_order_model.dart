// File: lib/feature/shipper/data/models/shipper_order_model.dart

class ShipperOrder {
  final String maDonHang;
  final String date;
  final double totalAmount;
  final String deliveryAddress;
  final String status;

  ShipperOrder({
    required this.maDonHang,
    required this.date,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.status,
  });

  factory ShipperOrder.fromJson(Map<String, dynamic> json) {
    return ShipperOrder(
      maDonHang: json['order_id'] ?? json['ma_don_hang'] ?? 'UNKNOWN',
      date: json['order_time'] ?? json['order_date'] ?? '',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      deliveryAddress: json['delivery_address'] ?? 'Chưa rõ',
      status: json['status'] ?? json['tinh_trang_don_hang'] ?? 'pending',
    );
  }
}
