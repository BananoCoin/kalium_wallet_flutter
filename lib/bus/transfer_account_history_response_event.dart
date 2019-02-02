import 'package:event_taxi/event_taxi.dart';
import 'package:kalium_wallet_flutter/network/model/response/account_history_response.dart';

class TransferAccountHistoryEvent implements Event {
  final AccountHistoryResponse response;

  TransferAccountHistoryEvent({this.response});
}