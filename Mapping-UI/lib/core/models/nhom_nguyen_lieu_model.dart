import 'package:equatable/equatable.dart';

class NhomNguyenLieu extends Equatable {
  final String maNhomNguyenLieu;
  final String tenNhomNguyenLieu;
  final String loaiNhomNguyenLieu;
  final int soNguyenLieu;

  const NhomNguyenLieu({
    required this.maNhomNguyenLieu,
    required this.tenNhomNguyenLieu,
    required this.loaiNhomNguyenLieu,
    required this.soNguyenLieu,
  });

  factory NhomNguyenLieu.fromJson(Map<String, dynamic> json) {
    return NhomNguyenLieu(
      maNhomNguyenLieu: json['ma_nhom_nguyen_lieu'] ?? '',
      tenNhomNguyenLieu: json['ten_nhom_nguyen_lieu'] ?? '',
      loaiNhomNguyenLieu: (json['loai_nhom_nguyen_lieu'] ?? '').toString().trim(),
      soNguyenLieu: json['so_nguyen_lieu'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [maNhomNguyenLieu, tenNhomNguyenLieu, loaiNhomNguyenLieu, soNguyenLieu];
}

class NhomNguyenLieuResponse {
  final bool success;
  final List<NhomNguyenLieu> data;

  NhomNguyenLieuResponse({
    required this.success,
    required this.data,
  });

  factory NhomNguyenLieuResponse.fromJson(Map<String, dynamic> json) {
    return NhomNguyenLieuResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => NhomNguyenLieu.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Model nguyên liệu theo nhóm
class NguyenLieuTheoNhom extends Equatable {
  final String maNguyenLieu;
  final String tenNguyenLieu;
  final String? donVi;
  final String maNhomNguyenLieu;
  final String tenNhomNguyenLieu;

  const NguyenLieuTheoNhom({
    required this.maNguyenLieu,
    required this.tenNguyenLieu,
    this.donVi,
    required this.maNhomNguyenLieu,
    required this.tenNhomNguyenLieu,
  });

  factory NguyenLieuTheoNhom.fromJson(Map<String, dynamic> json) {
    return NguyenLieuTheoNhom(
      maNguyenLieu: json['ma_nguyen_lieu'] ?? '',
      tenNguyenLieu: json['ten_nguyen_lieu'] ?? '',
      donVi: json['don_vi'],
      maNhomNguyenLieu: json['ma_nhom_nguyen_lieu'] ?? '',
      tenNhomNguyenLieu: json['ten_nhom_nguyen_lieu'] ?? '',
    );
  }

  @override
  List<Object?> get props => [maNguyenLieu, tenNguyenLieu, donVi, maNhomNguyenLieu, tenNhomNguyenLieu];
}

class NguyenLieuTheoNhomResponse {
  final bool success;
  final List<NguyenLieuTheoNhom> data;
  final int total;
  final bool hasNext;

  NguyenLieuTheoNhomResponse({
    required this.success,
    required this.data,
    this.total = 0,
    this.hasNext = false,
  });

  factory NguyenLieuTheoNhomResponse.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>?;
    return NguyenLieuTheoNhomResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => NguyenLieuTheoNhom.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: meta?['total'] ?? 0,
      hasNext: meta?['hasNext'] ?? false,
    );
  }
}
