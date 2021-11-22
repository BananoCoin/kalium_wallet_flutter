// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingRequest _$PendingRequestFromJson(Map<String, dynamic> json) =>
    PendingRequest(
      action: json['action'] as String ?? Actions.PENDING,
      account: json['account'] as String,
      source: json['source'] as bool ?? true,
      count: json['count'] as int,
      threshold: json['threshold'] as String,
      includeActive: json['include_active'] as bool ?? true,
    );

Map<String, dynamic> _$PendingRequestToJson(PendingRequest instance) =>
    <String, dynamic>{
      'action': instance.action,
      'account': instance.account,
      'source': instance.source,
      'count': instance.count,
      'threshold': instance.threshold,
      'include_active': instance.includeActive,
    };
