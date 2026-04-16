// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_map_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarketMapResponse _$MarketMapResponseFromJson(Map<String, dynamic> json) =>
    MarketMapResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => MarketMapStall.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MarketMapResponseToJson(MarketMapResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

MarketMapStall _$MarketMapStallFromJson(Map<String, dynamic> json) =>
    MarketMapStall(
      stallId: json['stall_id'] as String,
      tenGianHang: json['ten_gian_hang'] as String?,
      nguoiBan: json['nguoi_ban'] as String?,
      xCol: (json['x_col'] as num).toInt(),
      yRow: (json['y_row'] as num).toInt(),
      loaiHang: json['loai_hang'] as String?,
      trangThai: json['trang_thai'] as String?,
    );

Map<String, dynamic> _$MarketMapStallToJson(MarketMapStall instance) =>
    <String, dynamic>{
      'stall_id': instance.stallId,
      'ten_gian_hang': instance.tenGianHang,
      'nguoi_ban': instance.nguoiBan,
      'x_col': instance.xCol,
      'y_row': instance.yRow,
      'loai_hang': instance.loaiHang,
      'trang_thai': instance.trangThai,
    };
