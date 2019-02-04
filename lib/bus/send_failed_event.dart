import 'package:event_taxi/event_taxi.dart';
import 'package:kalium_wallet_flutter/network/model/response/error_response.dart';

class SendFailedEvent implements Event {
  final ErrorResponse response;

  SendFailedEvent({this.response});
}