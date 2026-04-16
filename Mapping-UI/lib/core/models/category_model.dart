/// Model cho danh mục món ăn
class CategoryModel {
  final String maDanhMucMonAn;
  final String tenDanhMucMonAn;
  final int soMonAn;

  CategoryModel({
    required this.maDanhMucMonAn,
    required this.tenDanhMucMonAn,
    required this.soMonAn,
  });

  /// Tạo CategoryModel từ JSON
  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      maDanhMucMonAn: json['ma_danh_muc_mon_an'] ?? '',
      tenDanhMucMonAn: json['ten_danh_muc_mon_an'] ?? '',
      soMonAn: json['so_mon_an'] ?? 0,
    );
  }

  /// Chuyển CategoryModel thành JSON
  Map<String, dynamic> toJson() {
    return {
      'ma_danh_muc_mon_an': maDanhMucMonAn,
      'ten_danh_muc_mon_an': tenDanhMucMonAn,
      'so_mon_an': soMonAn,
    };
  }
}

/// Model cho thông tin phân trang
class MetaModel {
  final int page;
  final int limit;
  final int total;
  final bool hasNext;

  MetaModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.hasNext,
  });

  /// Tạo MetaModel từ JSON
  factory MetaModel.fromJson(Map<String, dynamic> json) {
    return MetaModel(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 12,
      total: json['total'] ?? 0,
      hasNext: json['hasNext'] ?? false,
    );
  }

  /// Chuyển MetaModel thành JSON
  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'hasNext': hasNext,
    };
  }
}
