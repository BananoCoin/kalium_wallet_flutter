import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:local_auth/local_auth.dart';

class AppColors {
  // Some constants not themed
  static const overlay70 = Color(0xB3000000);
  static const overlay85 = Color(0xD9000000);
}

abstract class BaseTheme {
  Color primary;
  Color primary60;
  Color primary45;
  Color primary30;
  Color primary20;
  Color primary15;
  Color primary10;

  Color success;
  Color success60;
  Color success30;
  Color success15;
  Color successDark;
  Color successDark30;

  Color background;
  Color background40;
  Color background00;

  Color backgroundDark;
  Color backgroundDark00;

  Color backgroundDarkest;

  Color text;
  Color text60;
  Color text45;
  Color text30;
  Color text20;
  Color text15;
  Color text10;
  Color text5;
  Color text03;

  Color overlay90;
  Color overlay85;
  Color overlay80;
  Color overlay70;
  Color overlay50;
  Color overlay30;
  Color overlay20;

  Color animationOverlayMedium;
  Color animationOverlayStrong;

  Brightness brightness;
  SystemUiOverlayStyle statusBar;

  BoxShadow boxShadow;
  BoxShadow boxShadowButton;

  // QR scanner theme
  OverlayTheme qrScanTheme;
  // App icon (iOS only)
  AppIconEnum appIcon;
}

class KaliumTheme extends BaseTheme {
  static const yellow = Color(0xFFFBDD11);

  static const green = Color(0xFF4CBF4B);

  static const greenDark = Color(0xFF276126);

  static const greyLight = Color(0xFF2A2A2E);

  static const greyDark = Color(0xFF212124);

  static const greyDarkest = Color(0xFF1A1A1C);

  static const white = Color(0xFFFFFFFF);

  static const black = Color(0xFF000000);

  Color primary = yellow;
  Color primary60 = yellow.withOpacity(0.6);
  Color primary45 = yellow.withOpacity(0.45);
  Color primary30 = yellow.withOpacity(0.3);
  Color primary20 = yellow.withOpacity(0.2);
  Color primary15 = yellow.withOpacity(0.15);
  Color primary10 = yellow.withOpacity(0.1);

  Color success = green;
  Color success60 = green.withOpacity(0.6);
  Color success30 = green.withOpacity(0.3);
  Color success15 = green.withOpacity(0.15);

  Color successDark = greenDark;
  Color successDark30 = greenDark.withOpacity(0.3);

  Color background = greyLight;
  Color background40 = greyLight.withOpacity(0.4);
  Color background00 = greyLight.withOpacity(0.0);

  Color backgroundDark = greyDark;
  Color backgroundDark00 = greyDark.withOpacity(0.0);

  Color backgroundDarkest = greyDarkest;

  Color text = white.withOpacity(0.9);
  Color text60 = white.withOpacity(0.6);
  Color text45 = white.withOpacity(0.45);
  Color text30 = white.withOpacity(0.3);
  Color text20 = white.withOpacity(0.2);
  Color text15 = white.withOpacity(0.15);
  Color text10 = white.withOpacity(0.1);
  Color text05 = white.withOpacity(0.05);
  Color text03 = white.withOpacity(0.03);

  Color overlay90 = black.withOpacity(0.9);
  Color overlay85 = black.withOpacity(0.85);
  Color overlay80 = black.withOpacity(0.8);
  Color overlay70 = black.withOpacity(0.7);
  Color overlay50 = black.withOpacity(0.5);
  Color overlay30 = black.withOpacity(0.3);
  Color overlay20 = black.withOpacity(0.2);

  Color animationOverlayMedium = black.withOpacity(0.7);
  Color animationOverlayStrong = black.withOpacity(0.85);


  Brightness brightness = Brightness.dark;
  SystemUiOverlayStyle statusBar =
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent);

  BoxShadow boxShadow = BoxShadow(color: Colors.transparent);
  BoxShadow boxShadowButton = BoxShadow(color: Colors.transparent);

  OverlayTheme qrScanTheme = OverlayTheme.KALIUM;
  AppIconEnum appIcon = AppIconEnum.KALIUM;
}

