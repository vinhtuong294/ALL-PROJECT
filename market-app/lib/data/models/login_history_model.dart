import 'package:json_annotation/json_annotation.dart';

part 'login_history_model.g.dart';

@JsonSerializable()
class LoginHistoryModel {
  @JsonKey(name: 'id')
  final int id;
  @JsonKey(name: 'ma_nguoi_dung')
  final String userId;
  @JsonKey(name: 'thiet_bi')
  final String? deviceInfo;
  @JsonKey(name: 'he_dieu_hanh')
  final String? osInfo;
  @JsonKey(name: 'vi_tri')
  final String? location;
  @JsonKey(name: 'dia_chi_ip')
  final String? ipAddress;
  @JsonKey(name: 'thoi_gian')
  final String time;
  @JsonKey(name: 'thanh_cong')
  final bool success;

  LoginHistoryModel({
    required this.id,
    required this.userId,
    this.deviceInfo,
    this.osInfo,
    this.location,
    this.ipAddress,
    required this.time,
    required this.success,
  });

  factory LoginHistoryModel.fromJson(Map<String, dynamic> json) => _$LoginHistoryModelFromJson(json);
  Map<String, dynamic> toJson() => _$LoginHistoryModelToJson(this);
}
