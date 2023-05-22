# Kalium - BANANO Mobile Wallet

[![GitHub release (latest)](https://img.shields.io/github/v/release/BananoCoin/kalium_wallet_flutter)](https://github.com/BananoCoin/kalium_wallet_flutter/releases) [![License](https://img.shields.io/github/license/BananoCoin/kalium_wallet_flutter)](https://github.com/BananoCoin/kalium_wallet_flutter/blob/master/LICENSE) [![CI](https://github.com/BananoCoin/kalium_wallet_flutter/workflows/CI/badge.svg)](https://github.com/BananoCoin/kalium_wallet_flutter/actions?query=workflow%3ACI) [![Twitter Follow](https://img.shields.io/twitter/follow/bananocoin?style=social)](https://twitter.com/intent/follow?screen_name=bananocoin)

## What is Kalium?

Kalium is a cross-platform mobile wallet for the Banano cryptocurrency. It is written in Dart using [Flutter](https://flutter.io).

| Link | Description |
| :----- | :------ |
[banano.cc](https://banano.cc) | Banano Homepage
[chat.banano.cc](https://chat.banano.cc) | Banano Discord
[@bananocoin](https://twitter.com/bananocoin) | Follow Banano on Twitter to stay up to date
[banano.how](https://banano.how) | Getting started with Banano and more Information

## Server

Kalium's backend server can be found [here](https://github.com/BananoCoin/kalium-wallet-server)

## Contributing

* Fork the repository and clone it to your local machine
* Follow the instructions [here](https://flutter.io/docs/get-started/install) to install the Flutter SDK
* Setup [Android Studio](https://flutter.io/docs/development/tools/android-studio) or [Visual Studio Code](https://flutter.io/docs/development/tools/vs-code).

## Building

Android (armeabi-v7a): `flutter build apk`
Android (arm64-v8a): `flutter build apk --target=android-arm64`
iOS: `flutter build ios`

If you have a connected device or emulator you can run and deploy the app with `flutter run`

## Have a question?

If you need any help, please create an issue on GitHub or visit the [Banano discord](https://chat.banano.cc). Feel free to file an issue if you do not manage to find any solution.

## License

Kalium is released under the MIT License

### Update translations:

```
flutter pub pub run intl_translation:extract_to_arb --output-dir=lib/l10n lib/localization.dart
flutter pub pub run intl_translation:generate_from_arb --output-dir=lib/l10n \
   --no-use-deferred-loading lib/localization.dart lib/l10n/intl_*.arb
```

test