class TitaniumTheme extends BaseTheme {
  static const blueishGreen = Color(0xFF61C6AD);

  static const green = Color(0xFFB5ED88);

  static const greenDark = Color(0xFF5F893D);

  static const tealDark = Color(0xFF041920);

  static const tealLight = Color(0xFF052029);

  static const tealDarkest = Color(0xFF041920);

  static const white = Color(0xFFFFFFFF);

  static const black = Color(0xFF000000);

  Color primary = blueishGreen;
  Color primary60 = blueishGreen.withOpacity(0.6);
  Color primary45 = blueishGreen.withOpacity(0.45);
  Color primary30 = blueishGreen.withOpacity(0.3);
  Color primary20 = blueishGreen.withOpacity(0.2);
  Color primary15 = blueishGreen.withOpacity(0.15);
  Color primary10 = blueishGreen.withOpacity(0.1);

  Color success = green;
  Color success60 = green.withOpacity(0.6);
  Color success30 = green.withOpacity(0.3);
  Color success15 = green.withOpacity(0.15);

  Color successDark = greenDark;
  Color successDark30 = greenDark.withOpacity(0.3);

  Color background = tealDark;
  Color background40 = tealDark.withOpacity(0.4);
  Color background00 = tealDark.withOpacity(0.0);

  Color backgroundDark = tealLight;
  Color backgroundDark00 = tealLight.withOpacity(0.0);

  Color backgroundDarkest = tealDarkest;

  Color text = white.withOpacity(0.9);
  Color text60 = white.withOpacity(0.6);
  Color text45 = white.withOpacity(0.45);
  Color text30 = white.withOpacity(0.3);
  Color text20 = white.withOpacity(0.2);
  Color text15 = white.withOpacity(0.15);
  Color text10 = white.withOpacity(0.1);
  Color text05 = white.withOpacity(0.05);
  Color text03 = white.withOpacity(0.03);

  Color overlay90 = black.withOpacity(0.9);
  Color overlay85 = black.withOpacity(0.85);
  Color overlay80 = black.withOpacity(0.8);
  Color overlay70 = black.withOpacity(0.7);
  Color overlay50 = black.withOpacity(0.5);
  Color overlay30 = black.withOpacity(0.3);
  Color overlay20 = black.withOpacity(0.2);

  Color animationOverlayMedium = black.withOpacity(0.7);
  Color animationOverlayStrong = black.withOpacity(0.85);

  Brightness brightness = Brightness.dark;
  SystemUiOverlayStyle statusBar =
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent);

  BoxShadow boxShadow = BoxShadow(color: Colors.transparent);
  BoxShadow boxShadowButton = BoxShadow(color: Colors.transparent);

  OverlayTheme qrScanTheme = OverlayTheme.TITANIUM;
  AppIconEnum appIcon = AppIconEnum.TITANIUM;
}

class IridiumTheme extends BaseTheme {
  static const green = Color(0xFF008F53);

  static const blue = Color(0xFF566AB4);

  static const blueLight = Color(0xFF90A0D9);

  static const white = Color(0xFFFFFFFF);

  static const whiteishDark = Color(0xFFE6E6E6);

  static const grey = Color(0xFF424E49);

  static const black = Color(0xFF000000);

  static const veryDarkGreen = Color(0xFF003B22);

  Color primary = green;
  Color primary60 = green.withOpacity(0.6);
  Color primary45 = green.withOpacity(0.45);
  Color primary30 = green.withOpacity(0.3);
  Color primary20 = green.withOpacity(0.2);
  Color primary15 = green.withOpacity(0.15);
  Color primary10 = green.withOpacity(0.1);

  Color success = blue;
  Color success60 = blue.withOpacity(0.6);
  Color success30 = blue.withOpacity(0.3);
  Color success15 = blue.withOpacity(0.15);

  Color successDark = blueLight;
  Color successDark30 = blueLight.withOpacity(0.3);

  Color background = white;
  Color background40 = white.withOpacity(0.4);
  Color background00 = white.withOpacity(0.0);

  Color backgroundDark = white;
  Color backgroundDark00 = white.withOpacity(0.0);

  Color backgroundDarkest = whiteishDark;

