import 'package:json_annotation/json_annotation.dart';

part 'auth_model.g.dart';

@JsonSerializable()
class AuthResponseModel {
  final AuthUserDataModel data;
  final String token;

  AuthResponseModel({
    required this.data,
    required this.token,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) => _$AuthResponseModelFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseModelToJson(this);
}

@JsonSerializable()
class AuthUserDataModel {
  final String sub;
  @JsonKey(name: 'user_id')
  final String userId;
  final String role;
  @JsonKey(name: 'login_name')
  final String loginName;
  @JsonKey(name: 'user_name')
  final String userName;

  AuthUserDataModel({
    required this.sub,
    required this.userId,
    required this.role,
    required this.loginName,
    required this.userName,
  });

  factory AuthUserDataModel.fromJson(Map<String, dynamic> json) => _$AuthUserDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$AuthUserDataModelToJson(this);

  bool get isMarketManager => role == 'quan_ly_cho';
}
