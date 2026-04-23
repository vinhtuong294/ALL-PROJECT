import 'package:json_annotation/json_annotation.dart';

part 'dashboard_stats_model.g.dart';

@JsonSerializable()
class DashboardStatsModel {
  @JsonKey(name: 'manager_name')
  final String managerName;
  @JsonKey(name: 'market_name')
  final String marketName;
  @JsonKey(name: 'district_name')
  final String districtName;
  @JsonKey(name: 'active_merchants')
  final int activeMerchants;
  @JsonKey(name: 'total_stalls')
  final int totalStalls;
  @JsonKey(name: 'orders_today')
  final int ordersToday;
  @JsonKey(name: 'monthly_tax_revenue')
  final double monthlyTaxRevenue;
  @JsonKey(name: 'pending_tax_stalls')
  final int pendingTaxStalls;

  DashboardStatsModel({
    required this.managerName,
    required this.marketName,
    required this.districtName,
    required this.activeMerchants,
    required this.totalStalls,
    required this.ordersToday,
    required this.monthlyTaxRevenue,
    required this.pendingTaxStalls,
  });


  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsModelFromJson(json);

  Map<String, dynamic> toJson() => _$DashboardStatsModelToJson(this);
}
