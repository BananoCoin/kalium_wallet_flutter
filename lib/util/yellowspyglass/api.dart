import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/util/sharedprefsutil.dart';
import 'package:kalium_wallet_flutter/util/yellowspyglass/representative_node.dart';

class YellowSpyglassAPI {
  static const String API_URL = 'https://api.yellowspyglass.com/yellowspyglass';
  static const String responseKey = 'thresholdReps';

  static Future<String> getAndCacheAPIResponse() async {
    http.Response responseRepresentatives =
        await http.get(Uri.parse(API_URL + '/representatives'), headers: {});
    if (responseRepresentatives.statusCode != 200) {
      return null;
    }
    http.Response responseAliases =
        await http.get(Uri.parse(API_URL + '/aliases'), headers: {});
    if (responseAliases.statusCode != 200) {
      return null;
    }
    var decodedResponseRepresentatives =
        json.decode(responseRepresentatives.body);
    var decodedResponseAliases = json.decode(responseAliases.body) as List;

    var response = <Map<String, dynamic>>[];
    for (Map<String, dynamic> item
        in decodedResponseRepresentatives[responseKey]) {
      final _alias = decodedResponseAliases.firstWhere(
          (element) => element['addr'] == item['address'],
          orElse: () => null);
      item['alias'] = _alias == null ? item['addr'] : _alias['alias'];
      item['weight'] =
          item['weight'] / decodedResponseRepresentatives['onlineWeight'] * 100;
      response.add(item);
    }

    final responseText = json.encode(response);

    await sl.get<SharedPrefsUtil>().setYellowSpyglassAPICache(responseText);
    return responseText;
  }

  /// Get verified nodes, return null if an error occured
  static Future<List<RepresentativeNode>> getVerifiedNodes() async {
    String httpResponseBody = await getAndCacheAPIResponse();
    if (httpResponseBody == null) {
      return null;
    }
    final decodedResponse = json.decode(httpResponseBody);

    if (httpResponseBody is! Map ||
        (httpResponseBody as Map)[responseKey] == null) {
      return null;
    }
    List<RepresentativeNode> representativeNodes =
        (decodedResponse[responseKey] as List)
            .map((e) => new RepresentativeNode.fromJson(e))
            .toList();
    return representativeNodes;
  }

  static Future<List<RepresentativeNode>> getCachedVerifiedNodes() async {
    String rawJson =
        await sl.get<SharedPrefsUtil>().getYellowSpyglassAPICache();
    if (rawJson == null) {
      return null;
    }
    List<RepresentativeNode> representativeNodes =
        (json.decode(rawJson) as List)
            .map((e) => new RepresentativeNode.fromJson(e))
            .toList();
    return representativeNodes;
  }
}
