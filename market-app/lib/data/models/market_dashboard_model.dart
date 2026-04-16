import 'package:json_annotation/json_annotation.dart';

part 'market_dashboard_model.g.dart';

@JsonSerializable()
class MarketDashboardModel {
  @JsonKey(name: 'total_stalls')
  final int totalStalls;
  @JsonKey(name: 'open_stalls')
  final int openStalls;
  @JsonKey(name: 'closed_stalls')
  final int closedStalls;
  final List<CategoryStatModel> categories;
  final List<StallInfoModel> stalls;
  @JsonKey(name: 'recent_logs')
  final List<StatusLogInfoModel> recentLogs;

  MarketDashboardModel({
    required this.totalStalls,
    required this.openStalls,
    required this.closedStalls,
    required this.categories,
    required this.stalls,
    required this.recentLogs,
  });

  factory MarketDashboardModel.fromJson(Map<String, dynamic> json) =>
      _$MarketDashboardModelFromJson(json);

  Map<String, dynamic> toJson() => _$MarketDashboardModelToJson(this);
}

@JsonSerializable()
class CategoryStatModel {
  final String ma;
  final String ten;
  final int count;

  CategoryStatModel({
    required this.ma,
    required this.ten,
    required this.count,
  });

  factory CategoryStatModel.fromJson(Map<String, dynamic> json) =>
      _$CategoryStatModelFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryStatModelToJson(this);
}

@JsonSerializable()
class StallInfoModel {
  @JsonKey(name: 'stall_id')
  final String stallId;
  @JsonKey(name: 'stall_name')
  final String stallName;
  final String status;
  @JsonKey(name: 'user_name')
  final String userName;
  @JsonKey(name: 'category_ma')
  final String categoryMa;

  StallInfoModel({
    required this.stallId,
    required this.stallName,
    required this.status,
    required this.userName,
    required this.categoryMa,
  });

  factory StallInfoModel.fromJson(Map<String, dynamic> json) =>
      _$StallInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$StallInfoModelToJson(this);
}

@JsonSerializable()
class StatusLogInfoModel {
  @JsonKey(name: 'log_id')
  final String logId;
  final String time;
  @JsonKey(name: 'stall_id')
  final String stallId;
  @JsonKey(name: 'stall_name')
  final String stallName;
  @JsonKey(name: 'user_name')
  final String userName;
  final String status;
  @JsonKey(name: 'status_label')
  final String statusLabel;
  final String? note;

  StatusLogInfoModel({
    required this.logId,
    required this.time,
    required this.stallId,
    required this.stallName,
    required this.userName,
    required this.status,
    required this.statusLabel,
    this.note,
  });

  factory StatusLogInfoModel.fromJson(Map<String, dynamic> json) =>
      _$StatusLogInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$StatusLogInfoModelToJson(this);
}
