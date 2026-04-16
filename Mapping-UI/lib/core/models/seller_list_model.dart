/// Model cho API /api/market-manager/sellers

/// Thông tin gian hàng của tiểu thương
class SellerStallInfo {
  final String maGianHang;
  final String tenGianHang;
  final String? viTri;
  final DateTime? ngayDangKy;
  final int? gridRow;
  final int? gridCol;
  final int? gridFloor;

  SellerStallInfo({
    required this.maGianHang,
    required this.tenGianHang,
    this.viTri,
    this.ngayDangKy,
    this.gridRow,
    this.gridCol,
    this.gridFloor,
  });

  factory SellerStallInfo.fromJson(Map<String, dynamic> json) {
    return SellerStallInfo(
      maGianHang: json['ma_gian_hang'] as String? ?? '',
      tenGianHang: json['ten_gian_hang'] as String? ?? '',
      viTri: json['vi_tri'] as String?,
      ngayDangKy: json['ngay_dang_ky'] != null
          ? DateTime.tryParse(json['ngay_dang_ky'] as String)
          : null,
      gridRow: json['grid_row'] as int?,
      gridCol: json['grid_col'] as int?,
      gridFloor: json['grid_floor'] as int?,
    );
  }

  bool get hasPosition => gridRow != null && gridCol != null;
}

/// Thông tin tiểu thương
class SellerInfo {
  final String maNguoiDung;
  final String tenNguoiDung;
  final String? sdt;
  final String? diaChi;
  final bool tinhTrang;
  final List<SellerStallInfo> gianHang;

  SellerInfo({
    required this.maNguoiDung,
    required this.tenNguoiDung,
    this.sdt,
    this.diaChi,
    this.tinhTrang = false,
    this.gianHang = const [],
  });

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      maNguoiDung: json['ma_nguoi_dung'] as String? ?? '',
      tenNguoiDung: json['ten_nguoi_dung'] as String? ?? '',
      sdt: json['sdt'] as String?,
      diaChi: json['dia_chi'] as String?,
      tinhTrang: json['tinh_trang'] as bool? ?? false,
      gianHang: (json['gian_hang'] as List<dynamic>?)
              ?.map((e) => SellerStallInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Kiểm tra tiểu thương có đang hoạt động không
  bool get isActive => !tinhTrang;
}

/// Thông tin phân trang
class SellerPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  SellerPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory SellerPagination.fromJson(Map<String, dynamic> json) {
    return SellerPagination(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  bool get hasMore => page < totalPages;
}

/// Response từ API /api/market-manager/sellers
class SellerListResponse {
  final bool success;
  final List<SellerInfo> sellers;
  final SellerPagination pagination;

  SellerListResponse({
    required this.success,
    this.sellers = const [],
    required this.pagination,
  });

  factory SellerListResponse.fromJson(Map<String, dynamic> json) {
    return SellerListResponse(
      success: json['success'] as bool? ?? false,
      sellers: (json['data'] as List<dynamic>?)
              ?.map((e) => SellerInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? SellerPagination.fromJson(
              json['pagination'] as Map<String, dynamic>)
          : SellerPagination(page: 1, limit: 10, total: 0, totalPages: 1),
    );
  }
}
