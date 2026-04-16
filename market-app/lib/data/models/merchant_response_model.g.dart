// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'merchant_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MerchantResponseModel _$MerchantResponseModelFromJson(
        Map<String, dynamic> json) =>
    MerchantResponseModel(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => MerchantModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      meta: MerchantMetaModel.fromJson(json['meta'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$MerchantResponseModelToJson(
        MerchantResponseModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
      'meta': instance.meta,
    };

MerchantMetaModel _$MerchantMetaModelFromJson(Map<String, dynamic> json) =>
    MerchantMetaModel(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      totalPages: (json['total_pages'] as num).toInt(),
    );

Map<String, dynamic> _$MerchantMetaModelToJson(MerchantMetaModel instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'total_pages': instance.totalPages,
    };
