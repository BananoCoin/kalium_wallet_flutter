import 'package:flutter/material.dart';
import 'package:kalium_wallet_flutter/model/setting_item.dart';

enum AvailableBlockExplorerEnum { CREEPER, BANANOLOOKER }

/// Represent the available authentication methods our app supports
class AvailableBlockExplorer extends SettingSelectionItem {
  AvailableBlockExplorerEnum explorer;

  AvailableBlockExplorer(this.explorer);

  String getDisplayName(BuildContext context) {
    switch (explorer) {
      case AvailableBlockExplorerEnum.CREEPER:
        return "creeper.banano.cc";
      case AvailableBlockExplorerEnum.BANANOLOOKER:
        return "bananolooker.com";
      default:
        return "creeper.banano.cc";
    }
  }

  // For saving to shared prefs
  int getIndex() {
    return explorer.index;
  }
}
