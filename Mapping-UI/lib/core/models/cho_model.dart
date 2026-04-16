class ChoModel {
  final String maCho;
  final String tenCho;
  final String maKhuVuc;
  final String tenKhuVuc;
  final String diaChi;
  final String hinhAnh;
  final int soGianHang;

  ChoModel({
    required this.maCho,
    required this.tenCho,
    required this.maKhuVuc,
    required this.tenKhuVuc,
    required this.diaChi,
    required this.hinhAnh,
    required this.soGianHang,
  });

  factory ChoModel.fromJson(Map<String, dynamic> json) {
    return ChoModel(
      maCho: (json['ma_cho'] ?? json['id'] ?? '').toString(),
      tenCho: (json['ten_cho'] ?? json['market_name'] ?? '').toString(),
      maKhuVuc: (json['ma_khu_vuc'] ?? json['district_id'] ?? '').toString(),
      tenKhuVuc: (json['ten_khu_vuc'] ?? json['district_name'] ?? '').toString(),
      diaChi: (json['dia_chi'] ?? json['address'] ?? '').toString(),
      hinhAnh: (json['hinh_anh'] ?? json['image_url'] ?? '').toString(),
      soGianHang: json['so_gian_hang'] ?? json['stall_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_cho': maCho,
      'ten_cho': tenCho,
      'ma_khu_vuc': maKhuVuc,
      'ten_khu_vuc': tenKhuVuc,
      'dia_chi': diaChi,
      'hinh_anh': hinhAnh,
      'so_gian_hang': soGianHang,
    };
  }
}

class ChoResponse {
  final List<ChoModel> data;
  final ChoMetaData meta;

  ChoResponse({
    required this.data,
    required this.meta,
  });

  factory ChoResponse.fromJson(Map<String, dynamic> json) {
    return ChoResponse(
      data: (json['data'] as List)
          .map((item) => ChoModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: ChoMetaData.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class ChoMetaData {
  final int page;
  final int limit;
  final int total;
  final bool hasNext;

  ChoMetaData({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNext,
  });

  factory ChoMetaData.fromJson(Map<String, dynamic> json) {
    return ChoMetaData(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      hasNext: json['hasNext'] ?? false,
    );
  }
}
