/// Model cho Danh Mục Nguyên Liệu
class DanhMucNguyenLieuModel {
  final String maNhomNguyenLieu;
  final String tenNhomNguyenLieu;
  final int soNguyenLieu;

  DanhMucNguyenLieuModel({
    required this.maNhomNguyenLieu,
    required this.tenNhomNguyenLieu,
    required this.soNguyenLieu,
  });

  factory DanhMucNguyenLieuModel.fromJson(Map<String, dynamic> json) {
    return DanhMucNguyenLieuModel(
      maNhomNguyenLieu: json['ma_nhom_nguyen_lieu'] as String,
      tenNhomNguyenLieu: json['ten_nhom_nguyen_lieu'] as String,
      soNguyenLieu: (json['so_nguyen_lieu'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_nhom_nguyen_lieu': maNhomNguyenLieu,
      'ten_nhom_nguyen_lieu': tenNhomNguyenLieu,
      'so_nguyen_lieu': soNguyenLieu,
    };
  }
}

/// Response model cho danh sách danh mục nguyên liệu
class DanhMucNguyenLieuResponse {
  final List<DanhMucNguyenLieuModel> data;
  final DanhMucNguyenLieuMeta meta;

  DanhMucNguyenLieuResponse({
    required this.data,
    required this.meta,
  });

  factory DanhMucNguyenLieuResponse.fromJson(Map<String, dynamic> json) {
    return DanhMucNguyenLieuResponse(
      data: (json['data'] as List<dynamic>)
          .map((item) => DanhMucNguyenLieuModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: DanhMucNguyenLieuMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

/// Meta information cho pagination
class DanhMucNguyenLieuMeta {
  final int page;
  final int limit;
  final int total;
  final bool hasNext;

  DanhMucNguyenLieuMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNext,
  });

  factory DanhMucNguyenLieuMeta.fromJson(Map<String, dynamic> json) {
    return DanhMucNguyenLieuMeta(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      hasNext: json['hasNext'] as bool,
    );
  }
}
