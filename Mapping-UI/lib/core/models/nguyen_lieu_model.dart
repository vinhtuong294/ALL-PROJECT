import 'package:dngo/core/config/app_config.dart';

/// Model cho Nguyên Liệu
class NguyenLieuModel {
  final String maNguyenLieu;
  final String tenNguyenLieu;
  final String? donVi;
  final String maNhomNguyenLieu;
  final String tenNhomNguyenLieu;
  final int soGianHang;
  final double? giaGoc;
  final String? giaCuoi;
  final String? ngayCapNhat;
  final String? hinhAnh;

  NguyenLieuModel({
    required this.maNguyenLieu,
    required this.tenNguyenLieu,
    this.donVi,
    required this.maNhomNguyenLieu,
    required this.tenNhomNguyenLieu,
    required this.soGianHang,
    this.giaGoc,
    this.giaCuoi,
    this.ngayCapNhat,
    this.hinhAnh,
  });

  factory NguyenLieuModel.fromJson(Map<String, dynamic> json) {
    return NguyenLieuModel(
      maNguyenLieu: (json['ma_nguyen_lieu'] ?? json['id'] ?? '').toString(),
      tenNguyenLieu: (json['ten_nguyen_lieu'] ?? json['market_name'] ?? json['name'] ?? '').toString(),
      donVi: json['don_vi']?.toString(),
      maNhomNguyenLieu: (json['ma_nhom_nguyen_lieu'] ?? json['category_id'] ?? '').toString(),
      tenNhomNguyenLieu: (json['ten_nhom_nguyen_lieu'] ?? json['category_name'] ?? '').toString(),
      soGianHang: (json['so_gian_hang'] as num?)?.toInt() ?? 0,
      giaGoc: json['gia_goc'] != null ? (json['gia_goc'] as num).toDouble() : null,
      giaCuoi: json['gia_cuoi']?.toString(),
      ngayCapNhat: json['ngay_cap_nhat']?.toString(),
      hinhAnh: _parseImageUrl(json['hinh_anh'] ?? json['image'] ?? json['img']),
    );
  }

  static String _parseImageUrl(dynamic value) {
    if (value == null || value.toString().isEmpty) return '';
    final path = value.toString();
    if (path.startsWith('http')) return path;
    final imageBaseUrl = AppConfig.imageBaseUrl;
    return '$imageBaseUrl${path.startsWith('/') ? '' : '/'}$path';
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_nguyen_lieu': maNguyenLieu,
      'ten_nguyen_lieu': tenNguyenLieu,
      'don_vi': donVi,
      'ma_nhom_nguyen_lieu': maNhomNguyenLieu,
      'ten_nhom_nguyen_lieu': tenNhomNguyenLieu,
      'so_gian_hang': soGianHang,
      'gia_goc': giaGoc,
      'gia_cuoi': giaCuoi,
      'ngay_cap_nhat': ngayCapNhat,
      'hinh_anh': hinhAnh,
    };
  }
}

/// Response model cho danh sách nguyên liệu
class NguyenLieuResponse {
  final List<NguyenLieuModel> data;
  final NguyenLieuMeta meta;

  NguyenLieuResponse({
    required this.data,
    required this.meta,
  });

  factory NguyenLieuResponse.fromJson(Map<String, dynamic> json) {
    return NguyenLieuResponse(
      data: (json['data'] as List<dynamic>? ?? [])
          .map((item) => NguyenLieuModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: json['meta'] != null 
          ? NguyenLieuMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : NguyenLieuMeta(page: 1, limit: 12, total: 0, hasNext: false),
    );
  }
}

/// Meta information cho pagination
class NguyenLieuMeta {
  final int page;
  final int limit;
  final int total;
  final bool hasNext;

  NguyenLieuMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNext,
  });

  factory NguyenLieuMeta.fromJson(Map<String, dynamic> json) {
    return NguyenLieuMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 12,
      total: (json['total'] as num?)?.toInt() ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}
