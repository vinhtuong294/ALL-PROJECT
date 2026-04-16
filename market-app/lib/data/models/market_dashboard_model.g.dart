// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_dashboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarketDashboardModel _$MarketDashboardModelFromJson(
        Map<String, dynamic> json) =>
    MarketDashboardModel(
      totalStalls: (json['total_stalls'] as num).toInt(),
      openStalls: (json['open_stalls'] as num).toInt(),
      closedStalls: (json['closed_stalls'] as num).toInt(),
      categories: (json['categories'] as List<dynamic>)
          .map((e) => CategoryStatModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      stalls: (json['stalls'] as List<dynamic>)
          .map((e) => StallInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentLogs: (json['recent_logs'] as List<dynamic>)
          .map((e) => StatusLogInfoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MarketDashboardModelToJson(
        MarketDashboardModel instance) =>
    <String, dynamic>{
      'total_stalls': instance.totalStalls,
      'open_stalls': instance.openStalls,
      'closed_stalls': instance.closedStalls,
      'categories': instance.categories,
      'stalls': instance.stalls,
      'recent_logs': instance.recentLogs,
    };

CategoryStatModel _$CategoryStatModelFromJson(Map<String, dynamic> json) =>
    CategoryStatModel(
      ma: json['ma'] as String,
      ten: json['ten'] as String,
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$CategoryStatModelToJson(CategoryStatModel instance) =>
    <String, dynamic>{
      'ma': instance.ma,
      'ten': instance.ten,
      'count': instance.count,
    };

StallInfoModel _$StallInfoModelFromJson(Map<String, dynamic> json) =>
    StallInfoModel(
      stallId: json['stall_id'] as String,
      stallName: json['stall_name'] as String,
      status: json['status'] as String,
      userName: json['user_name'] as String,
      categoryMa: json['category_ma'] as String,
    );

Map<String, dynamic> _$StallInfoModelToJson(StallInfoModel instance) =>
    <String, dynamic>{
      'stall_id': instance.stallId,
      'stall_name': instance.stallName,
      'status': instance.status,
      'user_name': instance.userName,
      'category_ma': instance.categoryMa,
    };

StatusLogInfoModel _$StatusLogInfoModelFromJson(Map<String, dynamic> json) =>
    StatusLogInfoModel(
      logId: json['log_id'] as String,
      time: json['time'] as String,
      stallId: json['stall_id'] as String,
      stallName: json['stall_name'] as String,
      userName: json['user_name'] as String,
      status: json['status'] as String,
      statusLabel: json['status_label'] as String,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$StatusLogInfoModelToJson(StatusLogInfoModel instance) =>
    <String, dynamic>{
      'log_id': instance.logId,
      'time': instance.time,
      'stall_id': instance.stallId,
      'stall_name': instance.stallName,
      'user_name': instance.userName,
      'status': instance.status,
      'status_label': instance.statusLabel,
      'note': instance.note,
    };
