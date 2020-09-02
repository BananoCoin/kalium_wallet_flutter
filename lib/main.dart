import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalium_wallet_flutter/model/available_language.dart';
import 'package:kalium_wallet_flutter/ui/avatar/avatar.dart';
import 'package:kalium_wallet_flutter/ui/before_scan_screen.dart';
import 'package:logger/logger.dart';
import 'package:oktoast/oktoast.dart';

import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/ui/home_page.dart';
import 'package:kalium_wallet_flutter/ui/lock_screen.dart';
import 'package:kalium_wallet_flutter/ui/intro/intro_welcome.dart';
import 'package:kalium_wallet_flutter/ui/intro/intro_backup_safety.dart';
import 'package:kalium_wallet_flutter/ui/intro/intro_backup_seed.dart';
import 'package:kalium_wallet_flutter/ui/intro/intro_backup_confirm.dart';
import 'package:kalium_wallet_flutter/ui/intro/intro_import_seed.dart';
import 'package:kalium_wallet_flutter/ui/util/routes.dart';
import 'package:kalium_wallet_flutter/model/vault.dart';
import 'package:kalium_wallet_flutter/util/nanoutil.dart';
import 'package:kalium_wallet_flutter/util/sharedprefsutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Setup Service Provide
  setupServiceLocator();
  // Setup logger, only show warning and higher in release mode.
  if (kReleaseMode) {
    Logger.level = Level.warning;
  } else {
    Logger.level = Level.debug;
  }
  // Run app
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(new StateContainer(child: new App()));
  });
}

