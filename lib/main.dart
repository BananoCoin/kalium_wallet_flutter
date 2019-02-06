import 'dart:async';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:oktoast/oktoast.dart';

import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/ui/home_page.dart';
import 'package:kalium_wallet_flutter/ui/lock_screen.dart';
import 'package:kalium_wallet_flutter/ui/intro/intro_welcome.dart';
import 'package:kalium_wallet_flutter/ui/intro/intro_backup_seed.dart';
import 'package:kalium_wallet_flutter/ui/intro/intro_backup_confirm.dart';
import 'package:kalium_wallet_flutter/ui/intro/intro_import_seed.dart';
import 'package:kalium_wallet_flutter/ui/util/routes.dart';
import 'package:kalium_wallet_flutter/model/vault.dart';
import 'package:kalium_wallet_flutter/util/nanoutil.dart';
import 'package:kalium_wallet_flutter/util/sharedprefsutil.dart';
import 'colors.dart';

void main() async {
  // Setup logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  // Run app
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]).then((_) {
    runApp(new StateContainer(child: new App()));
  });
}

class App extends StatefulWidget {
  @override
  _AppState createState() => new _AppState();
}


class _AppState extends State<App> {
  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light
        .copyWith(statusBarIconBrightness: Brightness.light, statusBarColor: Colors.transparent));
    return OKToast(
      textStyle: AppStyles.TextStyleSnackbar,
      backgroundColor: AppColors.backgroundDark,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kalium',
        theme: ThemeData(
          dialogBackgroundColor: AppColors.backgroundDark,
          primaryColor: AppColors.primary,
          accentColor: AppColors.primary10,
          backgroundColor: AppColors.backgroundDark,
          fontFamily: 'NunitoSans',
          brightness: Brightness.dark,
        ),
        localizationsDelegates: [
          AppLocalizationsDelegate(StateContainer.of(context).curLanguage),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate
        ],
        supportedLocales: [Locale("en"), Locale("de")],
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case '/':
              return NoTransitionRoute(
                builder: (_) => Splash(),
                settings: settings,
              ); 
            case '/home':
              return NoTransitionRoute(
                builder: (_) => AppHomePage(),
                settings: settings,
              );
            case '/home_transition':
              return NoPopTransitionRoute(
                builder: (_) => AppHomePage(),
                settings: settings,
              );
            case '/intro_welcome':
              return NoTransitionRoute(
                builder: (_) => IntroWelcomePage(),
                settings: settings,
              );
            case '/intro_backup':
              return MaterialPageRoute(
                builder: (_) => IntroBackupSeedPage(),
                settings: settings,
              );
            case '/intro_backup_confirm':
              return MaterialPageRoute(
                builder: (_) => IntroBackupConfirm(),
                settings: settings,
              );
            case '/intro_import':
              return MaterialPageRoute(
                builder: (_) => IntroImportSeedPage(),
                settings: settings,
              );
            case '/lock_screen':
              return NoTransitionRoute(
                builder: (_) => AppLockScreen(),
                settings: settings,
              );            
            case '/lock_screen_transition':
              return MaterialPageRoute(
                builder: (_) => AppLockScreen(),
                settings: settings,
              );          
            default:
              return null;
          }
        },
      ),
    );
  }
}

/// Splash
/// Default page route that determines if user is logged in and routes them appropriately.
class Splash extends StatefulWidget {
  @override
  SplashState createState() => new SplashState();
}

class SplashState extends State<Splash> {
  Future checkLoggedIn() async {
    // iOS key store is persistent, so if this is first launch then we will clear the keystore
    /* TODO - Uncomment
    bool firstLaunch = await SharedPrefsUtil.inst.getFirstLaunch();
    if (firstLaunch) {
      await Vault.inst.deleteAll();
    }
    await SharedPrefsUtil.inst.setFirstLaunch();
    */
    // See if logged in already
    bool isLoggedIn = false;
    var seed = await Vault.inst.getSeed();
    var pin = await Vault.inst.getPin();
    // If we have a seed set, but not a pin - or vice versa
    // Then delete the seed and pin from device and start over.
    // This would mean user did not complete the intro screen completely.
    if (seed != null && pin != null) {
      isLoggedIn = true;
    } else if (seed != null && pin == null) {
      await Vault.inst.deleteSeed();
    } else if (pin != null && seed == null) {
      await Vault.inst.deletePin();
    }

    if (isLoggedIn) {
      if (await SharedPrefsUtil.inst.getLock() || await SharedPrefsUtil.inst.shouldLock()) {
        Navigator.of(context).pushReplacementNamed('/lock_screen');
      } else {
        StateContainer.of(context).updateWallet(address: NanoUtil.seedToAddress(seed));
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/intro_welcome');
    }
  }

  @override
  void initState() {
    super.initState();
    checkLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light
        .copyWith(statusBarIconBrightness: Brightness.light, statusBarColor: Colors.transparent));
    // This seems to be the earliest place we can retrieve the device Locale
    StateContainer.of(context).deviceLocale = Localizations.localeOf(context);
    SharedPrefsUtil.inst.getCurrency(StateContainer.of(context).deviceLocale).then((currency) {
      StateContainer.of(context).curCurrency = currency;
    });
    return new Scaffold(
      backgroundColor: AppColors.background,
    );
  }
}
