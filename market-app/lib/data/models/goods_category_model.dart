import 'package:equatable/equatable.dart';

class GoodsCategoryModel extends Equatable {
  final String ma;
  final String ten;

  const GoodsCategoryModel({
    required this.ma,
    required this.ten,
  });

  @override
  List<Object?> get props => [ma, ten];

  factory GoodsCategoryModel.fromJson(Map<String, dynamic> json) {
    return GoodsCategoryModel(
      ma: json['ma'] ?? '',
      ten: json['ten'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ma': ma,
      'ten': ten,
    };
  }
}

class GoodsCategoryResponse extends Equatable {
  final bool success;
  final List<GoodsCategoryModel> data;

  const GoodsCategoryResponse({
    required this.success,
    required this.data,
  });

  @override
  List<Object?> get props => [success, data];

  factory GoodsCategoryResponse.fromJson(Map<String, dynamic> json) {
    return GoodsCategoryResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => GoodsCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
