import 'package:event_taxi/event_taxi.dart';
import 'package:kalium_wallet_flutter/network/model/response/subscribe_response.dart';

class SubscribeEvent implements Event {
  final SubscribeResponse response;

  SubscribeEvent({this.response});
}