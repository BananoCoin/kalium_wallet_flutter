// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'representative_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepresentativeNode _$RepresentativeNodeFromJson(Map<String, dynamic> json) =>
    RepresentativeNode(
      weight: _toDouble(json['weight']),
      uptimePercentYear: _toDouble(json['uptimePercentYear']),
      address: json['address'] as String,
      alias: json['alias'] as String,
      creationUnixTimestamp: json['creationUnixTimestamp'] as int,
    )
      ..online = json['online'] as bool
      ..delegatorsCount = _toBigInt(json['delegatorsCount'])
      ..principal = json['principal'] as bool
      ..uptimePercentDay = _toDouble(json['uptimePercentDay'])
      ..uptimePercentMonth = _toDouble(json['uptimePercentMonth'])
      ..uptimePercentSemiAnnual = _toDouble(json['uptimePercentSemiAnnual'])
      ..uptimePercentWeek = _toDouble(json['uptimePercentWeek']);

Map<String, dynamic> _$RepresentativeNodeToJson(RepresentativeNode instance) =>
    <String, dynamic>{
      'address': instance.address,
      'online': instance.online,
      'delegatorsCount': instance.delegatorsCount.toString(),
      'principal': instance.principal,
      'uptimePercentDay': instance.uptimePercentDay,
      'uptimePercentMonth': instance.uptimePercentMonth,
      'uptimePercentSemiAnnual': instance.uptimePercentSemiAnnual,
      'uptimePercentWeek': instance.uptimePercentWeek,
      'uptimePercentYear': instance.uptimePercentYear,
      'weight': instance.weight,
      'alias': instance.alias,
      'creationUnixTimestamp': instance.creationUnixTimestamp,
    };
