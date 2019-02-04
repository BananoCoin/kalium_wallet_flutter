import 'package:event_taxi/event_taxi.dart';
import 'package:kalium_wallet_flutter/network/model/response/pending_response.dart';

class PendingEvent implements Event {
  final PendingResponse response;

  PendingEvent({this.response});
}