  Color text = grey.withOpacity(0.9);
  Color text60 = grey.withOpacity(0.6);
  Color text45 = grey.withOpacity(0.45);
  Color text30 = grey.withOpacity(0.3);
  Color text20 = grey.withOpacity(0.2);
  Color text15 = grey.withOpacity(0.15);
  Color text10 = grey.withOpacity(0.1);
  Color text05 = grey.withOpacity(0.05);
  Color text03 = grey.withOpacity(0.03);

  Color overlay90 = black.withOpacity(0.9);
  Color overlay85 = black.withOpacity(0.85);
  Color overlay80 = black.withOpacity(0.8);
  Color overlay70 = black.withOpacity(0.7);
  Color overlay50 = black.withOpacity(0.5);
  Color overlay30 = black.withOpacity(0.3);
  Color overlay20 = black.withOpacity(0.2);

  Color animationOverlayMedium = white.withOpacity(0.7);
  Color animationOverlayStrong = white.withOpacity(0.85);

  Brightness brightness = Brightness.light;
  SystemUiOverlayStyle statusBar =
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent);

  BoxShadow boxShadow = BoxShadow(
      color: veryDarkGreen.withOpacity(0.1),
      offset: Offset(0, 5),
      blurRadius: 15);
  BoxShadow boxShadowButton = BoxShadow(
      color: veryDarkGreen.withOpacity(0.2),
      offset: Offset(0, 5),
      blurRadius: 15);

  OverlayTheme qrScanTheme = OverlayTheme.IRIDIUM;
  AppIconEnum appIcon = AppIconEnum.IRIDIUM;
}

class BerylliumTheme extends BaseTheme {
  static const purple = Color(0xFFBDA1FF);

  static const green = Color(0xFFA1FFD2);

  static const greenDark = Color(0xFF2C6E4E);

  static const greyDark = Color(0xFF18181A);

  static const greyLight = Color(0xFF1E1E21);

  static const greyDarkest = Color(0xFF18181A);

  static const white = Color(0xFFFFFFFF);

  static const black = Color(0xFF000000);

  Color primary = purple;
  Color primary60 = purple.withOpacity(0.6);
  Color primary45 = purple.withOpacity(0.45);
  Color primary30 = purple.withOpacity(0.3);
  Color primary20 = purple.withOpacity(0.2);
  Color primary15 = purple.withOpacity(0.15);
  Color primary10 = purple.withOpacity(0.1);

  Color success = green;
  Color success60 = green.withOpacity(0.6);
  Color success30 = green.withOpacity(0.3);
  Color success15 = green.withOpacity(0.15);

  Color successDark = greenDark;
  Color successDark30 = greenDark.withOpacity(0.3);

  Color background = greyDark;
  Color background40 = greyDark.withOpacity(0.4);
  Color background00 = greyDark.withOpacity(0.0);

  Color backgroundDark = greyLight;
  Color backgroundDark00 = greyLight.withOpacity(0.0);

  Color backgroundDarkest = greyDarkest;

  Color text = white.withOpacity(0.9);
  Color text60 = white.withOpacity(0.6);
  Color text45 = white.withOpacity(0.45);
  Color text30 = white.withOpacity(0.3);
  Color text20 = white.withOpacity(0.2);
  Color text15 = white.withOpacity(0.15);
  Color text10 = white.withOpacity(0.1);
  Color text05 = white.withOpacity(0.05);
  Color text03 = white.withOpacity(0.03);

  Color overlay90 = black.withOpacity(0.9);
  Color overlay85 = black.withOpacity(0.85);
  Color overlay80 = black.withOpacity(0.8);
  Color overlay70 = black.withOpacity(0.7);
  Color overlay50 = black.withOpacity(0.5);
  Color overlay30 = black.withOpacity(0.3);
  Color overlay20 = black.withOpacity(0.2);

  Color animationOverlayMedium = black.withOpacity(0.7);
  Color animationOverlayStrong = black.withOpacity(0.85);

