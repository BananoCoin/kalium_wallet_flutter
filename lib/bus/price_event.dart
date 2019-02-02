import 'package:event_taxi/event_taxi.dart';
import 'package:kalium_wallet_flutter/network/model/response/price_response.dart';

class PriceEvent implements Event {
  final PriceResponse response;

  PriceEvent({this.response});
}