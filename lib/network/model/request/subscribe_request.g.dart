// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscribe_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscribeRequest _$SubscribeRequestFromJson(Map<String, dynamic> json) =>
    SubscribeRequest(
      action: json['action'] as String ?? Actions.SUBSCRIBE,
      account: json['account'] as String,
      currency: json['currency'] as String,
      uuid: json['uuid'] as String ?? '',
      fcmToken: json['fcm_token_v2'] as String,
      notificationEnabled: json['notification_enabled'] as bool,
    );

Map<String, dynamic> _$SubscribeRequestToJson(SubscribeRequest instance) =>
    <String, dynamic>{
      'action': instance.action,
      'account': instance.account,
      'currency': instance.currency,
      'uuid': instance.uuid,
      'fcm_token_v2': instance.fcmToken,
      'notification_enabled': instance.notificationEnabled,
    };