  Brightness brightness = Brightness.dark;
  SystemUiOverlayStyle statusBar =
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent);

  BoxShadow boxShadow = BoxShadow(color: Colors.transparent);
  BoxShadow boxShadowButton = BoxShadow(color: Colors.transparent);

  OverlayTheme qrScanTheme = OverlayTheme.BERYLLIUM;
  AppIconEnum appIcon = AppIconEnum.BERYLLIUM;
}

class RadiumTheme extends BaseTheme {
  static const electricGreen = Color(0xFF3DF291);

  static const pink = Color(0xFFA96BFF);

  static const pinkDark = Color(0xFF6E3AB6);

  static const purpleDark = Color(0xFF200A40);

  static const purpleLight = Color(0xFF2A1052);

  static const purpleDarkest = Color(0xFF200A40);

  static const white = Color(0xFFFFFFFF);

  static const black = Color(0xFF000000);

  Color primary = electricGreen;
  Color primary60 = electricGreen.withOpacity(0.6);
  Color primary45 = electricGreen.withOpacity(0.45);
  Color primary30 = electricGreen.withOpacity(0.3);
  Color primary20 = electricGreen.withOpacity(0.2);
  Color primary15 = electricGreen.withOpacity(0.15);
  Color primary10 = electricGreen.withOpacity(0.1);

  Color success = pink;
  Color success60 = pink.withOpacity(0.6);
  Color success30 = pink.withOpacity(0.3);
  Color success15 = pink.withOpacity(0.15);

  Color successDark = pinkDark;
  Color successDark30 = pinkDark.withOpacity(0.3);

  Color background = purpleDark;
  Color background40 = purpleDark.withOpacity(0.4);
  Color background00 = purpleDark.withOpacity(0.0);

  Color backgroundDark = purpleLight;
  Color backgroundDark00 = purpleLight.withOpacity(0.0);

  Color backgroundDarkest = purpleDarkest;

  Color text = white.withOpacity(0.9);
  Color text60 = white.withOpacity(0.6);
  Color text45 = white.withOpacity(0.45);
  Color text30 = white.withOpacity(0.3);
  Color text20 = white.withOpacity(0.2);
  Color text15 = white.withOpacity(0.15);
  Color text10 = white.withOpacity(0.1);
  Color text05 = white.withOpacity(0.05);
  Color text03 = white.withOpacity(0.03);

  Color overlay90 = black.withOpacity(0.9);
  Color overlay85 = black.withOpacity(0.85);
  Color overlay80 = black.withOpacity(0.8);
  Color overlay70 = black.withOpacity(0.7);
  Color overlay50 = black.withOpacity(0.5);
  Color overlay30 = black.withOpacity(0.3);
  Color overlay20 = black.withOpacity(0.2);

  Color animationOverlayMedium = black.withOpacity(0.7);
  Color animationOverlayStrong = black.withOpacity(0.85);

  Brightness brightness = Brightness.dark;
  SystemUiOverlayStyle statusBar =
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent);

  BoxShadow boxShadow = BoxShadow(color: Colors.transparent);
  BoxShadow boxShadowButton = BoxShadow(color: Colors.transparent);

  OverlayTheme qrScanTheme = OverlayTheme.RADIUM;
  AppIconEnum appIcon = AppIconEnum.RADIUM;
}

enum AppIconEnum { KALIUM, TITANIUM, IRIDIUM, BERYLLIUM, RADIUM }
class AppIcon {
  static const _channel = const MethodChannel('fappchannel');

  static Future<void> setAppIcon(AppIconEnum iconToChange) async {
    if (!Platform.isIOS) {
      return null;
    }
    String iconStr = "kalium";
    switch (iconToChange) {
      case AppIconEnum.BERYLLIUM:
        iconStr = "beryllium";
        break;
      case AppIconEnum.IRIDIUM:
        iconStr = "iridium";
        break;
      case AppIconEnum.TITANIUM:
        iconStr = "titanium";
        break;
      case AppIconEnum.RADIUM:
        iconStr = "radium";
        break;
      case AppIconEnum.KALIUM:
      default:
        iconStr = "kalium";
        break;
    }
    final Map<String, dynamic> params = <String, dynamic>{
     'icon': iconStr,
    };
    return await _channel.invokeMethod('changeIcon', params);
  }
}