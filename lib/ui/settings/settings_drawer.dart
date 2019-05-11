import 'dart:async';
import 'package:event_taxi/event_taxi.dart';
import 'package:kalium_wallet_flutter/ui/accounts/accountdetails_sheet.dart';
import 'package:kalium_wallet_flutter/ui/accounts/accounts_sheet.dart';
import 'package:kalium_wallet_flutter/ui/widgets/app_simpledialog.dart';
import 'package:logging/logging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/app_icons.dart';
import 'package:kalium_wallet_flutter/bus/events.dart';
import 'package:kalium_wallet_flutter/model/available_themes.dart';
import 'package:kalium_wallet_flutter/model/authentication_method.dart';
import 'package:kalium_wallet_flutter/model/available_currency.dart';
import 'package:kalium_wallet_flutter/model/device_unlock_option.dart';
import 'package:kalium_wallet_flutter/model/device_lock_timeout.dart';
import 'package:kalium_wallet_flutter/model/notification_settings.dart';
import 'package:kalium_wallet_flutter/model/available_language.dart';
import 'package:kalium_wallet_flutter/model/vault.dart';
import 'package:kalium_wallet_flutter/model/db/appdb.dart';
import 'package:kalium_wallet_flutter/ui/settings/backupseed_sheet.dart';
import 'package:kalium_wallet_flutter/ui/settings/changerepresentative_sheet.dart';
import 'package:kalium_wallet_flutter/ui/settings/settings_list_item.dart';
import 'package:kalium_wallet_flutter/ui/settings/contacts_widget.dart';
import 'package:kalium_wallet_flutter/ui/transfer/transfer_overview_sheet.dart';
import 'package:kalium_wallet_flutter/ui/transfer/transfer_confirm_sheet.dart';
import 'package:kalium_wallet_flutter/ui/transfer/transfer_complete_sheet.dart';
import 'package:kalium_wallet_flutter/ui/widgets/dialog.dart';
import 'package:kalium_wallet_flutter/ui/widgets/security.dart';
import 'package:kalium_wallet_flutter/ui/widgets/monkey.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/util/sharedprefsutil.dart';
import 'package:kalium_wallet_flutter/util/biometrics.dart';
import 'package:kalium_wallet_flutter/util/hapticutil.dart';
import 'package:kalium_wallet_flutter/util/numberutil.dart';
import 'package:kalium_wallet_flutter/util/caseconverter.dart';

class SettingsSheet extends StatefulWidget {
  _SettingsSheetState createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  AnimationController _controller;
  Animation<Offset> _offsetFloat;
  AnimationController _securityController;
  Animation<Offset> _securityOffsetFloat;

  String versionString = "";

  final log = Logger("SettingsSheet");
  bool _hasBiometrics = false;
  AuthenticationMethod _curAuthMethod =
      AuthenticationMethod(AuthMethod.BIOMETRICS);
  NotificationSetting _curNotificiationSetting =
      NotificationSetting(NotificationOptions.ON);
  UnlockSetting _curUnlockSetting = UnlockSetting(UnlockOption.NO);
  LockTimeoutSetting _curTimeoutSetting =
      LockTimeoutSetting(LockTimeoutOption.ONE);
  ThemeSetting _curThemeSetting = ThemeSetting(ThemeOptions.KALIUM);

  bool _contactsOpen;
  bool _securityOpen;
  bool _loadingAccounts;

  bool notNull(Object o) => o != null;

  // Called if transfer fails
  void transferError() {
    Navigator.of(context).pop();
    sl.get<UIUtil>().showSnackbar(AppLocalization.of(context).transferError, context);
  }

