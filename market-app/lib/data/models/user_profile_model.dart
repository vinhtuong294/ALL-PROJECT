import 'package:equatable/equatable.dart';

class UserProfileModel extends Equatable {
  final String userId;
  final String loginName;
  final String userName;
  final String role;
  final String gender;
  final String phone;
  final String address;
  final String? bankAccount;
  final String? bankName;
  final String? marketName;
  final int approvalStatus;

  const UserProfileModel({
    required this.userId,
    required this.loginName,
    required this.userName,
    required this.role,
    required this.gender,
    required this.phone,
    required this.address,
    this.bankAccount,
    this.bankName,
    this.marketName,
    required this.approvalStatus,
  });

  @override
  List<Object?> get props => [
        userId,
        loginName,
        userName,
        role,
        gender,
        phone,
        address,
        bankAccount,
        bankName,
        marketName,
        approvalStatus
      ];

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['ma_nguoi_dung'] ?? json['user_id'] ?? '',
      loginName: json['ten_dang_nhap'] ?? json['login_name'] ?? '',
      userName: json['ten_nguoi_dung'] ?? json['user_name'] ?? '',
      role: json['vai_tro'] ?? json['role'] ?? '',
      gender: json['gioi_tinh'] ?? json['gender'] ?? 'O',
      phone: json['sdt'] ?? json['phone'] ?? '',
      address: json['dia_chi'] ?? json['address'] ?? '',
      bankAccount: json['so_tai_khoan'] ?? json['bank_account'],
      bankName: json['ngan_hang'] ?? json['bank_name'],
      marketName: json['ten_cho'] ?? json['market_name'],
      approvalStatus: json['tinh_trang'] ?? json['approval_status'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ten_nguoi_dung': userName,
      'gioi_tinh': gender,
      'sdt': phone,
      'dia_chi': address,
      'so_tai_khoan': bankAccount,
      'ngan_hang': bankName,
    };
  }
}

class UserProfileResponse extends Equatable {
  final bool success;
  final UserProfileModel data;

  const UserProfileResponse({
    required this.success,
    required this.data,
  });

  @override
  List<Object?> get props => [success, data];

  factory UserProfileResponse.fromJson(Map<String, dynamic> json) {
    return UserProfileResponse(
      success: json['success'] ?? true,
      data: UserProfileModel.fromJson(json['data'] ?? {}),
    );
  }
}
