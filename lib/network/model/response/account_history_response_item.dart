import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/model/address.dart';
import 'package:kalium_wallet_flutter/util/numberutil.dart';

part 'account_history_response_item.g.dart';

int _toInt(String v) => v == null ? 0 : int.tryParse(v);

@JsonSerializable()
class AccountHistoryResponseItem {
  @JsonKey(name: 'type')
  String type;

  @JsonKey(name: 'account')
  String account;

  @JsonKey(name: 'amount')
  String amount;

  @JsonKey(name: 'hash')
  String hash;

  @JsonKey(name: 'height', fromJson: _toInt)
  int height;

  @JsonKey(name: 'local_timestamp', fromJson: _toInt)
  int localTimestamp;

  @JsonKey(ignore: true)
  bool confirmed;

  AccountHistoryResponseItem({
    String type,
    String account,
    String amount,
    String hash,
    int height,
    int localTimestamp,
    this.confirmed,
  }) {
    this.type = type;
    this.account = account;
    this.amount = amount;
    this.hash = hash;
    this.height = height;
    this.localTimestamp = localTimestamp;
  }

  String getShortString() {
    return new Address(this.account).getShortString();
  }

  String getShorterString() {
    return new Address(this.account).getShorterString();
  }

  /**
   * Return amount formatted for use in the UI
   */
  String getFormattedAmount() {
    return NumberUtil.getRawAsUsableString(amount);
  }

  String get date => DateFormat().format(DateTime.fromMillisecondsSinceEpoch(
      int.parse(localTimestamp.toString().padRight(13, '0'))));

  factory AccountHistoryResponseItem.fromJson(Map<String, dynamic> json) =>
      _$AccountHistoryResponseItemFromJson(json);
  Map<String, dynamic> toJson() => _$AccountHistoryResponseItemToJson(this);

  bool operator ==(o) => o is AccountHistoryResponseItem && o.hash == hash;
  int get hashCode => hash.hashCode;
}
