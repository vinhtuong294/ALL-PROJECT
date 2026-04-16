import '../config/app_config.dart';

/// Model chi tiết món ăn từ API
/// API: GET /api/buyer/mon-an/{ma_mon_an}
/// Response JSON: { "success": true, "detail": {...} }
class MonAnDetailModel {
  final String maMonAn;
  final String tenMonAn;
  final String hinhAnh; // URL ảnh món ăn
  final int? khoangThoiGian; // Thời gian nấu (phút)
  final String? doKho; // Độ khó: "Dễ", "Trung bình", "Khó"
  final int? khauPhanTieuChuan; // Số khẩu phần tiêu chuẩn
  final int? khauPhanHienTai; // Số khẩu phần hiện tại (khi có parameter khau_phan)
  final String? cachThucHien; // Cách thực hiện (hướng dẫn nấu)
  final String? soChe; // Số chế (cách chế biến)
  final String? cachDung; // Cách dùng
  final int? calories; // Calories gốc
  final int? caloriesGoc; // Calories gốc (khi có khẩu phần)
  final int? caloriesMoiKhauPhan; // Calories mỗi khẩu phần
  final int? caloriesTongTheoKhauPhan; // Tổng calories theo khẩu phần
  final int? soDanhMuc; // Số lượng danh mục
  final int? soNguyenLieu; // Số lượng nguyên liệu
  final List<DanhMucDetail>? danhMuc; // Danh sách danh mục
  final List<NguyenLieuDetail>? nguyenLieu; // Danh sách nguyên liệu

  MonAnDetailModel({
    required this.maMonAn,
    required this.tenMonAn,
    required this.hinhAnh,
    this.khoangThoiGian,
    this.doKho,
    this.khauPhanTieuChuan,
    this.khauPhanHienTai,
    this.cachThucHien,
    this.soChe,
    this.cachDung,
    this.calories,
    this.caloriesGoc,
    this.caloriesMoiKhauPhan,
    this.caloriesTongTheoKhauPhan,
    this.soDanhMuc,
    this.soNguyenLieu,
    this.danhMuc,
    this.nguyenLieu,
  });

