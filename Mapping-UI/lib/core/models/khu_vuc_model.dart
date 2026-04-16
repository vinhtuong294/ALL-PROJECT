class KhuVucModel {
  final String maKhuVuc;
  final String phuong;
  final double longitude;
  final double latitude;
  final int soCho;

  KhuVucModel({
    required this.maKhuVuc,
    required this.phuong,
    required this.longitude,
    required this.latitude,
    required this.soCho,
  });

  factory KhuVucModel.fromJson(Map<String, dynamic> json) {
    return KhuVucModel(
      maKhuVuc: (json['ma_khu_vuc'] ?? json['id'] ?? '').toString(),
      phuong: (json['phuong'] ?? json['district_name'] ?? '').toString(),
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      soCho: json['so_cho'] ?? json['market_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_khu_vuc': maKhuVuc,
      'phuong': phuong,
      'longitude': longitude,
      'latitude': latitude,
      'so_cho': soCho,
    };
  }
}

class KhuVucResponse {
  final List<KhuVucModel> data;
  final MetaData meta;

  KhuVucResponse({
    required this.data,
    required this.meta,
  });

  factory KhuVucResponse.fromJson(Map<String, dynamic> json) {
    return KhuVucResponse(
      data: (json['data'] as List)
          .map((item) => KhuVucModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      meta: MetaData.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}

class MetaData {
  final int page;
  final int limit;
  final int total;
  final bool hasNext;

  MetaData({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNext,
  });

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      hasNext: json['hasNext'] ?? false,
    );
  }
}
