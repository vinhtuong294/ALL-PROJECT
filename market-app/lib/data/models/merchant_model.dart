import 'package:json_annotation/json_annotation.dart';

part 'merchant_model.g.dart';

@JsonSerializable()
class MerchantModel {
  @JsonKey(name: 'ma_nguoi_dung')
  final String userId;
  @JsonKey(name: 'ten_nguoi_dung')
  final String userName;
  @JsonKey(name: 'ma_gian_hang')
  final String? stallId;
  @JsonKey(name: 'ten_gian_hang')
  final String? stallName;
  @JsonKey(name: 'vi_tri_gian_hang')
  final String? stallLocation;
  @JsonKey(name: 'tinh_trang')
  final String status;
  @JsonKey(name: 'fee_status')
  final String? feeStatus;
  @JsonKey(name: 'fee_id')
  final String? feeId;
  @JsonKey(name: 'approval_status')
  final int approvalStatus;
  @JsonKey(name: 'sdt')
  final String? sdt;
  @JsonKey(name: 'dia_chi')
  final String? diaChi;

  MerchantModel({
    required this.userId,
    required this.userName,
    this.stallId,
    this.stallName,
    this.stallLocation,
    required this.status,
    this.feeStatus,
    this.feeId,
    this.approvalStatus = 1,
    this.sdt,
    this.diaChi,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) => _$MerchantModelFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantModelToJson(this);

  String get initial => userName.isNotEmpty ? userName.trim().split(' ').last[0].toUpperCase() : '?';
  bool get isActive => status == 'hoat_dong';
  bool get isTaxPaid => feeStatus == 'da_nop';
  bool get isPending => approvalStatus == 0;
}
