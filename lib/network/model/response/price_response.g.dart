// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceResponse _$PriceResponseFromJson(Map<String, dynamic> json) =>
    PriceResponse()
      ..currency = json['currency'] as String
      ..price = _toDouble(json['price'])
      ..btcPrice = _toDouble(json['btc'])
      ..nanoPrice = _toDouble(json['nano']);

Map<String, dynamic> _$PriceResponseToJson(PriceResponse instance) =>
    <String, dynamic>{
      'currency': instance.currency,
      'price': instance.price,
      'btc': instance.btcPrice,
      'nano': instance.nanoPrice,
    };
