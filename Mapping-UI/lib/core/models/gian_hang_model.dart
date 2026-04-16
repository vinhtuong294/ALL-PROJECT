/// Model cho Gian Hàng (Shop)
class GianHangModel {
  final String maGianHang;
  final String tenGianHang;
  final String viTri;
  final String? hinhAnh;
  final double danhGiaTb;
  final String maCho;

  GianHangModel({
    required this.maGianHang,
    required this.tenGianHang,
    required this.viTri,
    this.hinhAnh,
    required this.danhGiaTb,
    required this.maCho,
  });

  factory GianHangModel.fromJson(Map<String, dynamic> json) {
    return GianHangModel(
      maGianHang: json['ma_gian_hang'] as String,
      tenGianHang: json['ten_gian_hang'] as String,
      viTri: json['vi_tri'] as String,
      hinhAnh: json['hinh_anh'] as String?,
      danhGiaTb: (json['danh_gia_tb'] as num?)?.toDouble() ?? 0.0,
      maCho: json['ma_cho'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_gian_hang': maGianHang,
      'ten_gian_hang': tenGianHang,
      'vi_tri': viTri,
      'hinh_anh': hinhAnh,
      'danh_gia_tb': danhGiaTb,
      'ma_cho': maCho,
    };
  }
}

/// Response model cho danh sách gian hàng
class GianHangResponse {
  final List<GianHangModel> data;
  final GianHangMeta meta;

  GianHangResponse({
    required this.data,
    required this.meta,
  });

  factory GianHangResponse.fromJson(Map<String, dynamic> json) {
    return GianHangResponse(
      data: (json['data'] as List<dynamic>)
          .map((item) => GianHangModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: GianHangMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

/// Meta information cho pagination
class GianHangMeta {
  final int page;
  final int limit;
  final int total;
  final bool hasNext;

  GianHangMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNext,
  });

  factory GianHangMeta.fromJson(Map<String, dynamic> json) {
    return GianHangMeta(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      hasNext: json['hasNext'] as bool,
    );
  }
}
