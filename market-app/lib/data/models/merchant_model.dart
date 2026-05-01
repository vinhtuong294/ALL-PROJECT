
class MerchantModel {
  final String userId;
  final String? userName;
  final String? stallId;
  final String? stallName;
  final String? stallLocation;
  final String? status;
  final String? feeStatus;
  final String? feeId;
  final int approvalStatus;
  final String? sdt;
  final String? diaChi;
  final String? ngayTao;

  MerchantModel({
    required this.userId,
    this.userName,
    this.stallId,
    this.stallName,
    this.stallLocation,
    this.status,
    this.feeStatus,
    this.feeId,
    this.approvalStatus = 1,
    this.sdt,
    this.diaChi,
    this.ngayTao,
  });

  /// Parse JSON từ API — hỗ trợ cả 2 format:
  /// - Production server: user_id, user_name, phone, address
  /// - Local / market-app format: ma_nguoi_dung, ten_nguoi_dung, sdt, dia_chi
  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    return MerchantModel(
      userId: (json['ma_nguoi_dung'] ?? json['user_id'] ?? '') as String,
      userName: (json['ten_nguoi_dung'] ?? json['user_name']) as String?,
      stallId: (json['ma_gian_hang'] ?? json['stall_id']) as String?,
      stallName: (json['ten_gian_hang'] ?? json['stall_name']) as String?,
      stallLocation: (json['vi_tri_gian_hang'] ?? json['stall_location']) as String?,
      status: (json['tinh_trang'] ?? json['active_status']) as String?,
      feeStatus: json['fee_status'] as String?,
      feeId: json['fee_id'] as String?,
      approvalStatus: (json['approval_status'] as num?)?.toInt() ?? 1,
      sdt: (json['sdt'] ?? json['phone']) as String?,
      diaChi: (json['dia_chi'] ?? json['address']) as String?,
      ngayTao: json['ngay_tao'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'ma_nguoi_dung': userId,
    'ten_nguoi_dung': userName,
    'ma_gian_hang': stallId,
    'ten_gian_hang': stallName,
    'vi_tri_gian_hang': stallLocation,
    'tinh_trang': status,
    'fee_status': feeStatus,
    'fee_id': feeId,
    'approval_status': approvalStatus,
    'sdt': sdt,
    'dia_chi': diaChi,
    'ngay_tao': ngayTao,
  };

  String get displayName => userName ?? 'Chưa cập nhật';
  String get initial {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.split(' ').last[0].toUpperCase();
  }
  bool get isActive => status == 'hoat_dong' || status == 'mo_cua';
  bool get isTaxPaid => feeStatus == 'da_nop';
  bool get isPending => approvalStatus == 0;
}