  /// Parse từ JSON response
  /// Cấu trúc: { "success": true, "detail": {...} }
  factory MonAnDetailModel.fromJson(Map<String, dynamic> json) {
    // Lấy object detail từ response
    final detail = json['detail'] as Map<String, dynamic>? ?? json['data'] as Map<String, dynamic>? ?? json;
    
    return MonAnDetailModel(
      maMonAn: (detail['ma_mon_an'] ?? detail['id'] ?? detail['dish_id'] ?? '').toString(),
      tenMonAn: (detail['ten_mon_an'] ?? detail['dish_name'] ?? detail['market_name'] ?? detail['name'] ?? '').toString(),
      hinhAnh: _parseImageUrl(detail['hinh_anh_moi_nhat'] ?? detail['hinh_anh'] ?? detail['image'] ?? detail['img']),
      khoangThoiGian: (detail['khoang_thoi_gian'] as num?)?.toInt(),
      doKho: detail['do_kho']?.toString(),
      khauPhanTieuChuan: (detail['khau_phan_tieu_chuan'] as num?)?.toInt(),
      khauPhanHienTai: (detail['khau_phan_hien_tai'] as num?)?.toInt(),
      cachThucHien: detail['cach_thuc_hien']?.toString(),
      soChe: detail['so_che']?.toString(),
      cachDung: detail['cach_dung']?.toString(),
      calories: (detail['calories'] as num?)?.toInt(),
      caloriesGoc: (detail['calories_goc'] as num?)?.toInt(),
      caloriesMoiKhauPhan: (detail['calories_moi_khau_phan'] as num?)?.toInt(),
      caloriesTongTheoKhauPhan: (detail['calories_tong_theo_khau_phan'] as num?)?.toInt(),
      soDanhMuc: (detail['so_danh_muc'] as num?)?.toInt(),
      soNguyenLieu: (detail['so_nguyen_lieu'] as num?)?.toInt(),
      danhMuc: detail['danh_muc'] is List 
          ? (detail['danh_muc'] as List<dynamic>)
              .map((item) => DanhMucDetail.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
      nguyenLieu: detail['nguyen_lieu'] is List
          ? (detail['nguyen_lieu'] as List<dynamic>)
              .map((item) => NguyenLieuDetail.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  /// Convert sang JSON
  Map<String, dynamic> toJson() {
    return {
      'ma_mon_an': maMonAn,
      'ten_mon_an': tenMonAn,
      'hinh_anh': hinhAnh,
      'khoang_thoi_gian': khoangThoiGian,
      'do_kho': doKho,
      'khau_phan_tieu_chuan': khauPhanTieuChuan,
      'khau_phan_hien_tai': khauPhanHienTai,
      'cach_thuc_hien': cachThucHien,
      'so_che': soChe,
      'cach_dung': cachDung,
      'calories': calories,
      'calories_goc': caloriesGoc,
      'calories_moi_khau_phan': caloriesMoiKhauPhan,
      'calories_tong_theo_khau_phan': caloriesTongTheoKhauPhan,
      'so_danh_muc': soDanhMuc,
      'so_nguyen_lieu': soNguyenLieu,
      'danh_muc': danhMuc?.map((item) => item.toJson()).toList(),
      'nguyen_lieu': nguyenLieu?.map((item) => item.toJson()).toList(),
    };
  }
}

/// Model danh mục trong chi tiết món ăn
class DanhMucDetail {
  final String? maDanhMuc;
  final String? tenDanhMuc;

  DanhMucDetail({
    this.maDanhMuc,
    this.tenDanhMuc,
  });

  factory DanhMucDetail.fromJson(Map<String, dynamic> json) {
    return DanhMucDetail(
      maDanhMuc: json['ma_danh_muc_mon_an'] as String? ?? json['ma_danh_muc'] as String?,
      tenDanhMuc: json['ten_danh_muc_mon_an'] as String? ?? json['ten_danh_muc'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_danh_muc': maDanhMuc,
      'ten_danh_muc': tenDanhMuc,
    };
  }
}

/// Model nguyên liệu trong chi tiết món ăn
class NguyenLieuDetail {
  final String? maNguyenLieu; // Mã nguyên liệu để navigate
  final String? tenNguyenLieu; // VD: "đỏ"
  final String? donViGoc; // VD: null hoặc "gram"
  final String? dinhLuong; // VD: "50\r"
  final String? hinhAnh; // URL hình ảnh nguyên liệu
  final double? gia; // Giá nguyên liệu
  final String? donViBan; // Đơn vị bán (VD: "kg", "gram")
  final double? soLuongBan; // Số lượng bán
  final int? soGianHang; // Số gian hàng bán nguyên liệu này
  final List<GianHangInfo>? gianHang; // Danh sách gian hàng

  NguyenLieuDetail({
    this.maNguyenLieu,
    this.tenNguyenLieu,
    this.donViGoc,
    this.dinhLuong,
    this.hinhAnh,
    this.gia,
    this.donViBan,
    this.soLuongBan,
    this.soGianHang,
    this.gianHang,
  });

  factory NguyenLieuDetail.fromJson(Map<String, dynamic> json) {
    return NguyenLieuDetail(
      maNguyenLieu: (json['ma_nguyen_lieu'] ?? json['ingredient_id'] ?? json['id'] ?? '').toString(),
      tenNguyenLieu: (json['ten_nguyen_lieu'] ?? json['ingredient_name'] ?? json['name'] ?? '').toString(),
      donViGoc: json['don_vi_goc']?.toString() ?? json['unit']?.toString(),
      dinhLuong: json['dinh_luong']?.toString() ?? json['quantity']?.toString(),
      hinhAnh: _parseImageUrl(json['hinh_anh_moi_nhat'] ?? json['hinh_anh'] ?? json['image'] ?? json['img']),
      gia: _parseDouble(json['gia_cuoi']) ?? _parseDouble(json['gia_goc']) ?? _parseDouble(json['gia']),
      donViBan: json['don_vi_ban'] as String?,
      soLuongBan: _parseDouble(json['so_luong_ban']),
      soGianHang: (json['so_gian_hang'] as num?)?.toInt(),
      gianHang: (json['gian_hang'] as List<dynamic>?)
          ?.map((item) => GianHangInfo.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_nguyen_lieu': maNguyenLieu,
      'ten_nguyen_lieu': tenNguyenLieu,
      'don_vi_goc': donViGoc,
      'dinh_luong': dinhLuong,
      'hinh_anh': hinhAnh,
      'gia': gia,
      'don_vi_ban': donViBan,
      'so_luong_ban': soLuongBan,
      'so_gian_hang': soGianHang,
      'gian_hang': gianHang?.map((item) => item.toJson()).toList(),
    };
  }
}

/// Model thông tin gian hàng trong nguyên liệu
class GianHangInfo {
  final String? maGianHang;
  final String? tenGianHang;
  final String? maCho;
  final String? tinhTrang;

  GianHangInfo({
    this.maGianHang,
    this.tenGianHang,
    this.maCho,
    this.tinhTrang,
  });

  /// Kiểm tra gian hàng có đang mở cửa không
  bool get isMoCua => tinhTrang == 'dang_mo_cua' || tinhTrang == null;

  factory GianHangInfo.fromJson(Map<String, dynamic> json) {
    return GianHangInfo(
      maGianHang: json['ma_gian_hang'] as String?,
      tenGianHang: json['ten_gian_hang'] as String?,
      maCho: json['ma_cho'] as String?,
      tinhTrang: json['tinh_trang'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma_gian_hang': maGianHang,
      'ten_gian_hang': tenGianHang,
      'ma_cho': maCho,
      'tinh_trang': tinhTrang,
    };
  }
}

String _parseImageUrl(dynamic value) {
  if (value == null || value.toString().isEmpty) return '';
  final path = value.toString();
  if (path.startsWith('http')) return path;
  return '${AppConfig.imageBaseUrl}${path.startsWith('/') ? '' : '/'}$path';
}
