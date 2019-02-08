import 'package:flutter/material.dart';

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
  Color text03;

  Color overlay20;
  Color overlay30;
  Color overlay50;
  Color overlay70;
  Color overlay80;
  Color overlay85;
  Color overlay90;
}

class KaliumTheme extends BaseTheme {
  static const yellow = Color(0xFFFBDD11);
  static const yellow10 = Color(0x1AFBDD11);
  static const yellow15 = Color(0x26FBDD11);
  static const yellow20 = Color(0x33FBDD11);
  static const yellow30 = Color(0x4DFBDD11);
  static const yellow45 = Color(0x73FBDD11);
  static const yellow60 = Color(0x99FBDD11);

  static const green = Color(0xFF4CBF4B);
  static const green60 = Color(0x994CBF4B);
  static const green30 = Color(0x4D4CBF4B);
  static const green15 = Color(0x264CBF4B);
  static const greenDark = Color(0xFF276126);
  static const greenDark30 = Color(0x4D276126);

  static const greyLight = Color(0xFF2A2A2E);
  static const greyLight40 = Color(0x662A2A2E);
  static const greyLight00 = Color(0x002A2A2E);

  static const greyDark = Color(0xFF212124);
  static const greyDark00 = Color(0x00212124);

  static const greyDarkest = Color(0xFF1A1A1C);

  static const white90 = Color(0xE6FFFFFF);
  static const white60 = Color(0x99FFFFFF);
  static const white45 = Color(0x73FFFFFF);
  static const white30 = Color(0x4DFFFFFF);
  static const white20 = Color(0x33FFFFFF);
  static const white15 = Color(0x26FFFFFF);
  static const white03 = Color(0x08FFFFFF);

  static const black20 = Color(0x33000000);
  static const black30 = Color(0x4D000000);
  static const black50 = Color(0x80000000);
  static const black70 = Color(0xB3000000);
  static const black80 = Color(0xCC000000);
  static const black85 = Color(0xD9000000);
  static const black90 = Color(0xE6000000);

  static const blue = Color(0xFF4A90E2);

  Color primary = yellow;
  Color primary60 = yellow60;
  Color primary45 = yellow45;
  Color primary30 = yellow30;
  Color primary20 = yellow20;
  Color primary15 = yellow15;
  Color primary10 = yellow10;

  Color success = green;
  Color success60 = green60;
  Color success30 = green30;
  Color success15 = green15;
  Color successDark = greenDark;
  Color successDark30 = greenDark30;

  Color background = greyLight;
  Color background40 = greyLight40;
  Color background00 = greyLight00;

  Color backgroundDark = greyDark;
  Color backgroundDark00 = greyDark00;

  Color backgroundDarkest = greyDarkest;

  Color text = white90;
  Color text60 = white60;
  Color text45 = white45;
  Color text30 = white30;
  Color text20 = white20;
  Color text15 = white15;
  Color text03 = white03;

  Color overlay20= black20;
  Color overlay30= black20;
  Color overlay50= black50;
  Color overlay70= black70;
  Color overlay80= black80;
  Color overlay85= black85;
  Color overlay90= black90;
}

class TitaniumTheme extends BaseTheme {
  static const blueishGreen = Color(0xFF61C6AD);
  static const blueishGreen10 = Color(0x1A61C6AD);
  static const blueishGreen15 = Color(0x2661C6AD);
  static const blueishGreen20 = Color(0x3361C6AD);
  static const blueishGreen30 = Color(0x4D61C6AD);
  static const blueishGreen45 = Color(0x7361C6AD);
  static const blueishGreen60 = Color(0x9961C6AD);

  static const green = Color(0xFFB5ED88);
  static const green60 = Color(0x99B5ED88);
  static const green30 = Color(0x4DB5ED88);
  static const green15 = Color(0x26B5ED88);
  static const greenDark = Color(0xFF5F893D);
  static const greenDark30 = Color(0x4D5F893D);

  static const tealDark = Color(0xFF041920);
  static const tealDark40 = Color(0x66041920);
  static const tealDark00 = Color(0x00041920);

  static const tealLight = Color(0xFF052029);
  static const tealLight00 = Color(0x00052029);

  static const tealDarkest = Color(0xFF041920);

  static const white90 = Color(0xE6FFFFFF);
  static const white60 = Color(0x99FFFFFF);
  static const white45 = Color(0x73FFFFFF);
  static const white30 = Color(0x4DFFFFFF);
  static const white20 = Color(0x33FFFFFF);
  static const white15 = Color(0x26FFFFFF);
  static const white03 = Color(0x08FFFFFF);

  static const black20 = Color(0x33000000);
  static const black30 = Color(0x4D000000);
  static const black50 = Color(0x80000000);
  static const black70 = Color(0xB3000000);
  static const black80 = Color(0xCC000000);
  static const black85 = Color(0xD9000000);
  static const black90 = Color(0xE6000000);

  static const blue = Color(0xFF4A90E2);

  Color primary = blueishGreen;
  Color primary60 = blueishGreen60;
  Color primary45 = blueishGreen45;
  Color primary30 = blueishGreen30;
  Color primary20 = blueishGreen20;
  Color primary15 = blueishGreen15;
  Color primary10 = blueishGreen10;

  Color success = green;
  Color success60 = green60;
  Color success30 = green30;
  Color success15 = green15;
  Color successDark = greenDark;
  Color successDark30 = greenDark30;

  Color background = tealDark;
  Color background40 = tealDark40;
  Color background00 = tealDark00;

  Color backgroundDark = tealLight;
  Color backgroundDark00 = tealLight00;

  Color backgroundDarkest = tealDarkest;

  Color text = white90;
  Color text60 = white60;
  Color text45 = white45;
  Color text30 = white30;
  Color text20 = white20;
  Color text15 = white15;
  Color text03 = white03;

  Color overlay20= black20;
  Color overlay30= black20;
  Color overlay50= black50;
  Color overlay70= black70;
  Color overlay80= black80;
  Color overlay85= black85;
  Color overlay90= black90;
}