import 'package:json_annotation/json_annotation.dart';

part 'market_map_model.g.dart';

@JsonSerializable()
class MarketMapResponse {
  final bool success;
  final List<MarketMapStall> data;

  MarketMapResponse({
    required this.success,
    required this.data,
  });

  factory MarketMapResponse.fromJson(Map<String, dynamic> json) =>
      _$MarketMapResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MarketMapResponseToJson(this);
}

@JsonSerializable()
class MarketMapStall {
  @JsonKey(name: 'stall_id')
  final String stallId;
  
  @JsonKey(name: 'ten_gian_hang')
  final String? tenGianHang;
  
  @JsonKey(name: 'nguoi_ban')
  final String? nguoiBan;
  
  @JsonKey(name: 'x_col')
  final int xCol;
  
  @JsonKey(name: 'y_row')
  final int yRow;
  
  @JsonKey(name: 'loai_hang')
  final String? loaiHang;
  
  @JsonKey(name: 'trang_thai')
  final String? trangThai;

  MarketMapStall({
    required this.stallId,
    this.tenGianHang,
    this.nguoiBan,
    required this.xCol,
    required this.yRow,
    this.loaiHang,
    this.trangThai,
  });

  factory MarketMapStall.fromJson(Map<String, dynamic> json) =>
      _$MarketMapStallFromJson(json);

  Map<String, dynamic> toJson() => _$MarketMapStallToJson(this);
}
