import 'dart:math';

import 'package:json_annotation/json_annotation.dart';

part 'representative_node.g.dart';

double _toDouble(v) {
  return double.tryParse(v.toString());
}

BigInt _toBigInt(v) {
  return BigInt.from(v);
}

/// Represent a node that is returned from the YellowSpyglass API
@JsonSerializable()
class RepresentativeNode {
  @JsonKey(name: 'address')
  String address;

  @JsonKey(name: 'online')
  bool online;

  @JsonKey(name: 'delegatorsCount', fromJson: _toBigInt)
  BigInt delegatorsCount;

  @JsonKey(name: 'principal')
  bool principal;

  @JsonKey(name: 'uptimePercentDay', fromJson: _toDouble)
  double uptimePercentDay;

  @JsonKey(name: 'uptimePercentMonth', fromJson: _toDouble)
  double uptimePercentMonth;

  @JsonKey(name: 'uptimePercentSemiAnnual', fromJson: _toDouble)
  double uptimePercentSemiAnnual;

  @JsonKey(name: 'uptimePercentWeek', fromJson: _toDouble)
  double uptimePercentWeek;

  @JsonKey(name: 'uptimePercentYear', fromJson: _toDouble)
  double uptimePercentYear;

  @JsonKey(name: 'weight', fromJson: _toDouble)
  double weight;

  @JsonKey(name: 'alias')
  String alias;

  @JsonKey(name: 'creationUnixTimestamp')
  int creationUnixTimestamp;

  RepresentativeNode({
    this.weight,
    this.uptimePercentYear,
    this.address,
    this.alias,
    this.creationUnixTimestamp,
  });

  int get daysSinceCreation {
    DateTime date =
        DateTime.fromMillisecondsSinceEpoch(this.creationUnixTimestamp).toUtc();
    DateTime now = DateTime.now().toUtc();
    return now.difference(date).inDays;
  }

  int get score {
    double weightCalculation = (weight * 0.0075) * 100;
//    double scoreWeight = 100 / (1 + exp(8 * weight - 10));

    double scoreUptime = pow(10, -6) * pow(uptimePercentSemiAnnual, 4);

    double scoreAge = (100 + (-100 / (1 + pow(daysSinceCreation / 30, 4))));

    int score =
        (((scoreUptime * scoreAge) ~/ (pow(100, 2) / 100)) - weightCalculation)
            .toInt();
    return score;
  }

  factory RepresentativeNode.fromJson(Map<String, dynamic> json) =>
      _$RepresentativeNodeFromJson(json);
  Map<String, dynamic> toJson() => _$RepresentativeNodeToJson(this);
}
