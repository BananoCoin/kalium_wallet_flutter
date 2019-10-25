import 'package:event_taxi/event_taxi.dart';

class transferCompleteKalEvent implements Event {
  final BigInt amount;

  transferCompleteKalEvent({this.amount});
}