  @override
  void initState() {
    super.initState();
    _contactsOpen = false;
    _securityOpen = false;
    _loadingAccounts = false;
    // Determine if they have face or fingerprint enrolled, if not hide the setting
    sl.get<BiometricUtil>().hasBiometrics().then((bool hasBiometrics) {
      setState(() {
        _hasBiometrics = hasBiometrics;
      });
    });
    // Get default auth method setting
    sl.get<SharedPrefsUtil>().getAuthMethod().then((authMethod) {
      setState(() {
        _curAuthMethod = authMethod;
      });
    });
    // Get default unlock settings
    sl.get<SharedPrefsUtil>().getLock().then((lock) {
      setState(() {
        _curUnlockSetting = lock
            ? UnlockSetting(UnlockOption.YES)
            : UnlockSetting(UnlockOption.NO);
      });
    });
    sl.get<SharedPrefsUtil>().getLockTimeout().then((lockTimeout) {
      setState(() {
        _curTimeoutSetting = lockTimeout;
      });
    });
    // Get default notification setting
    sl.get<SharedPrefsUtil>().getNotificationsOn().then((notificationsOn) {
      setState(() {
        _curNotificiationSetting = notificationsOn
            ? NotificationSetting(NotificationOptions.ON)
            : NotificationSetting(NotificationOptions.OFF);
      });
    });
    // Get default theme settings
    sl.get<SharedPrefsUtil>().getTheme().then((theme) {
      setState(() {
        _curThemeSetting = theme;
      });
    });
    // Register event bus
    _registerBus();
    // Setup animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    // For security menu
    _securityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _offsetFloat = Tween<Offset>(begin: Offset(1.1, 0), end: Offset(0, 0))
        .animate(_controller);
    _securityOffsetFloat =
        Tween<Offset>(begin: Offset(1.1, 0), end: Offset(0, 0))
            .animate(_securityController);

    // Version string
    PackageInfo.fromPlatform().then((packageInfo) {
      setState(() {
        versionString = "v${packageInfo.version}";
      });
    });
  }

  StreamSubscription<TransferConfirmEvent> _transferConfirmSub;
  StreamSubscription<TransferCompleteEvent> _transferCompleteSub;
  StreamSubscription<UnlockCallbackEvent> _callbackUnlockSub;

  void _registerBus() {
    // Ready to go to transfer confirm
    _transferConfirmSub = EventTaxiImpl.singleton()
        .registerTo<TransferConfirmEvent>()
        .listen((event) {
      AppTransferConfirmSheet(event.balMap, transferError)
          .mainBottomSheet(context);
    });
    // Ready to go to transfer complete
    _transferCompleteSub = EventTaxiImpl.singleton()
        .registerTo<TransferCompleteEvent>()
        .listen((event) {
      StateContainer.of(context).requestUpdate();
      AppTransferCompleteSheet(
              sl.get<NumberUtil>().getRawAsUsableString(event.amount.toString()))
          .mainBottomSheet(context);
    });
    // Unlock callback
    _callbackUnlockSub = EventTaxiImpl.singleton()
        .registerTo<UnlockCallbackEvent>()
        .listen((event) {
      StateContainer.of(context).unlockCallback();
    });
  }

  void _destroyBus() {
    if (_transferConfirmSub != null) {
      _transferConfirmSub.cancel();
    }
    if (_transferCompleteSub != null) {
      _transferCompleteSub.cancel();
    }
    if (_callbackUnlockSub != null) {
      _callbackUnlockSub.cancel();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _securityController.dispose();
    _destroyBus();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        super.didChangeAppLifecycleState(state);
        break;
      case AppLifecycleState.resumed:
        super.didChangeAppLifecycleState(state);
        break;
      default:
        super.didChangeAppLifecycleState(state);
        break;
    }
  }


