// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MerchantModel _$MerchantModelFromJson(Map<String, dynamic> json) =>
    MerchantModel(
      userId: json['ma_nguoi_dung'] as String,
      userName: json['ten_nguoi_dung'] as String,
      stallId: json['ma_gian_hang'] as String?,
      stallName: json['ten_gian_hang'] as String?,
      stallLocation: json['vi_tri_gian_hang'] as String?,
      status: json['tinh_trang'] as String,
      feeStatus: json['fee_status'] as String?,
      feeId: json['fee_id'] as String?,
      approvalStatus: (json['approval_status'] as num?)?.toInt() ?? 1,
      sdt: json['sdt'] as String?,
      diaChi: json['dia_chi'] as String?,
    );

Map<String, dynamic> _$MerchantModelToJson(MerchantModel instance) =>
    <String, dynamic>{
      'ma_nguoi_dung': instance.userId,
      'ten_nguoi_dung': instance.userName,
      'ma_gian_hang': instance.stallId,
      'ten_gian_hang': instance.stallName,
      'vi_tri_gian_hang': instance.stallLocation,
      'tinh_trang': instance.status,
      'fee_status': instance.feeStatus,
      'fee_id': instance.feeId,
      'approval_status': instance.approvalStatus,
      'sdt': instance.sdt,
      'dia_chi': instance.diaChi,
    };
