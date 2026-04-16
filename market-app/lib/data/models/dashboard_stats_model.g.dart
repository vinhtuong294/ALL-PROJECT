// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_stats_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardStatsModel _$DashboardStatsModelFromJson(Map<String, dynamic> json) =>
    DashboardStatsModel(
      managerName: json['manager_name'] as String,
      marketName: json['market_name'] as String,
      districtName: json['district_name'] as String,
      activeMerchants: (json['active_merchants'] as num).toInt(),
      totalStalls: (json['total_stalls'] as num).toInt(),
      ordersToday: (json['orders_today'] as num).toInt(),
      monthlyTaxRevenue: (json['monthly_tax_revenue'] as num).toDouble(),
      pendingTaxStalls: (json['pending_tax_stalls'] as num).toInt(),
    );

Map<String, dynamic> _$DashboardStatsModelToJson(
        DashboardStatsModel instance) =>
    <String, dynamic>{
      'manager_name': instance.managerName,
      'market_name': instance.marketName,
      'district_name': instance.districtName,
      'active_merchants': instance.activeMerchants,
      'total_stalls': instance.totalStalls,
      'orders_today': instance.ordersToday,
      'monthly_tax_revenue': instance.monthlyTaxRevenue,
      'pending_tax_stalls': instance.pendingTaxStalls,
    };
