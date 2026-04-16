/// Response model cho API login
class AuthResponse {
  final UserData data;
  final String token;

  AuthResponse({
    required this.data,
    required this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      data: UserData.fromJson(json['data']),
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data.toJson(),
      'token': token,
    };
  }
}

/// User data model
class UserData {
  final String sub;
  final String maNguoiDung;
  final String vaiTro;
  final String tenDangNhap;
  final String? tenNguoiDung;

  UserData({
    required this.sub,
    required this.maNguoiDung,
    required this.vaiTro,
    required this.tenDangNhap,
    this.tenNguoiDung,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      sub: json['sub'] ?? '',
      maNguoiDung: json['user_id'] ?? json['ma_nguoi_dung'] ?? json['sub'] ?? '',
      vaiTro: json['role'] ?? json['vai_tro'] ?? 'nguoi_mua',
      tenDangNhap: json['login_name'] ?? json['ten_dang_nhap'] ?? '',
      tenNguoiDung: json['user_name'] ?? json['ten_nguoi_dung'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sub': sub,
      'ma_nguoi_dung': maNguoiDung,
      'vai_tro': vaiTro,
      'ten_dang_nhap': tenDangNhap,
      'ten_nguoi_dung': tenNguoiDung,
    };
  }

  /// Getters for convenience
  bool get isNguoiMua => vaiTro == 'nguoi_mua';
  bool get isNguoiBan => vaiTro == 'nguoi_ban';
  bool get isAdmin => vaiTro == 'admin';
}
