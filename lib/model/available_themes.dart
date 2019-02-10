import 'package:flutter/material.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/themes.dart';
import 'package:kalium_wallet_flutter/model/setting_item.dart';

enum ThemeOptions { KALIUM, TITANIUM, IRIDIUM, RADIUM, BERYLLIUM, RUTHENIUM }

/// Represent notification on/off setting
class ThemeSetting extends SettingSelectionItem {
  ThemeOptions theme;

  ThemeSetting(this.theme);

  String getDisplayName(BuildContext context) {
    switch (theme) {
      case ThemeOptions.TITANIUM:
        return "Titanium";
      case ThemeOptions.IRIDIUM:
        return "Iridium";
      case ThemeOptions.BERYLLIUM:
        return "Beryllium";
      case ThemeOptions.RUTHENIUM:
        return "Ruthenium";
      case ThemeOptions.RADIUM:
        return "Radium";
      case ThemeOptions.KALIUM:
      default:
        return "Kalium";
    }
  }

  BaseTheme getTheme() {
    switch (theme) {
      case ThemeOptions.TITANIUM:
        return TitaniumTheme();
      case ThemeOptions.IRIDIUM:
        return IridiumTheme();
      case ThemeOptions.BERYLLIUM:
        return BerylliumTheme();
      case ThemeOptions.RUTHENIUM:
        return RutheniumTheme();
      case ThemeOptions.RADIUM:
        return RadiumTheme();
      case ThemeOptions.KALIUM:
      default:
        return KaliumTheme();
    }
  }

  // For saving to shared prefs
  int getIndex() {
    return theme.index;
  }
}
