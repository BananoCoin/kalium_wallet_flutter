// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fcm_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FcmUpdateRequest _$FcmUpdateRequestFromJson(Map<String, dynamic> json) =>
    FcmUpdateRequest(
      account: json['account'] as String,
      fcmToken: json['fcm_token_v2'] as String,
      enabled: json['enabled'] as bool,
    )..action = json['action'] as String;

Map<String, dynamic> _$FcmUpdateRequestToJson(FcmUpdateRequest instance) =>
    <String, dynamic>{
      'action': instance.action,
      'account': instance.account,
      'fcm_token_v2': instance.fcmToken,
      'enabled': instance.enabled,
    };
