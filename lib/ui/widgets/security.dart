import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/app_icons.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/ui/widgets/auto_resize_text.dart';
import 'package:kalium_wallet_flutter/util/hapticutil.dart';
import 'package:kalium_wallet_flutter/util/sharedprefsutil.dart';

enum PinOverlayType { NEW_PIN, ENTER_PIN }

class ShakeCurve extends Curve {
  @override
  double transform(double t) {
    //t from 0.0 to 1.0
    return sin(t * 3 * pi);
  }
}

class PinScreen extends StatefulWidget {
  final PinOverlayType type;
  final String expectedPin;
  final String description;
  final Function pinSuccessCallback;
  final Color pinScreenBackgroundColor;

  PinScreen(this.type, this.pinSuccessCallback,
      {this.description = "", this.expectedPin = "", this.pinScreenBackgroundColor});

  @override
  _PinScreenState createState() =>
      _PinScreenState(type, expectedPin, description, pinSuccessCallback, pinScreenBackgroundColor);
}

class _PinScreenState extends State<PinScreen>
    with SingleTickerProviderStateMixin {
  static const int MAX_ATTEMPTS = 5;

  _PinScreenState(
      this.type, this.expectedPin, this.description, this.successCallback, this.pinScreenBackgroundColor) {
        if (this.pinScreenBackgroundColor == null) {
          pinScreenBackgroundColor = StateContainer.of(context).curTheme.backgroundDark;
        }
  }

  PinOverlayType type;
  String expectedPin;
  Function successCallback;
  String description;
  Color pinScreenBackgroundColor;
  double buttonSize = 100.0;

  String pinEnterTitle = "";
  String pinCreateTitle = "";

  // Stateful data
  List<IconData> _dotStates;
  String _pin;
  String _pinConfirmed;
  bool
      _awaitingConfirmation; // true if pin has been entered once, false if not entered once
  String _header;
  int _failedAttempts = 0;

  // Invalid animation
  AnimationController _controller;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Initialize list all empty
    _dotStates = List.filled(6, AppIcons.dotemtpy);
    _awaitingConfirmation = false;
    _pin = "";
    _pinConfirmed = "";
    // Get adjusted failed attempts
    SharedPrefsUtil.inst.getLockAttempts().then((attempts) {
      setState(() {
        _failedAttempts = attempts % MAX_ATTEMPTS;
      });
    });
    if (type == PinOverlayType.ENTER_PIN) {
      _header = pinEnterTitle;
    } else {
      _header = pinCreateTitle;
    }
    // Set animation
    _controller = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this);
    final Animation curve =
        CurvedAnimation(parent: _controller, curve: ShakeCurve());
    _animation = Tween(begin: 0.0, end: 25.0).animate(curve)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (type == PinOverlayType.ENTER_PIN) {
            SharedPrefsUtil.inst.incrementLockAttempts().then((_) {
              _failedAttempts++;
              if (_failedAttempts >= MAX_ATTEMPTS) {
                setState(() {
                  _controller.value = 0;
                });
                SharedPrefsUtil.inst.updateLockDate().then((_) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/lock_screen_transition', (Route<dynamic> route) => false);
                });
              } else {
                setState(() {
                  _pin = "";
                  _header = AppLocalization.of(context).pinInvalid;
                  _dotStates = List.filled(6, AppIcons.dotemtpy);
                  _controller.value = 0;
                });
              }
            });
          } else {
            setState(() {
              _awaitingConfirmation = false;
              _dotStates = List.filled(6, AppIcons.dotemtpy);
              _pin = "";
              _pinConfirmed = "";
              _header = AppLocalization.of(context).pinConfirmError;
              _controller.value = 0;
            });
          }
        }
      })
      ..addListener(() {
        setState(() {
          // the animation object’s value is the changed state
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Set next character in the pin set
  /// return true if all characters entered
  bool _setCharacter(String character) {
    if (_awaitingConfirmation) {
      setState(() {
        _pinConfirmed = _pinConfirmed + character;
      });
    } else {
      setState(() {
        _pin = _pin + character;
      });
    }
    for (int i = 0; i < _dotStates.length; i++) {
      if (_dotStates[i] == AppIcons.dotemtpy) {
        setState(() {
          _dotStates[i] = AppIcons.dotfilled;
        });
        break;
      }
    }
    if (_dotStates.last == AppIcons.dotfilled) {
      return true;
    }
    return false;
  }

  void _backSpace() {
    if (_dotStates[0] != AppIcons.dotemtpy) {
      int lastFilledIndex;
      for (int i = 0; i < _dotStates.length; i++) {
        if (_dotStates[i] == AppIcons.dotfilled) {
          if (i == _dotStates.length ||
              _dotStates[i + 1] == AppIcons.dotemtpy) {
            lastFilledIndex = i;
            break;
          }
        }
      }
      setState(() {
        _dotStates[lastFilledIndex] = AppIcons.dotemtpy;
        if (_awaitingConfirmation) {
          _pinConfirmed = _pinConfirmed.substring(0, _pinConfirmed.length - 1);
        } else {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      });
    }
  }

  Widget _buildPinScreenButton(String buttonText, BuildContext context) {
    return Container(
      height: smallScreen(context) ? buttonSize - 15 : buttonSize,
      width: smallScreen(context) ? buttonSize - 15 : buttonSize,
      child: InkWell(
        borderRadius: BorderRadius.circular(200),
        highlightColor: StateContainer.of(context).curTheme.primary15,
        splashColor: StateContainer.of(context).curTheme.primary30,
        onTap: () {},
        onTapDown: (details) {
          if (_controller.status == AnimationStatus.forward ||
              _controller.status == AnimationStatus.reverse) {
            return;
          }
          if (_setCharacter(buttonText)) {
            // Mild delay so they can actually see the last dot get filled
            Future.delayed(Duration(milliseconds: 50), () {
              if (type == PinOverlayType.ENTER_PIN) {
                // Pin is not what was expected
                if (_pin != expectedPin) {
                  HapticUtil.error();
                  _controller.forward();
                } else {
                  SharedPrefsUtil.inst.resetLockAttempts().then((_) {
                    successCallback(_pin);
                  });
                }
              } else {
                if (!_awaitingConfirmation) {
                  // Switch to confirm pin
                  setState(() {
                    _awaitingConfirmation = true;
                    _dotStates = List.filled(6, AppIcons.dotemtpy);
                    _header = AppLocalization.of(context).pinConfirmTitle;
                  });
                } else {
                  // First and second pins match
                  if (_pin == _pinConfirmed) {
                    successCallback(_pin);
                  } else {
                    HapticUtil.error();
                    _controller.forward();
                  }
                }
              }
            });
          }
        },
        child: Container(
          alignment: Alignment(0, 0),
          child: Text(
            buttonText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.0,
              color: StateContainer.of(context).curTheme.primary,
              fontFamily: 'NunitoSans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (pinEnterTitle.isEmpty) {
      setState(() {
        pinEnterTitle = AppLocalization.of(context).pinEnterTitle;
        if (type == PinOverlayType.ENTER_PIN) {
          _header = pinEnterTitle;
        }
      });
    }
    if (pinCreateTitle.isEmpty) {
      setState(() {
        pinCreateTitle = AppLocalization.of(context).pinCreateTitle;
        if (type == PinOverlayType.NEW_PIN) {
          _header = pinCreateTitle;
        }
      });
    }

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
        statusBarIconBrightness: Brightness.light,
        statusBarColor: Colors.transparent));

    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Container(
        constraints: BoxConstraints.expand(),
        child: Material(
          color: pinScreenBackgroundColor,
          child: Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.1),
                child: Column(
                  children: <Widget>[
                    // Header
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 40),
                      child: AutoSizeText(
                        _header,
                        style: AppStyles.textStylePinScreenHeaderColored(context),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        stepGranularity: 0.1,
                      ),
                    ),
                    // Descripttion
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                      child: AutoSizeText(
                        description,
                        style: AppStyles.textStyleParagraph(context),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        stepGranularity: 0.1,
                      ),
                    ),
                    // Dots
                    Container(
                      margin: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width * 0.25 +
                            _animation.value,
                        right: MediaQuery.of(context).size.width * 0.25 -
                            _animation.value,
                        top: MediaQuery.of(context).size.height * 0.02,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          Icon(
                            _dotStates[0],
                            color: StateContainer.of(context).curTheme.primary,
                            size: 20.0,
                          ),
                          Icon(
                            _dotStates[1],
                            color: StateContainer.of(context).curTheme.primary,
                            size: 20.0,
                          ),
                          Icon(
                            _dotStates[2],
                            color: StateContainer.of(context).curTheme.primary,
                            size: 20.0,
                          ),
                          Icon(
                            _dotStates[3],
                            color: StateContainer.of(context).curTheme.primary,
                            size: 20.0,
                          ),
                          Icon(
                            _dotStates[4],
                            color: StateContainer.of(context).curTheme.primary,
                            size: 20.0,
                          ),
                          Icon(
                            _dotStates[5],
                            color: StateContainer.of(context).curTheme.primary,
                            size: 20.0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width * 0.07,
                      right: MediaQuery.of(context).size.width * 0.07,
                      bottom: smallScreen(context)
                          ? MediaQuery.of(context).size.height * 0.02
                          : MediaQuery.of(context).size.height * 0.05,
                      top: MediaQuery.of(context).size.height * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height * 0.01),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            _buildPinScreenButton("1", context),
                            _buildPinScreenButton("2", context),
                            _buildPinScreenButton("3", context),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height * 0.01),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            _buildPinScreenButton("4", context),
                            _buildPinScreenButton("5", context),
                            _buildPinScreenButton("6", context),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height * 0.01),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            _buildPinScreenButton("7", context),
                            _buildPinScreenButton("8", context),
                            _buildPinScreenButton("9", context),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height * 0.009),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            SizedBox(
                              height: smallScreen(context)
                                  ? buttonSize - 15
                                  : buttonSize,
                              width: smallScreen(context)
                                  ? buttonSize - 15
                                  : buttonSize,
                            ),
                            _buildPinScreenButton("0", context),
                            Container(
                              height: smallScreen(context)
                                  ? buttonSize - 15
                                  : buttonSize,
                              width: smallScreen(context)
                                  ? buttonSize - 15
                                  : buttonSize,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(200),
                                highlightColor: StateContainer.of(context).curTheme.primary15,
                                splashColor: StateContainer.of(context).curTheme.primary30,
                                onTap: () {},
                                onTapDown: (details) {
                                  _backSpace();
                                },
                                child: Container(
                                  alignment: Alignment(0, 0),
                                  child: Icon(Icons.backspace,
                                      color: StateContainer.of(context).curTheme.primary, size: 20.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
