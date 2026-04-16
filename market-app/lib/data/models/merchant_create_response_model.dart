import 'package:equatable/equatable.dart';

class MerchantCreateResponseModel extends Equatable {
  final bool success;
  final String? message;
  final MerchantCreateDataModel? data;

  const MerchantCreateResponseModel({
    required this.success,
    this.message,
    this.data,
  });

  @override
  List<Object?> get props => [success, message, data];

  factory MerchantCreateResponseModel.fromJson(Map<String, dynamic> json) {
    return MerchantCreateResponseModel(
      success: json['success'] ?? false,
      message: json['message'] as String?,
      data: json['data'] != null
          ? MerchantCreateDataModel.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MerchantCreateDataModel extends Equatable {
  final String userId;
  final String userName;
  final String stallId;
  final String stallName;

  const MerchantCreateDataModel({
    required this.userId,
    required this.userName,
    required this.stallId,
    required this.stallName,
  });

  @override
  List<Object?> get props => [userId, userName, stallId, stallName];

  factory MerchantCreateDataModel.fromJson(Map<String, dynamic> json) {
    return MerchantCreateDataModel(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      stallId: json['stall_id'] ?? '',
      stallName: json['stall_name'] ?? '',
    );
  }
}