  Future<void> _authMethodDialog() async {
    switch (await showDialog<AuthMethod>(
        context: context,
        builder: (BuildContext context) {
          return AppSimpleDialog(
            title: Text(
              AppLocalization.of(context).authMethod,
              style: AppStyles.textStyleDialogHeader(context),
            ),
            children: <Widget>[
              AppSimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, AuthMethod.BIOMETRICS);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    AppLocalization.of(context).biometricsMethod,
                    style: AppStyles.textStyleDialogOptions(context),
                  ),
                ),
              ),
              AppSimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, AuthMethod.PIN);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    AppLocalization.of(context).pinMethod,
                    style: AppStyles.textStyleDialogOptions(context),
                  ),
                ),
              ),
            ],
          );
        })) {
      case AuthMethod.PIN:
        sl.get<SharedPrefsUtil>()
            .setAuthMethod(AuthenticationMethod(AuthMethod.PIN))
            .then((result) {
          setState(() {
            _curAuthMethod = AuthenticationMethod(AuthMethod.PIN);
          });
        });
        break;
      case AuthMethod.BIOMETRICS:
        sl.get<SharedPrefsUtil>()
            .setAuthMethod(AuthenticationMethod(AuthMethod.BIOMETRICS))
            .then((result) {
          setState(() {
            _curAuthMethod = AuthenticationMethod(AuthMethod.BIOMETRICS);
          });
        });
        break;
    }
  }

  Future<void> _notificationsDialog() async {
    switch (await showDialog<NotificationOptions>(
        context: context,
        builder: (BuildContext context) {
          return AppSimpleDialog(
            title: Text(
              AppLocalization.of(context).notifications,
              style: AppStyles.textStyleDialogHeader(context),
            ),
            children: <Widget>[
              AppSimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, NotificationOptions.ON);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    AppLocalization.of(context).onStr,
                    style: AppStyles.textStyleDialogOptions(context),
                  ),
                ),
              ),
              AppSimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, NotificationOptions.OFF);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    AppLocalization.of(context).off,
                    style: AppStyles.textStyleDialogOptions(context),
                  ),
                ),
              ),
            ],
          );
        })) {
      case NotificationOptions.ON:
        sl.get<SharedPrefsUtil>().setNotificationsOn(true).then((result) {
          setState(() {
            _curNotificiationSetting =
                NotificationSetting(NotificationOptions.ON);
          });
          FirebaseMessaging().requestNotificationPermissions();
          FirebaseMessaging().getToken().then((fcmToken) {
            EventTaxiImpl.singleton().fire(FcmUpdateEvent(token: fcmToken));
          });
        });
        break;
      case NotificationOptions.OFF:
        sl.get<SharedPrefsUtil>().setNotificationsOn(false).then((result) {
          setState(() {
            _curNotificiationSetting =
                NotificationSetting(NotificationOptions.OFF);
          });
          FirebaseMessaging().getToken().then((fcmToken) {
            EventTaxiImpl.singleton().fire(FcmUpdateEvent(token: fcmToken));
          });
        });
        break;
    }
  }

  Future<void> _lockDialog() async {
    switch (await showDialog<UnlockOption>(
        context: context,
        builder: (BuildContext context) {
          return AppSimpleDialog(
            title: Text(
              AppLocalization.of(context).lockAppSetting,
              style: AppStyles.textStyleDialogHeader(context),
            ),
            children: <Widget>[
              AppSimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, UnlockOption.NO);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    AppLocalization.of(context).no,
                    style: AppStyles.textStyleDialogOptions(context),
                  ),
                ),
              ),
              AppSimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, UnlockOption.YES);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    AppLocalization.of(context).yes,
                    style: AppStyles.textStyleDialogOptions(context),
                  ),
                ),
              ),
            ],
          );
        })) {
      case UnlockOption.YES:
        sl.get<SharedPrefsUtil>().setLock(true).then((result) {
          setState(() {
            _curUnlockSetting = UnlockSetting(UnlockOption.YES);
          });
        });
        break;
      case UnlockOption.NO:
        sl.get<SharedPrefsUtil>().setLock(false).then((result) {
          setState(() {
            _curUnlockSetting = UnlockSetting(UnlockOption.NO);
          });
        });
        break;
    }
  }

  List<Widget> _buildCurrencyOptions() {
    List<Widget> ret = new List();
    AvailableCurrencyEnum.values.forEach((AvailableCurrencyEnum value) {
      ret.add(SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            AvailableCurrency(value).getDisplayName(context),
            style: AppStyles.textStyleDialogOptions(context),
          ),
        ),
      ));
    });
    return ret;
  }

  Future<void> _currencyDialog() async {
    AvailableCurrencyEnum selection =
        await showAppDialog<AvailableCurrencyEnum>(
            context: context,
            builder: (BuildContext context) {
              return AppSimpleDialog(
                title: Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    AppLocalization.of(context).changeCurrency,
                    style: AppStyles.textStyleDialogHeader(context),
                  ),
                ),
                children: _buildCurrencyOptions(),
              );
            });
    sl.get<SharedPrefsUtil>()
        .setCurrency(AvailableCurrency(selection))
        .then((result) {
      if (StateContainer.of(context).curCurrency.currency != selection) {
        setState(() {
          StateContainer.of(context).curCurrency = AvailableCurrency(selection);
        });
        StateContainer.of(context).requestSubscribe();
      }
    });
  }

  List<Widget> _buildLanguageOptions() {
    List<Widget> ret = new List();
    AvailableLanguage.values.forEach((AvailableLanguage value) {
      ret.add(SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            LanguageSetting(value).getDisplayName(context),
            style: AppStyles.textStyleDialogOptions(context),
          ),
        ),
      ));
    });
    return ret;
  }

  Future<void> _languageDialog() async {
    AvailableLanguage selection = await showAppDialog<AvailableLanguage>(
        context: context,
        builder: (BuildContext context) {
          return AppSimpleDialog(
            title: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                AppLocalization.of(context).language,
                style: AppStyles.textStyleDialogHeader(context),
              ),
            ),
            children: _buildLanguageOptions(),
          );
        });
    sl.get<SharedPrefsUtil>().setLanguage(LanguageSetting(selection)).then((result) {
      if (StateContainer.of(context).curLanguage.language != selection) {
        setState(() {
          StateContainer.of(context).updateLanguage(LanguageSetting(selection));
        });
      }
    });
  }

  List<Widget> _buildLockTimeoutOptions() {
    List<Widget> ret = new List();
    LockTimeoutOption.values.forEach((LockTimeoutOption value) {
      ret.add(SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            LockTimeoutSetting(value).getDisplayName(context),
            style: AppStyles.textStyleDialogOptions(context),
          ),
        ),
      ));
    });
    return ret;
  }

  Future<void> _lockTimeoutDialog() async {
    LockTimeoutOption selection = await showAppDialog<LockTimeoutOption>(
        context: context,
        builder: (BuildContext context) {
          return AppSimpleDialog(
            title: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                AppLocalization.of(context).autoLockHeader,
                style: AppStyles.textStyleDialogHeader(context),
              ),
            ),
            children: _buildLockTimeoutOptions(),
          );
        });
    sl.get<SharedPrefsUtil>()
        .setLockTimeout(LockTimeoutSetting(selection))
        .then((result) {
      if (_curTimeoutSetting.setting != selection) {
        sl.get<SharedPrefsUtil>()
            .setLockTimeout(LockTimeoutSetting(selection))
            .then((_) {
          setState(() {
            _curTimeoutSetting = LockTimeoutSetting(selection);
          });
        });
      }
    });
  }

  List<Widget> _buildThemeOptions() {
    List<Widget> ret = new List();
    ThemeOptions.values.forEach((ThemeOptions value) {
      ret.add(SimpleDialogOption(
        onPressed: () {
          Navigator.pop(context, value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            ThemeSetting(value).getDisplayName(context),
            style: AppStyles.textStyleDialogOptions(context),
          ),
        ),
      ));
    });
    return ret;
  }

  Future<void> _themeDialog() async {
    ThemeOptions selection = await showAppDialog<ThemeOptions>(
        context: context,
        builder: (BuildContext context) {
          return AppSimpleDialog(
            title: Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                AppLocalization.of(context).themeHeader,
                style: AppStyles.textStyleDialogHeader(context),
              ),
            ),
            children: _buildThemeOptions(),
          );
        });
    if (_curThemeSetting != ThemeSetting(selection)) {
      sl.get<SharedPrefsUtil>().setTheme(ThemeSetting(selection)).then((result) {
        setState(() {
          StateContainer.of(context).updateTheme(ThemeSetting(selection));
          _curThemeSetting = ThemeSetting(selection);
        });
      });
    }
  }

  Future<bool> _onBackButtonPressed() async {
    if (_contactsOpen) {
      setState(() {
        _contactsOpen = false;
      });
      _controller.reverse();
      return false;
    } else if (_securityOpen) {
      setState(() {
        _securityOpen = false;
      });
      _securityController.reverse();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Drawer in flutter doesn't have a built-in way to push/pop elements
    // on top of it like our Android counterpart. So we can override back button
    // presses and replace the main settings widget with contacts based on a bool
    return new WillPopScope(
      onWillPop: _onBackButtonPressed,
      child: ClipRect(
        child: Stack(
          children: <Widget>[
            Container(
              color: StateContainer.of(context).curTheme.backgroundDark,
              constraints: BoxConstraints.expand(),
            ),
            buildMainSettings(context),
            SlideTransition(
                position: _offsetFloat, child: ContactsList(_controller, _contactsOpen)),
            SlideTransition(
                position: _securityOffsetFloat,
                child: buildSecurityMenu(context)),
          ],
        ),
      ),
    );
  }

  Widget buildMainSettings(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StateContainer.of(context).curTheme.backgroundDark,
      ),
      child: SafeArea(
        minimum: EdgeInsets.only(
          top: 60,
        ),
        child: Column(
          children: <Widget>[
            // A container for accounts area
            Container(
              margin: EdgeInsetsDirectional.only(start: 26.0, end: 20, bottom: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Main Account
                      Container(
                        margin: EdgeInsetsDirectional.only(start: 4.0),
                        child: Stack(
                          children: <Widget>[
                            Center(
                              child: Container(
                                width: smallScreen(context)?63:78,
                                height: smallScreen(context)?63:78,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      width: 1.5,
                                      color: StateContainer.of(context)
                                          .curTheme
                                          .primary),
                                ),
                                child: SizedBox(),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Container(
                                  width: smallScreen(context)?55:70,
                                  height: smallScreen(context)?55:70,
                                  alignment: Alignment(0.5, 0.5),
                                  child: MonkeyWidget(
                                    address: StateContainer.of(context).wallet.address,
                                    size: MonkeySize.SMALL
                                  )
                                ),
                              ),
                            ),
                            Center(
                              child: Container(
                                width: smallScreen(context)?63:78,
                                height: smallScreen(context)?63:78,
                                child: FlatButton(
                                  highlightColor: StateContainer.of(context)
                                      .curTheme
                                      .backgroundDark
                                      .withOpacity(0.75),
                                  splashColor: StateContainer.of(context)
                                      .curTheme
                                      .backgroundDark
                                      .withOpacity(0.75),
                                  padding: EdgeInsets.all(0.0),
                                  child: SizedBox(
                                    width: smallScreen(context)?63:78,
                                    height: smallScreen(context)?63:78,
                                  ),
                                  onPressed: () {
                                    AccountDetailsSheet(
                                            StateContainer.of(context)
                                                .selectedAccount)
                                        .mainBottomSheet(context);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // A row for other accounts and account switcher
                      Row(
                        children: <Widget>[
                          // Second Account
                          StateContainer.of(context).recentLast != null
                              ? Container(
                                  margin: EdgeInsetsDirectional.only(end: 2),
                                  child: Stack(
                                    children: <Widget>[
                                      Center(
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                            child: MonkeyWidget(
                                              address: StateContainer.of(context).recentLast.address,
                                              size: MonkeySize.SMALLEST
                                            )
                                        ),
                                      ),
                                      Center(
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          color: Colors.transparent,
                                          child: FlatButton(
                                            onPressed: () {
                                              sl.get<DBHelper>()
                                                  .changeAccount(
                                                      StateContainer.of(context)
                                                          .recentLast)
                                                  .then((_) {
                                                EventTaxiImpl.singleton().fire(
                                                    AccountChangedEvent(
                                                        account:
                                                            StateContainer.of(
                                                                    context)
                                                                .recentLast,
                                                        delayPop: true));
                                              });
                                            },
                                            highlightColor:
                                                StateContainer.of(context)
                                                    .curTheme
                                                    .backgroundDark
                                                    .withOpacity(0.75),
                                            splashColor:
                                                StateContainer.of(context)
                                                    .curTheme
                                                    .backgroundDark
                                                    .withOpacity(0.75),
                                            padding: EdgeInsets.all(0.0),
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              color: Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox(),
                          // Third Account
                          StateContainer.of(context).recentSecondLast != null
                              ? Container(
                                  margin: EdgeInsetsDirectional.only(end: 8),
                                  child: Stack(
                                    children: <Widget>[
                                      Center(
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          child: MonkeyWidget(
                                            address: StateContainer.of(context).recentSecondLast.address,
                                            size: MonkeySize.SMALLEST
                                          )
                                        ),
                                      ),
                                      Center(
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          color: Colors.transparent,
                                          child: FlatButton(
                                            onPressed: () {
                                              sl.get<DBHelper>()
                                                  .changeAccount(
                                                      StateContainer.of(context)
                                                          .recentSecondLast)
                                                  .then((_) {
                                                EventTaxiImpl.singleton().fire(
                                                    AccountChangedEvent(
                                                        account: StateContainer
                                                                .of(context)
                                                            .recentSecondLast,
                                                        delayPop: true));
                                              });
                                            },
                                            highlightColor:
                                                StateContainer.of(context)
                                                    .curTheme
                                                    .backgroundDark
                                                    .withOpacity(0.75),
                                            splashColor:
                                                StateContainer.of(context)
                                                    .curTheme
                                                    .backgroundDark
                                                    .withOpacity(0.75),
                                            padding: EdgeInsets.all(0.0),
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              color: Colors.transparent,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SizedBox(),
                          // Account switcher
                          Container(
                            height: 36,
                            width: 36,
                            margin: EdgeInsetsDirectional.only(end: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: FlatButton(
                              onPressed: () {
                                if (!_loadingAccounts) {
                                  setState(() {
                                    _loadingAccounts = true;
                                  });
                                  sl.get<DBHelper>().getAccounts().then((accounts) {
                                    setState(() {
                                      _loadingAccounts = false;
                                    });
                                    AppAccountsSheet(accounts)
                                        .mainBottomSheet(context);
                                  });
                                }
                              },
                              padding: EdgeInsets.all(0.0),
                              shape: CircleBorder(),
                              splashColor: _loadingAccounts
                                  ? Colors.transparent
                                  : StateContainer.of(context)
                                      .curTheme
                                      .primary30,
                              highlightColor: _loadingAccounts
                                  ? Colors.transparent
                                  : StateContainer.of(context)
                                      .curTheme
                                      .primary15,
                              child: Icon(AppIcons.accountswitcher,
                                  size: 36,
                                  color: _loadingAccounts
                                      ? StateContainer.of(context)
                                          .curTheme
                                          .primary60
                                      : StateContainer.of(context)
                                          .curTheme
                                          .primary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    child: FlatButton(
                      padding: EdgeInsets.all(4.0),
                      highlightColor:
                          StateContainer.of(context).curTheme.text15,
                      splashColor: StateContainer.of(context).curTheme.text30,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.0)),
                      onPressed: () {
                        AccountDetailsSheet(
                                StateContainer.of(context).selectedAccount)
                            .mainBottomSheet(context);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Main account name
                          Container(
                            child: Text(
                              StateContainer.of(context).selectedAccount.name,
                              style: TextStyle(
                                fontFamily: "NunitoSans",
                                fontWeight: FontWeight.w600,
                                fontSize: 16.0,
                                color: StateContainer.of(context).curTheme.text,
                              ),
                            ),
                          ),
                          // Main account address
                          Container(
                            child: Text(
                              StateContainer.of(context)
                                  .wallet
                                  .address
                                  .substring(0, 11),
                              style: TextStyle(
                                fontFamily: "OverpassMono",
                                fontWeight: FontWeight.w100,
                                fontSize: 14.0,
                                color:
                                    StateContainer.of(context).curTheme.text60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
                child: Stack(
              children: <Widget>[
                ListView(
                  padding: EdgeInsets.only(top: 15.0),
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(left: 30.0, bottom: 10),
                      child: Text(AppLocalization.of(context).preferences,
                          style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w100,
                              color:
                                  StateContainer.of(context).curTheme.text60)),
                    ),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    AppSettings.buildSettingsListItemDoubleLine(
                        context,
                        AppLocalization.of(context).changeCurrency,
                        StateContainer.of(context).curCurrency,
                        AppIcons.currency,
                        _currencyDialog),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    AppSettings.buildSettingsListItemDoubleLine(
                        context,
                        AppLocalization.of(context).language,
                        StateContainer.of(context).curLanguage,
                        AppIcons.language,
                        _languageDialog),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    AppSettings.buildSettingsListItemDoubleLine(
                        context,
                        AppLocalization.of(context).notifications,
                        _curNotificiationSetting,
                        AppIcons.notifications,
                        _notificationsDialog),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    AppSettings.buildSettingsListItemDoubleLine(
                        context,
                        AppLocalization.of(context).themeHeader,
                        _curThemeSetting,
                        AppIcons.theme,
                        _themeDialog),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    AppSettings.buildSettingsListItemSingleLine(
                        context,
                        AppLocalization.of(context).securityHeader,
                        AppIcons.security, onPressed: () {
                      setState(() {
                        _securityOpen = true;
                      });
                      _securityController.forward();
                    }),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    Container(
                      margin:
                          EdgeInsetsDirectional.only(start: 30.0, top: 20.0, bottom: 10.0),
                      child: Text(AppLocalization.of(context).manage,
                          style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w100,
                              color:
                                  StateContainer.of(context).curTheme.text60)),
                    ),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    AppSettings.buildSettingsListItemSingleLine(
                        context,
                        AppLocalization.of(context).contactsHeader,
                        AppIcons.contact, onPressed: () {
                      setState(() {
                        _contactsOpen = true;
                      });
                      _controller.forward();
                    }),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    AppSettings.buildSettingsListItemSingleLine(
                        context,
                        AppLocalization.of(context).backupSeed,
                        AppIcons.backupseed, onPressed: () {
                      // Authenticate
                      sl.get<SharedPrefsUtil>().getAuthMethod().then((authMethod) {
                        sl.get<BiometricUtil>().hasBiometrics().then((hasBiometrics) {
                          if (authMethod.method == AuthMethod.BIOMETRICS &&
                              hasBiometrics) {
                            sl.get<BiometricUtil>().authenticateWithBiometrics(
                                    context,
                                    AppLocalization.of(context)
                                        .fingerprintSeedBackup)
                                .then((authenticated) {
                              if (authenticated) {
                                sl.get<HapticUtil>().fingerprintSucess();
                                new AppSeedBackupSheet()
                                    .mainBottomSheet(context);
                              }
                            });
                          } else {
                            // PIN Authentication
                            sl.get<Vault>().getPin().then((expectedPin) {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (BuildContext context) {
                                return new PinScreen(
                                  PinOverlayType.ENTER_PIN,
                                  (pin) {
                                    Navigator.of(context).pop();
                                    new AppSeedBackupSheet()
                                        .mainBottomSheet(context);
                                  },
                                  expectedPin: expectedPin,
                                  description:
                                      AppLocalization.of(context).pinSeedBackup,
                                );
                              }));
                            });
                          }
                        });
                      });
                    }),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    AppSettings.buildSettingsListItemSingleLine(
                        context,
                        AppLocalization.of(context).settingsTransfer,
                        AppIcons.transferfunds, onPressed: () {
                      AppTransferOverviewSheet().mainBottomSheet(context);
                    }),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    AppSettings.buildSettingsListItemSingleLine(
                        context,
                        AppLocalization.of(context).changeRepAuthenticate,
                        AppIcons.changerepresentative, onPressed: () {
                      new AppChangeRepresentativeSheet()
                          .mainBottomSheet(context);
                    }),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    AppSettings.buildSettingsListItemSingleLine(
                        context,
                        AppLocalization.of(context).shareKalium,
                        AppIcons.share, onPressed: () {
                      Share.share(AppLocalization.of(context).shareKaliumText +
                          " https://kalium.banano.cc");
                    }),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    AppSettings.buildSettingsListItemSingleLine(
                        context,
                        AppLocalization.of(context).logout,
                        AppIcons.logout, onPressed: () {
                      AppDialogs.showConfirmDialog(
                          context,
                          CaseChange.toUpperCase(
                              AppLocalization.of(context).warning, context),
                          AppLocalization.of(context).logoutDetail,
                          AppLocalization.of(context)
                              .logoutAction
                              .toUpperCase(), () {
                        // Show another confirm dialog
                        AppDialogs.showConfirmDialog(
                            context,
                            AppLocalization.of(context).logoutAreYouSure,
                            AppLocalization.of(context).logoutReassurance,
                            CaseChange.toUpperCase(
                                AppLocalization.of(context).yes, context), () {
                          // Unsubscribe from notifications
                          sl.get<SharedPrefsUtil>()
                              .setNotificationsOn(false)
                              .then((_) {
                            FirebaseMessaging().getToken().then((fcmToken) {
                              EventTaxiImpl.singleton()
                                  .fire(FcmUpdateEvent(token: fcmToken));
                              // Delete all data
                              sl.get<Vault>().deleteAll().then((_) {
                                sl.get<SharedPrefsUtil>().deleteAll().then((result) {
                                  StateContainer.of(context).logOut();
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/', (Route<dynamic> route) => false);
                                });
                              });
                            });
                          });
                        });
                      });
                    }),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: 10.0, bottom: 10.0, left: 20, right: 20),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          Text(versionString,
                              style: AppStyles.textStyleVersion(context)),
                          Text(" | ",
                              style: AppStyles.textStyleVersion(context)),
                          GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (BuildContext context) {
                                  return sl.get<UIUtil>().showWebview(context,
                                      AppLocalization.of(context).privacyUrl);
                                }));
                              },
                              child: Text(
                                  AppLocalization.of(context).privacyPolicy,
                                  style: AppStyles.textStyleVersionUnderline(
                                      context))),
                          Text(" | ",
                              style: AppStyles.textStyleVersion(context)),
                          GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (BuildContext context) {
                                  return sl.get<UIUtil>().showWebview(context,
                                      AppLocalization.of(context).eulaUrl);
                                }));
                              },
                              child: Text("EULA",
                                  style: AppStyles.textStyleVersionUnderline(
                                      context))),
                        ],
                      ),
                    ),
                  ].where(notNull).toList(),
                ),
                //List Top Gradient End
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 20.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          StateContainer.of(context).curTheme.backgroundDark,
                          StateContainer.of(context).curTheme.backgroundDark00
                        ],
                        begin: Alignment(0.5, -1.0),
                        end: Alignment(0.5, 1.0),
                      ),
                    ),
                  ),
                ), //List Top Gradient End
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget buildSecurityMenu(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StateContainer.of(context).curTheme.backgroundDark,
        boxShadow: [
          BoxShadow(
              color: StateContainer.of(context).curTheme.overlay30,
              offset: Offset(-5, 0),
              blurRadius: 20),
        ],
      ),
      child: SafeArea(
        minimum: EdgeInsets.only(
          top: 60,
        ),
        child: Column(
          children: <Widget>[
            // Back button and Security Text
            Container(
              margin: EdgeInsets.only(bottom: 10, top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      //Back button
                      Container(
                        height: 40,
                        width: 40,
                        margin: EdgeInsets.only(right: 10, left: 10),
                        child: FlatButton(
                            highlightColor:
                                StateContainer.of(context).curTheme.text15,
                            splashColor:
                                StateContainer.of(context).curTheme.text15,
                            onPressed: () {
                              setState(() {
                                _securityOpen = false;
                              });
                              _securityController.reverse();
                            },
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50.0)),
                            padding: EdgeInsets.all(8.0),
                            child: Icon(AppIcons.back,
                                color: StateContainer.of(context).curTheme.text,
                                size: 24)),
                      ),
                      //Security Header Text
                      Text(
                        AppLocalization.of(context).securityHeader,
                        style: AppStyles.textStyleSettingsHeader(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
                child: Stack(
              children: <Widget>[
                ListView(
                  padding: EdgeInsets.only(top: 15.0),
                  children: <Widget>[
                    Container(
                      margin: EdgeInsetsDirectional.only(start: 30.0, bottom: 10),
                      child: Text(AppLocalization.of(context).preferences,
                          style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w100,
                              color:
                                  StateContainer.of(context).curTheme.text60)),
                    ),
                    // Authentication Method
                    _hasBiometrics
                        ? Divider(
                            height: 2,
                            color: StateContainer.of(context).curTheme.text15,
                          )
                        : null,
                    _hasBiometrics
                        ? AppSettings.buildSettingsListItemDoubleLine(
                            context,
                            AppLocalization.of(context).authMethod,
                            _curAuthMethod,
                            AppIcons.fingerprint,
                            _authMethodDialog)
                        : null,
                    // Authenticate on Launch
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    AppSettings.buildSettingsListItemDoubleLine(
                        context,
                        AppLocalization.of(context).lockAppSetting,
                        _curUnlockSetting,
                        AppIcons.lock,
                        _lockDialog),
                    // Authentication Timer
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                    AppSettings.buildSettingsListItemDoubleLine(
                      context,
                      AppLocalization.of(context).autoLockHeader,
                      _curTimeoutSetting,
                      AppIcons.timer,
                      _lockTimeoutDialog,
                      disabled: _curUnlockSetting.setting == UnlockOption.NO,
                    ),
                    Divider(
                      height: 2,
                      color: StateContainer.of(context).curTheme.text15,
                    ),
                  ].where(notNull).toList(),
                ),
                //List Top Gradient End
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 20.0,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          StateContainer.of(context).curTheme.backgroundDark,
                          StateContainer.of(context).curTheme.backgroundDark00
                        ],
                        begin: Alignment(0.5, -1.0),
                        end: Alignment(0.5, 1.0),
                      ),
                    ),
                  ),
                ), //List Top Gradient End
              ],
            )),
          ],
        ),
      ),
    );
  }
}
