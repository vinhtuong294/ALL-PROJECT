import 'package:equatable/equatable.dart';

class StallFeeModel extends Equatable {
  final String stallId;
  final String stallName;
  final String userName;
  final double fee;
  final String feeStatus; // da_nop / chua_nop
  final String? feeId;
  final DateTime? paymentTime;

  const StallFeeModel({
    required this.stallId,
    required this.stallName,
    required this.userName,
    required this.fee,
    required this.feeStatus,
    this.feeId,
    this.paymentTime,
  });

  bool get isPaid => feeStatus == 'da_nop';

  @override
  List<Object?> get props => [stallId, stallName, userName, fee, feeStatus, feeId, paymentTime];

  factory StallFeeModel.fromJson(Map<String, dynamic> json) {
    return StallFeeModel(
      stallId: json['stall_id'] ?? '',
      stallName: json['stall_name'] ?? '',
      userName: json['user_name'] ?? '',
      fee: (json['fee'] ?? 0.0).toDouble(),
      feeStatus: json['fee_status'] ?? 'chua_nop',
      feeId: json['fee_id'],
      paymentTime: json['payment_time'] != null ? DateTime.parse(json['payment_time']) : null,
    );
  }
}

class StallFeeMetaModel extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final String month;

  const StallFeeMetaModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.month,
  });

  @override
  List<Object?> get props => [page, limit, total, totalPages, month];

  factory StallFeeMetaModel.fromJson(Map<String, dynamic> json) {
    return StallFeeMetaModel(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['total_pages'] ?? 1,
      month: json['month'] ?? '',
    );
  }
}

class StallFeeListResponse extends Equatable {
  final bool success;
  final List<StallFeeModel> data;
  final double totalCollected;
  final StallFeeMetaModel meta;

  const StallFeeListResponse({
    required this.success,
    required this.data,
    required this.totalCollected,
    required this.meta,
  });

  @override
  List<Object?> get props => [success, data, totalCollected, meta];

  factory StallFeeListResponse.fromJson(Map<String, dynamic> json) {
    return StallFeeListResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => StallFeeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCollected: (json['total_collected'] ?? 0.0).toDouble(),
      meta: StallFeeMetaModel.fromJson(
          json['meta'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class StallFeeDetailModel extends Equatable {
  final String feeId;
  final String stallId;
  final String stallName;
  final String userName;
  final String address;
  final double fee;
  final String feeStatus;
  final String month;

  const StallFeeDetailModel({
    required this.feeId,
    required this.stallId,
    required this.stallName,
    required this.userName,
    required this.address,
    required this.fee,
    required this.feeStatus,
    required this.month,
  });

  @override
  List<Object?> get props => [feeId, stallId, stallName, userName, address, fee, feeStatus, month];

  StallFeeDetailModel copyWith({
    String? feeId,
    String? stallId,
    String? stallName,
    String? userName,
    String? address,
    double? fee,
    String? feeStatus,
    String? month,
  }) {
    return StallFeeDetailModel(
      feeId: feeId ?? this.feeId,
      stallId: stallId ?? this.stallId,
      stallName: stallName ?? this.stallName,
      userName: userName ?? this.userName,
      address: address ?? this.address,
      fee: fee ?? this.fee,
      feeStatus: feeStatus ?? this.feeStatus,
      month: month ?? this.month,
    );
  }

  factory StallFeeDetailModel.fromJson(Map<String, dynamic> json) {
    return StallFeeDetailModel(
      feeId: json['fee_id'] ?? '',
      stallId: json['stall_id'] ?? '',
      stallName: json['stall_name'] ?? '',
      userName: json['user_name'] ?? '',
      address: json['address'] ?? '',
      fee: (json['fee'] ?? 0.0).toDouble(),
      feeStatus: json['fee_status'] ?? 'chua_nop',
      month: json['month'] ?? '',
    );
  }
}

class StallFeeDetailResponse extends Equatable {
  final bool success;
  final StallFeeDetailModel data;

  const StallFeeDetailResponse({
    required this.success,
    required this.data,
  });

  @override
  List<Object?> get props => [success, data];

  factory StallFeeDetailResponse.fromJson(Map<String, dynamic> json) {
    return StallFeeDetailResponse(
      success: json['success'] ?? false,
      data: StallFeeDetailModel.fromJson(
          json['data'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class CommonResponse extends Equatable {
  final bool success;
  final String message;

  const CommonResponse({
    required this.success,
    required this.message,
  });

  @override
  List<Object?> get props => [success, message];

  factory CommonResponse.fromJson(Map<String, dynamic> json) {
    return CommonResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
