// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponseModel _$AuthResponseModelFromJson(Map<String, dynamic> json) =>
    AuthResponseModel(
      data: AuthUserDataModel.fromJson(json['data'] as Map<String, dynamic>),
      token: json['token'] as String,
    );

Map<String, dynamic> _$AuthResponseModelToJson(AuthResponseModel instance) =>
    <String, dynamic>{
      'data': instance.data,
      'token': instance.token,
    };

AuthUserDataModel _$AuthUserDataModelFromJson(Map<String, dynamic> json) =>
    AuthUserDataModel(
      sub: json['sub'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      loginName: json['login_name'] as String,
      userName: json['user_name'] as String,
    );

Map<String, dynamic> _$AuthUserDataModelToJson(AuthUserDataModel instance) =>
    <String, dynamic>{
      'sub': instance.sub,
      'user_id': instance.userId,
      'role': instance.role,
      'login_name': instance.loginName,
      'user_name': instance.userName,
    };
