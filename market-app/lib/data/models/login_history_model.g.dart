// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginHistoryModel _$LoginHistoryModelFromJson(Map<String, dynamic> json) =>
    LoginHistoryModel(
      id: (json['id'] as num).toInt(),
      userId: json['ma_nguoi_dung'] as String,
      deviceInfo: json['thiet_bi'] as String?,
      osInfo: json['he_dieu_hanh'] as String?,
      location: json['vi_tri'] as String?,
      ipAddress: json['dia_chi_ip'] as String?,
      time: json['thoi_gian'] as String,
      success: json['thanh_cong'] as bool,
    );

Map<String, dynamic> _$LoginHistoryModelToJson(LoginHistoryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ma_nguoi_dung': instance.userId,
      'thiet_bi': instance.deviceInfo,
      'he_dieu_hanh': instance.osInfo,
      'vi_tri': instance.location,
      'dia_chi_ip': instance.ipAddress,
      'thoi_gian': instance.time,
      'thanh_cong': instance.success,
    };
