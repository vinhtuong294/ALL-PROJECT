/// Model thông tin chợ từ API market-manager/market
class MarketInfoModel {
  final String maCho;
  final String tenCho;
  final String maKhuVuc;
  final String khuVuc;
  final String diaChi;
  final String hinhAnh;
  final int gridCellWidth;
  final int gridCellHeight;
  final int gridColumns;
  final int gridRows;

  MarketInfoModel({
    required this.maCho,
    required this.tenCho,
    required this.maKhuVuc,
    required this.khuVuc,
    required this.diaChi,
    required this.hinhAnh,
    required this.gridCellWidth,
    required this.gridCellHeight,
    required this.gridColumns,
    required this.gridRows,
  });

  factory MarketInfoModel.fromJson(Map<String, dynamic> json) {
    return MarketInfoModel(
      maCho: json['ma_cho'] as String? ?? '',
      tenCho: json['ten_cho'] as String? ?? '',
      maKhuVuc: json['ma_khu_vuc'] as String? ?? '',
      khuVuc: json['khu_vuc'] as String? ?? '',
      diaChi: json['dia_chi'] as String? ?? '',
      hinhAnh: json['hinh_anh'] as String? ?? '',
      gridCellWidth: (json['grid_cell_width'] as num?)?.toInt() ?? 100,
      gridCellHeight: (json['grid_cell_height'] as num?)?.toInt() ?? 100,
      gridColumns: (json['grid_columns'] as num?)?.toInt() ?? 10,
      gridRows: (json['grid_rows'] as num?)?.toInt() ?? 10,
    );
  }

  /// Tổng số ô trong sơ đồ
  int get totalCells => gridColumns * gridRows;
}

/// Response từ API market-manager/market
class MarketInfoResponse {
  final bool success;
  final MarketInfoModel? data;

  MarketInfoResponse({
    required this.success,
    this.data,
  });

  factory MarketInfoResponse.fromJson(Map<String, dynamic> json) {
    return MarketInfoResponse(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null
          ? MarketInfoModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}
