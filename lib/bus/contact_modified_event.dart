import 'package:event_taxi/event_taxi.dart';
import 'package:kalium_wallet_flutter/model/db/contact.dart';

class ContactModifiedEvent implements Event {
  final Contact contact;

  ContactModifiedEvent({this.contact});
}