import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nano_core/flutter_nano_core.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/app_icons.dart';
import 'package:kalium_wallet_flutter/ui/widgets/auto_resize_text.dart';
import 'package:kalium_wallet_flutter/ui/widgets/sheets.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/util/caseconverter.dart';

class AppTransferManualEntrySheet {
  Function validSeedCallback;

  AppTransferManualEntrySheet(this.validSeedCallback);

  var _seedInputFocusNode = new FocusNode();
  var _seedInputController = new TextEditingController();
  // State constants
  TextStyle _initialSeedTextStyle;
  TextStyle _validSeedTextStyle;
  static const _initialErrorTextColor = Colors.transparent;
  Color _hasErrorTextColor;
  // State variables
  var _seedTextStyle;
  var _errorTextColor;

  mainBottomSheet(BuildContext context) {
    _seedTextStyle = _initialSeedTextStyle;
    _errorTextColor = _initialErrorTextColor;
    _hasErrorTextColor = StateContainer.of(context).curTheme.primary;
    _initialSeedTextStyle = AppStyles.textStyleSeedGray(context);
    _validSeedTextStyle = AppStyles.textStyleSeed(context);
    AppSheets.showAppHeightNineSheet(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Container(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  //A container for the header
                  Container(
                    margin: EdgeInsets.only(top: 30.0, left: 70, right: 70),
                    child: AutoSizeText(
                      CaseChange.toUpperCase(
                          AppLocalization.of(context).transferHeader, context),
                      style: AppStyles.textStyleHeader(context),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      stepGranularity: 0.1,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.05),
                      child: Stack(
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              // Clear focus of our fields when tapped in this empty space
                              _seedInputFocusNode.unfocus();
                            },
                            child: Container(
                              color: Colors.transparent,
                              child: SizedBox.expand(),
                              constraints: BoxConstraints.expand(),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              // The paragraph
                              Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: smallScreen(context) ? 50 : 60,
                                    vertical: 10),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  AppLocalization.of(context)
                                      .transferManualHint,
                                  style: AppStyles.textStyleParagraph(context),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              // The container for the seed
                              Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.105,
                                ),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: StateContainer.of(context)
                                      .curTheme
                                      .backgroundDarkest,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                // Text Field for the seed
                                child: TextField(
                                  focusNode: _seedInputFocusNode,
                                  controller: _seedInputController,
                                  textAlign: TextAlign.center,
                                  cursorColor: StateContainer.of(context)
                                      .curTheme
                                      .primary,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(64),
                                  ],
                                  textInputAction: TextInputAction.done,
                                  maxLines: null,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    // Emtpy SizedBox
                                    prefixIcon: SizedBox(
                                      width: 48,
                                      height: 48,
                                    ),
                                    // Paste Button
                                    suffixIcon: AnimatedCrossFade(
                                      duration: Duration(milliseconds: 100),
                                      firstChild: Container(
                                        width: 48,
                                        height: 48,
                                        child: FlatButton(
                                          child: Icon(AppIcons.paste,
                                              size: 20,
                                              color: StateContainer.of(context)
                                                  .curTheme
                                                  .primary),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(100.0)),
                                          padding: EdgeInsets.all(14.0),
                                          onPressed: () {
                                            Clipboard.getData("text/plain")
                                                .then((ClipboardData data) {
                                              if (data == null ||
                                                  data.text == null) {
                                                return;
                                              } else if (NanoSeeds.isValidSeed(
                                                  data.text)) {
                                                _seedInputController.text =
                                                    data.text;
                                                setState(() {
                                                  _seedTextStyle =
                                                      _validSeedTextStyle;
                                                });
                                              } else {
                                                setState(() {
                                                  _seedTextStyle =
                                                      _initialSeedTextStyle;
                                                });
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      secondChild: SizedBox(),
                                      crossFadeState: NanoSeeds.isValidSeed(
                                              _seedInputController.text)
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                    ),
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      fontFamily: 'NunitoSans',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w100,
                                      color: StateContainer.of(context)
                                          .curTheme
                                          .text60,
                                    ),
                                  ),
                                  keyboardType: TextInputType.text,
                                  style: _seedTextStyle,
                                  onChanged: (text) {
                                    // Always reset the error message to be less annoying
                                    setState(() {
                                      _errorTextColor = _initialErrorTextColor;
                                    });
                                    // If valid seed, clear focus/close keyboard
                                    if (NanoSeeds.isValidSeed(text)) {
                                      _seedInputFocusNode.unfocus();
                                      setState(() {
                                        _seedTextStyle = _validSeedTextStyle;
                                      });
                                    } else {
                                      setState(() {
                                        _seedTextStyle = _initialSeedTextStyle;
                                      });
                                    }
                                  },
                                ),
                              ),
                              // "Invalid Seed" text that appears if the input is invalid
                              Container(
                                margin: EdgeInsets.only(top: 5),
                                child: Text(
                                    AppLocalization.of(context).seedInvalid,
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      color: _errorTextColor,
                                      fontFamily: 'NunitoSans',
                                      fontWeight: FontWeight.w600,
                                    )),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  Row(
                    children: <Widget>[
                      AppButton.buildAppButton(
                        context,
                        AppButtonType.PRIMARY,
                        AppLocalization.of(context).transfer,
                        Dimens.BUTTON_TOP_DIMENS,
                        onPressed: () {
                          if (NanoSeeds.isValidSeed(
                              _seedInputController.text)) {
                            validSeedCallback(_seedInputController.text);
                          } else {
                            setState(() {
                              _errorTextColor =
                                  StateContainer.of(context).curTheme.primary;
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  Row(
                    children: <Widget>[
                      AppButton.buildAppButton(
                        context,
                        AppButtonType.PRIMARY_OUTLINE,
                        AppLocalization.of(context).cancel,
                        Dimens.BUTTON_BOTTOM_DIMENS,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          });
        });
  }
}
