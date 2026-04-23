import 'package:json_annotation/json_annotation.dart';
import 'merchant_model.dart';

part 'merchant_response_model.g.dart';

@JsonSerializable()
class MerchantResponseModel {
  final bool success;
  final List<MerchantModel> data;
  final MerchantMetaModel meta;

  MerchantResponseModel({
    required this.success,
    required this.data,
    required this.meta,
  });

  factory MerchantResponseModel.fromJson(Map<String, dynamic> json) => _$MerchantResponseModelFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantResponseModelToJson(this);
}

@JsonSerializable()
class MerchantMetaModel {
  final int page;
  final int limit;
  final int total;
  @JsonKey(name: 'total_pages')
  final int totalPages;

  MerchantMetaModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory MerchantMetaModel.fromJson(Map<String, dynamic> json) => _$MerchantMetaModelFromJson(json);
  Map<String, dynamic> toJson() => _$MerchantMetaModelToJson(this);
}