class App extends StatefulWidget {
  @override
  _AppState createState() => new _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
  }

  // This widget is the root of the application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        StateContainer.of(context).curTheme.statusBar);
    return OKToast(
      textStyle: AppStyles.textStyleSnackbar(context),
      backgroundColor: StateContainer.of(context).curTheme.backgroundDark,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kalium',
        theme: ThemeData(
          dialogBackgroundColor:
              StateContainer.of(context).curTheme.backgroundDark,
          primaryColor: StateContainer.of(context).curTheme.primary,
          accentColor: StateContainer.of(context).curTheme.primary10,
          backgroundColor: StateContainer.of(context).curTheme.backgroundDark,
          fontFamily: 'NunitoSans',
          brightness: Brightness.dark,
        ),
        localizationsDelegates: [
          AppLocalizationsDelegate(StateContainer.of(context).curLanguage),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate
        ],
        locale: StateContainer.of(context).curLanguage == null ||
                StateContainer.of(context).curLanguage.language ==
                    AvailableLanguage.DEFAULT
            ? null
            : StateContainer.of(context).curLanguage.getLocale(),
        supportedLocales: [
          const Locale('en', 'US'), // English
          const Locale('he', 'IL'), // Hebrew
          const Locale('de', 'DE'), // German
          const Locale('ar'), // Arabic
          const Locale('lv'), // Latvian
          const Locale('bg'), // Bulgarian
          const Locale('es'), // Spanish
          const Locale('hi'), // Hindi
          const Locale('hu'), // Hungarian
          const Locale('hi'), // Hindi
          const Locale('id'), // Indonesian
          const Locale('it'), // Italian
          const Locale('ko'), // Korean
          const Locale('ms'), // Malay
          const Locale('nl'), // Dutch
          const Locale('pl'), // Polish
          const Locale('pt'), // Portugese
          const Locale('ro'), // Romanian
          const Locale('ru'), // Russian
          const Locale('sl'), // Slovenian
          const Locale('sv'), // Swedish
          const Locale('tl'), // Tagalog
          const Locale('tr'), // Turkish
          const Locale('vi'), // Vietnamese
          const Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hans'), // Chinese Simplified
          const Locale.fromSubtags(
              languageCode: 'zh', scriptCode: 'Hant'), // Chinese Traditional
          // Currency-default requires country included
          const Locale("es", "AR"),
          const Locale("en", "AU"),
          const Locale("pt", "BR"),
          const Locale("en", "CA"),
          const Locale("de", "CH"),
          const Locale("es", "CL"),
          const Locale("zh", "CN"),
          const Locale("cs", "CZ"),
          const Locale("da", "DK"),
          const Locale("fr", "FR"),
          const Locale("en", "GB"),
          const Locale("zh", "HK"),
          const Locale("hu", "HU"),
          const Locale("id", "ID"),
          const Locale("he", "IL"),
          const Locale("hi", "IN"),
          const Locale("ja", "JP"),
          const Locale("ko", "KR"),
          const Locale("es", "MX"),
          const Locale("ta", "MY"),
          const Locale("en", "NZ"),
          const Locale("tl", "PH"),
          const Locale("ur", "PK"),
          const Locale("pl", "PL"),
          const Locale("ru", "RU"),
          const Locale("sv", "SE"),
          const Locale("zh", "SG"),
          const Locale("th", "TH"),
          const Locale("tr", "TR"),
          const Locale("en", "TW"),
          const Locale("es", "VE"),
          const Locale("en", "ZA"),
          const Locale("en", "US"),
          const Locale("es", "AR"),
          const Locale("de", "AT"),
          const Locale("fr", "BE"),
          const Locale("de", "BE"),
          const Locale("nl", "BE"),
          const Locale("tr", "CY"),
          const Locale("et", "EE"),
          const Locale("fi", "FI"),
          const Locale("fr", "FR"),
          const Locale("el", "GR"),
          const Locale("es", "AR"),
          const Locale("en", "IE"),
          const Locale("it", "IT"),
          const Locale("es", "AR"),
          const Locale("lv", "LV"),
          const Locale("lt", "LT"),
          const Locale("fr", "LU"),
          const Locale("en", "MT"),
          const Locale("nl", "NL"),
          const Locale("pt", "PT"),
          const Locale("sk", "SK"),
          const Locale("sl", "SI"),
          const Locale("es", "ES"),
          const Locale("ar", "AE"), // UAE
          const Locale("ar", "SA"), // Saudi Arabia
          const Locale("ar", "KW"), // Kuwait
        ],
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
            case '/intro_backup_safety':
              return MaterialPageRoute(
                builder: (_) => IntroBackupSafetyPage(),
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
            case '/before_scan_screen':
              return NoTransitionRoute(
                builder: (_) => BeforeScanScreen(),
                settings: settings,
              );
            case '/avatar_page':
              return PageRouteBuilder(
                  pageBuilder: (context, animationIn, animationOut) =>
                      AvatarPage(),
                  settings: settings,
                  opaque: false);
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

class SplashState extends State<Splash> with WidgetsBindingObserver {
  bool _hasCheckedLoggedIn;
  bool _retried;
  Future checkLoggedIn() async {
    if (!_hasCheckedLoggedIn) {
      _hasCheckedLoggedIn = true;
    } else {
      return;
    }
    try {
      // iOS key store is persistent, so if this is first launch then we will clear the keystore
      bool firstLaunch = await sl.get<SharedPrefsUtil>().getFirstLaunch();
      if (firstLaunch) {
        await sl.get<Vault>().deleteAll();
      }
      await sl.get<SharedPrefsUtil>().setFirstLaunch();
      // See if logged in already
      bool isLoggedIn = false;
      var seed = await sl.get<Vault>().getSeed();
      var pin = await sl.get<Vault>().getPin();
      // If we have a seed set, but not a pin - or vice versa
      // Then delete the seed and pin from device and start over.
      // This would mean user did not complete the intro screen completely.
      if (seed != null && pin != null) {
        isLoggedIn = true;
      } else if (seed != null && pin == null) {
        await sl.get<Vault>().deleteSeed();
      } else if (pin != null && seed == null) {
        await sl.get<Vault>().deletePin();
      }

      if (isLoggedIn) {
        if (await sl.get<SharedPrefsUtil>().getLock() ||
            await sl.get<SharedPrefsUtil>().shouldLock()) {
          Navigator.of(context).pushReplacementNamed('/lock_screen');
        } else {
          await NanoUtil().loginAccount(context);
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/intro_welcome');
      }
    } catch (e) {
      /// Fallback secure storage
      /// A very small percentage of users are encountering issues writing to the
      /// Android keyStore using the flutter_secure_storage plugin.
      ///
      /// Instead of telling them they are out of luck, this is an automatic "fallback"
      /// It will generate a 64-byte secret using the native android "bottlerocketstudios" Vault
      /// This secret is used to encrypt sensitive data and save it in SharedPreferences
      if (Platform.isAndroid && e.toString().contains("flutter_secure")) {
        if (!(await sl.get<SharedPrefsUtil>().useLegacyStorage())) {
          await sl.get<SharedPrefsUtil>().setUseLegacyStorage();
          checkLoggedIn();
        }
      } else {
        await sl.get<Vault>().deleteAll();
        await sl.get<SharedPrefsUtil>().deleteAll();
        if (!_retried) {
          _retried = true;
          _hasCheckedLoggedIn = false;
          checkLoggedIn();
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hasCheckedLoggedIn = false;
    _retried = false;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => checkLoggedIn());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Account for user changing locale when leaving the app
    switch (state) {
      case AppLifecycleState.paused:
        super.didChangeAppLifecycleState(state);
        break;
      case AppLifecycleState.resumed:
        setLanguage();
        super.didChangeAppLifecycleState(state);
        break;
      default:
        super.didChangeAppLifecycleState(state);
        break;
    }
  }

  void setLanguage() {
    setState(() {
      StateContainer.of(context).deviceLocale = Localizations.localeOf(context);
    });
    sl.get<SharedPrefsUtil>().getLanguage().then((setting) {
      setState(() {
        StateContainer.of(context).updateLanguage(setting);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // This seems to be the earliest place we can retrieve the device Locale
    setLanguage();
    sl
        .get<SharedPrefsUtil>()
        .getCurrency(StateContainer.of(context).deviceLocale)
        .then((currency) {
      StateContainer.of(context).curCurrency = currency;
    });
    return new Scaffold(
      backgroundColor: StateContainer.of(context).curTheme.background,
    );
  }
}
