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

  RepresentativeNode({
    this.weight,
    this.uptimePercentYear,
    this.address,
    this.alias,
  });

  factory RepresentativeNode.fromJson(Map<String, dynamic> json) =>
      _$RepresentativeNodeFromJson(json);
  Map<String, dynamic> toJson() => _$RepresentativeNodeToJson(this);
}
