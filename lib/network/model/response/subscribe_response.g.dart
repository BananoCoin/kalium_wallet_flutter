// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscribe_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscribeResponse _$SubscribeResponseFromJson(Map<String, dynamic> json) {
  return SubscribeResponse()
    ..frontier = json['frontier'] as String
    ..openBlock = json['open_block'] as String
    ..representativeBlock = json['representative_block'] as String
    ..representative = json['representative'] as String
    ..balance = json['balance'] as String
    ..blockCount = _toInt(json['block_count'] as String)
    ..pending = json['pending'] as String
    ..uuid = json['uuid'] as String
    ..price = _toDouble(json['price'])
    ..btcPrice = _toDouble(json['btc'])
    ..nanoPrice = _toDouble(json['nano'])
    ..pendingCount = json['pending_count'] as int;
}

Map<String, dynamic> _$SubscribeResponseToJson(SubscribeResponse instance) =>
    <String, dynamic>{
      'frontier': instance.frontier,
      'open_block': instance.openBlock,
      'representative_block': instance.representativeBlock,
      'representative': instance.representative,
      'balance': instance.balance,
      'block_count': instance.blockCount,
      'pending': instance.pending,
      'uuid': instance.uuid,
      'price': instance.price,
      'btc': instance.btcPrice,
      'nano': instance.nanoPrice,
      'pending_count': instance.pendingCount,
    };
