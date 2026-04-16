class MarketMapStall {
  final String stallId;
  final String? tenGianHang;
  final String? nguoiBan;
  final int xCol;
  final int yRow;
  final String? loaiHang;
  final String? trangThai;

  MarketMapStall({
    required this.stallId,
    this.tenGianHang,
    this.nguoiBan,
    required this.xCol,
    required this.yRow,
    this.loaiHang,
    this.trangThai,
  });

  factory MarketMapStall.fromJson(Map<String, dynamic> json) {
    return MarketMapStall(
      stallId: json['stall_id'] ?? '',
      tenGianHang: json['ten_gian_hang'],
      nguoiBan: json['nguoi_ban'],
      xCol: json['x_col'] ?? 0,
      yRow: json['y_row'] ?? 0,
      loaiHang: json['loai_hang'],
      trangThai: json['trang_thai'],
    );
  }
}
