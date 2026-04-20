// File: lib/feature/shipper/data/models/shipper_order_model.dart

class ShipperOrder {
  final String maDonHang;
  final String date;
  final double totalAmount;
  final String deliveryAddress;
  final String status;
  final String? consolidationId;
  final String? buyerName;
  final String? buyerPhone;
  final String? buyerAddress;
  final String? marketName;
  final double? distanceKm;

  ShipperOrder({
    required this.maDonHang,
    required this.date,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.status,
    this.consolidationId,
    this.buyerName,
    this.buyerPhone,
    this.buyerAddress,
    this.marketName,
    this.distanceKm,
  });

  factory ShipperOrder.fromJson(Map<String, dynamic> json) {
    // Parse buyer info
    final nguoiMua = json['nguoi_mua'] as Map<String, dynamic>?;
    final gomDon = json['gom_don'] as Map<String, dynamic>?;

    return ShipperOrder(
      maDonHang: json['order_id'] ?? json['ma_don_hang'] ?? 'UNKNOWN',
      date: (json['order_time'] ?? json['order_date'] ?? json['thoi_gian_giao_hang'] ?? '').toString(),
      totalAmount: (json['total_amount'] ?? json['tong_tien'] ?? 0).toDouble(),
      deliveryAddress: json['delivery_address'] ?? json['dia_chi_giao_hang'] ?? 'Chưa rõ',
      status: json['status'] ?? json['tinh_trang_don_hang'] ?? 'pending',
      consolidationId: gomDon?['ma_gom_don'],
      buyerName: nguoiMua?['ten_nguoi_dung'],
      buyerPhone: nguoiMua?['sdt'],
      buyerAddress: nguoiMua?['dia_chi'],
      marketName: json['ten_cho'],
      distanceKm: json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null,
    );
  }
}
