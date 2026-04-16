import '../config/app_config.dart';

/// Model cho chi tiết nguyên liệu
class NguyenLieuDetailModel {
  final String maNguyenLieu;
  final String tenNguyenLieu;
  final String? donVi;
  final String maNhomNguyenLieu;
  final String tenNhomNguyenLieu;
  final int soGianHang;
  final double? giaGoc;
  final String? giaCuoi;
  final String? ngayCapNhatMoiNhat;
  final String? hinhAnh;

  NguyenLieuDetailModel({
    required this.maNguyenLieu,
    required this.tenNguyenLieu,
    this.donVi,
    required this.maNhomNguyenLieu,
    required this.tenNhomNguyenLieu,
    required this.soGianHang,
    this.giaGoc,
    this.giaCuoi,
    this.ngayCapNhatMoiNhat,
    this.hinhAnh,
  });

  factory NguyenLieuDetailModel.fromJson(Map<String, dynamic> json) {
    return NguyenLieuDetailModel(
      maNguyenLieu: (json['ma_nguyen_lieu'] ?? json['id'] ?? '').toString(),
      tenNguyenLieu: (json['ten_nguyen_lieu'] ?? json['name'] ?? '').toString(),
      donVi: json['don_vi']?.toString(),
      maNhomNguyenLieu: (json['ma_nhom_nguyen_lieu'] ?? json['category_id'] ?? '').toString(),
      tenNhomNguyenLieu: (json['ten_nhom_nguyen_lieu'] ?? json['category_name'] ?? '').toString(),
      soGianHang: (json['so_gian_hang'] as num?)?.toInt() ?? 0,
      giaGoc: json['gia_goc'] != null ? (json['gia_goc'] as num).toDouble() : null,
      giaCuoi: json['gia_cuoi']?.toString(),
      ngayCapNhatMoiNhat: json['ngay_cap_nhat_moi_nhat']?.toString() ?? json['ngay_cap_nhat']?.toString(),
      hinhAnh: _parseImageUrl(json['hinh_anh_moi_nhat'] ?? json['hinh_anh'] ?? json['image']),
    );
  }
}

/// Model cho người bán (seller)
class SellerModel {
  final String maGianHang;
  final String tenGianHang;
  final String viTri;
  final String maCho;
  final double? giaGoc;
  final String? giaCuoi;
  final String? hinhAnh;
  final String? ngayCapNhat;
  final int soLuongBan; // Số lượng: > 0 còn hàng, <= 0 hết hàng
  final String? donViBan;
  final String tinhTrang; // "dang_mo_cua" hoặc "tam_nghi"

  SellerModel({
    required this.maGianHang,
    required this.tenGianHang,
    required this.viTri,
    required this.maCho,
    this.giaGoc,
    this.giaCuoi,
    this.hinhAnh,
    this.ngayCapNhat,
    required this.soLuongBan,
    this.donViBan,
    this.tinhTrang = 'dang_mo_cua',
  });

  /// Kiểm tra còn hàng không (so_luong_ban > 0 = còn hàng)
  bool get conHang => soLuongBan > 0;

  /// Kiểm tra gian hàng có đang mở cửa không
  bool get isMoCua => tinhTrang == 'dang_mo_cua';

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    return SellerModel(
      maGianHang: (json['ma_gian_hang'] ?? json['id'] ?? '').toString(),
      tenGianHang: (json['ten_gian_hang'] ?? json['shop_name'] ?? '').toString(),
      viTri: (json['vi_tri'] ?? json['location'] ?? '').toString(),
      maCho: (json['ma_cho'] ?? json['market_id'] ?? '').toString(),
      giaGoc: json['gia_goc'] != null ? (json['gia_goc'] as num).toDouble() : null,
      giaCuoi: json['gia_cuoi']?.toString(),
      hinhAnh: _parseImageUrl(json['hinh_anh']),
      ngayCapNhat: json['ngay_cap_nhat']?.toString(),
      soLuongBan: (json['so_luong_ban'] as num?)?.toInt() ?? 0,
      donViBan: json['don_vi_ban']?.toString(),
      tinhTrang: json['tinh_trang']?.toString() ?? 'dang_mo_cua',
    );
  }
}

/// Response model cho chi tiết nguyên liệu
class NguyenLieuDetailResponse {
  final bool success;
  final NguyenLieuDetailModel data;
  final SellersData sellers;

  NguyenLieuDetailResponse({
    required this.success,
    required this.data,
    required this.sellers,
  });

  factory NguyenLieuDetailResponse.fromJson(Map<String, dynamic> json) {
    return NguyenLieuDetailResponse(
      success: json['success'] as bool? ?? true,
      data: NguyenLieuDetailModel.fromJson(json['detail'] as Map<String, dynamic>? ?? json['data'] as Map<String, dynamic>? ?? {}),
      sellers: SellersData.fromJson(json['sellers'] as Map<String, dynamic>? ?? json['data'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Sellers data với pagination
class SellersData {
  final List<SellerModel> data;
  final SellersMeta meta;

  SellersData({
    required this.data,
    required this.meta,
  });

  factory SellersData.fromJson(Map<String, dynamic> json) {
    return SellersData(
      data: (json['data'] as List<dynamic>)
          .map((item) => SellerModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: SellersMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

/// Meta information cho sellers pagination
class SellersMeta {
  final int page;
  final int limit;
  final int total;
  final bool hasNext;

  SellersMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNext,
  });

  factory SellersMeta.fromJson(Map<String, dynamic> json) {
    return SellersMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 12,
      total: (json['total'] as num?)?.toInt() ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}

String _parseImageUrl(dynamic value) {
  if (value == null || value.toString().isEmpty) return '';
  final path = value.toString();
  if (path.startsWith('http')) return path;
  return '${AppConfig.imageBaseUrl}${path.startsWith('/') ? '' : '/'}$path';
}
