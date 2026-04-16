/// Model cho API /api/market-manager/map

/// Thông tin chợ trong map response
class MapMarketInfo {
  final String maCho;
  final String tenCho;
  final String diaChi;
  final String? hinhAnh;
  final int gridRows;
  final int gridColumns;

  MapMarketInfo({
    required this.maCho,
    required this.tenCho,
    required this.diaChi,
    this.hinhAnh,
    required this.gridRows,
    required this.gridColumns,
  });

  factory MapMarketInfo.fromJson(Map<String, dynamic> json) {
    return MapMarketInfo(
      maCho: json['ma_cho'] as String? ?? '',
      tenCho: json['ten_cho'] as String? ?? '',
      diaChi: json['dia_chi'] as String? ?? '',
      hinhAnh: json['hinh_anh'] as String?,
      gridRows: (json['grid_rows'] as num?)?.toInt() ?? 10,
      gridColumns: (json['grid_columns'] as num?)?.toInt() ?? 10,
    );
  }
}

/// Thông tin grid
class MapGridInfo {
  final int cellWidth;
  final int cellHeight;
  final int rows;
  final int columns;

  MapGridInfo({
    required this.cellWidth,
    required this.cellHeight,
    required this.rows,
    required this.columns,
  });

  factory MapGridInfo.fromJson(Map<String, dynamic> json) {
    return MapGridInfo(
      cellWidth: (json['cell_width'] as num?)?.toInt() ?? 100,
      cellHeight: (json['cell_height'] as num?)?.toInt() ?? 100,
      rows: (json['rows'] as num?)?.toInt() ?? 10,
      columns: (json['columns'] as num?)?.toInt() ?? 10,
    );
  }
}


/// Thông tin người dùng (chủ gian hàng)
class StoreOwnerInfo {
  final String maNguoiDung;
  final String tenNguoiDung;
  final String? sdt;

  StoreOwnerInfo({
    required this.maNguoiDung,
    required this.tenNguoiDung,
    this.sdt,
  });

  factory StoreOwnerInfo.fromJson(Map<String, dynamic> json) {
    return StoreOwnerInfo(
      maNguoiDung: json['ma_nguoi_dung'] as String? ?? '',
      tenNguoiDung: json['ten_nguoi_dung'] as String? ?? '',
      sdt: json['sdt'] as String?,
    );
  }
}

/// Thông tin gian hàng trên sơ đồ
class MapStoreInfo {
  final String maGianHang;
  final String tenGianHang;
  final String? viTri;
  final int? gridRow;
  final int? gridCol;
  final int? gridFloor;
  final String? hinhAnh;
  final double? danhGiaTb;
  final StoreOwnerInfo? nguoiDung;

  MapStoreInfo({
    required this.maGianHang,
    required this.tenGianHang,
    this.viTri,
    this.gridRow,
    this.gridCol,
    this.gridFloor,
    this.hinhAnh,
    this.danhGiaTb,
    this.nguoiDung,
  });

  factory MapStoreInfo.fromJson(Map<String, dynamic> json) {
    return MapStoreInfo(
      maGianHang: json['ma_gian_hang'] as String? ?? '',
      tenGianHang: json['ten_gian_hang'] as String? ?? '',
      viTri: json['vi_tri'] as String?,
      gridRow: json['grid_row'] as int?,
      gridCol: json['grid_col'] as int?,
      gridFloor: json['grid_floor'] as int?,
      hinhAnh: json['hinh_anh'] as String?,
      danhGiaTb: (json['danh_gia_tb'] as num?)?.toDouble(),
      nguoiDung: json['nguoi_dung'] != null
          ? StoreOwnerInfo.fromJson(json['nguoi_dung'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Kiểm tra gian hàng đã được đặt vị trí trên grid chưa
  bool get hasPosition => gridRow != null && gridCol != null;
}

/// Response từ API /api/market-manager/map
class MarketMapResponse {
  final bool success;
  final MapMarketInfo? market;
  final MapGridInfo? grid;
  final List<MapStoreInfo> stores;

  MarketMapResponse({
    required this.success,
    this.market,
    this.grid,
    this.stores = const [],
  });

  factory MarketMapResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    
    return MarketMapResponse(
      success: json['success'] as bool? ?? false,
      market: data?['market'] != null
          ? MapMarketInfo.fromJson(data!['market'] as Map<String, dynamic>)
          : null,
      grid: data?['grid'] != null
          ? MapGridInfo.fromJson(data!['grid'] as Map<String, dynamic>)
          : null,
      stores: (data?['stores'] as List<dynamic>?)
              ?.map((e) => MapStoreInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Danh sách gian hàng đã có vị trí trên grid
  List<MapStoreInfo> get positionedStores =>
      stores.where((s) => s.hasPosition).toList();

  /// Danh sách gian hàng chưa có vị trí
  List<MapStoreInfo> get unpositionedStores =>
      stores.where((s) => !s.hasPosition).toList();
}
