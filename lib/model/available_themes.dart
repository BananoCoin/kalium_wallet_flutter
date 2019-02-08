import 'package:flutter/material.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/themes.dart';
import 'package:kalium_wallet_flutter/model/setting_item.dart';

enum ThemeOptions { KALIUM, PINK }

/// Represent notification on/off setting
class ThemeSetting extends SettingSelectionItem {
  ThemeOptions theme;

  ThemeSetting(this.theme);

  String getDisplayName(BuildContext context) {
    switch (theme) {
      case ThemeOptions.PINK:
        return "Pink";
      case ThemeOptions.KALIUM:
      default:
        return "Kalium";
    }
  }

  BaseTheme getTheme() {
    switch (theme) {
      case ThemeOptions.PINK:
        return PinkTheme();
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