/// Model cho response chi tiết gian hàng
/// API: GET /api/buyer/gian-hang/{ma_gian_hang}
class ShopDetailResponse {
  final bool success;
  final ShopDetail detail;
  final ShopProductList sanPham;

  ShopDetailResponse({
    required this.success,
    required this.detail,
    required this.sanPham,
  });

  factory ShopDetailResponse.fromJson(Map<String, dynamic> json) {
    return ShopDetailResponse(
      success: json['success'] ?? false,
      detail: ShopDetail.fromJson(json['detail'] ?? {}),
      sanPham: ShopProductList.fromJson(json['san_pham'] ?? {}),
    );
  }
}

/// Model cho thông tin chi tiết gian hàng
class ShopDetail {
  final String maGianHang;
  final String tenGianHang;
  final String viTri;
  final String? hinhAnh;
  final double danhGiaTb;
  final DateTime? ngayDangKy;
  final int soSanPham;
  final int soDanhGia;
  final String tinhTrang;
  final ShopCho? cho;

  ShopDetail({
    required this.maGianHang,
    required this.tenGianHang,
    required this.viTri,
    this.hinhAnh,
    required this.danhGiaTb,
    this.ngayDangKy,
    required this.soSanPham,
    required this.soDanhGia,
    this.tinhTrang = 'dang_mo_cua',
    this.cho,
  });

  factory ShopDetail.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['tinh_trang']?.toString() ?? 'dang_mo_cua';
    // Normalize status: cả 'dang_mo_cua' và 'mo_cua' đều được coi là mở cửa
    final normalizedStatus = (rawStatus == 'mo_cua' || rawStatus == 'dang_mo_cua') 
        ? 'dang_mo_cua' 
        : 'tam_nghi';

    return ShopDetail(
      maGianHang: json['ma_gian_hang']?.toString() ?? '',
      tenGianHang: json['ten_gian_hang']?.toString() ?? '',
      viTri: json['vi_tri']?.toString() ?? '',
      hinhAnh: json['hinh_anh']?.toString(),
      danhGiaTb: _parseDouble(json['danh_gia_tb']),
      ngayDangKy: json['ngay_dang_ky'] != null
          ? DateTime.tryParse(json['ngay_dang_ky'].toString())
          : null,
      soSanPham: _parseInt(json['so_san_pham']),
      soDanhGia: _parseInt(json['so_danh_gia']),
      tinhTrang: normalizedStatus,
      cho: json['cho'] != null ? ShopCho.fromJson(json['cho']) : null,
    );
  }
}

/// Model cho thông tin chợ của gian hàng
class ShopCho {
  final String maCho;
  final String tenCho;
  final String diaChi;
  final String? hinhAnh;
  final ShopKhuVuc? khuVuc;

  ShopCho({
    required this.maCho,
    required this.tenCho,
    required this.diaChi,
    this.hinhAnh,
    this.khuVuc,
  });

  factory ShopCho.fromJson(Map<String, dynamic> json) {
    return ShopCho(
      maCho: json['ma_cho']?.toString() ?? '',
      tenCho: json['ten_cho']?.toString() ?? '',
      diaChi: json['dia_chi']?.toString() ?? '',
      hinhAnh: json['hinh_anh']?.toString(),
      khuVuc:
          json['khu_vuc'] != null ? ShopKhuVuc.fromJson(json['khu_vuc']) : null,
    );
  }
}

/// Model cho khu vực
class ShopKhuVuc {
  final String maKhuVuc;
  final String phuong;

  ShopKhuVuc({
    required this.maKhuVuc,
    required this.phuong,
  });

  factory ShopKhuVuc.fromJson(Map<String, dynamic> json) {
    return ShopKhuVuc(
      maKhuVuc: json['ma_khu_vuc']?.toString() ?? '',
      phuong: json['phuong']?.toString() ?? '',
    );
  }
}

/// Model cho danh sách sản phẩm của gian hàng
class ShopProductList {
  final List<ShopProductItem> data;
  final ShopProductMeta meta;

  ShopProductList({
    required this.data,
    required this.meta,
  });

  factory ShopProductList.fromJson(Map<String, dynamic> json) {
    return ShopProductList(
      data: (json['data'] as List<dynamic>?)
              ?.map((item) =>
                  ShopProductItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      meta: ShopProductMeta.fromJson(json['meta'] ?? {}),
    );
  }
}

/// Model cho sản phẩm trong gian hàng
class ShopProductItem {
  final String maNguyenLieu;
  final String tenNguyenLieu;
  final String donVi;
  final String maNhomNguyenLieu;
  final String tenNhomNguyenLieu;
  final String? hinhAnh;
  final double giaGoc;
  final double giaCuoi;
  final double soLuongBan;
  final double phanTramGiamGia;
  final DateTime? ngayCapNhat;

  ShopProductItem({
    required this.maNguyenLieu,
    required this.tenNguyenLieu,
    required this.donVi,
    required this.maNhomNguyenLieu,
    required this.tenNhomNguyenLieu,
    this.hinhAnh,
    required this.giaGoc,
    required this.giaCuoi,
    required this.soLuongBan,
    required this.phanTramGiamGia,
    this.ngayCapNhat,
  });

  factory ShopProductItem.fromJson(Map<String, dynamic> json) {
    return ShopProductItem(
      maNguyenLieu: json['ma_nguyen_lieu']?.toString() ?? '',
      tenNguyenLieu: json['ten_nguyen_lieu']?.toString() ?? '',
      donVi: json['don_vi']?.toString() ?? '',
      maNhomNguyenLieu: json['ma_nhom_nguyen_lieu']?.toString() ?? '',
      tenNhomNguyenLieu: json['ten_nhom_nguyen_lieu']?.toString() ?? '',
      hinhAnh: json['hinh_anh']?.toString(),
      giaGoc: _parseDouble(json['gia_goc']),
      giaCuoi: _parseDouble(json['gia_cuoi']),
      soLuongBan: _parseDouble(json['so_luong_ban']),
      phanTramGiamGia: _parseDouble(json['phan_tram_giam_gia']),
      ngayCapNhat: json['ngay_cap_nhat'] != null
          ? DateTime.tryParse(json['ngay_cap_nhat'].toString())
          : null,
    );
  }

  /// Kiểm tra có giảm giá không
  bool get hasDiscount => phanTramGiamGia > 0;
}

/// Meta cho pagination
class ShopProductMeta {
  final int page;
  final int limit;
  final int total;
  final bool hasNext;

  ShopProductMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNext,
  });

  factory ShopProductMeta.fromJson(Map<String, dynamic> json) {
    return ShopProductMeta(
      page: _parseInt(json['page'], defaultValue: 1),
      limit: _parseInt(json['limit'], defaultValue: 12),
      total: _parseInt(json['total']),
      hasNext: json['hasNext'] == true,
    );
  }
}

/// Helper function để parse double từ cả String và num
double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Helper function để parse int từ cả String và num
int _parseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}
