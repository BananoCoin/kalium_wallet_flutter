import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nano_ffi/flutter_nano_ffi.dart';
import 'package:kalium_wallet_flutter/app_icons.dart';

import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/model/db/account.dart';
import 'package:kalium_wallet_flutter/model/db/appdb.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';

import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/ui/util/formatters.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/ui/widgets/app_text_field.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:kalium_wallet_flutter/ui/widgets/flat_button.dart';
import 'package:kalium_wallet_flutter/util/nanoutil.dart';
import 'package:keyboard_avoider/keyboard_avoider.dart';
import 'package:logger/logger.dart';

class ImportExternalAccountSheet extends StatefulWidget {
  final Function accountAddedCallback;

  ImportExternalAccountSheet({@required this.accountAddedCallback}) : super();
  _ImportExternalAccountSheetState createState() =>
      _ImportExternalAccountSheetState();
}

class _ImportExternalAccountSheetState
    extends State<ImportExternalAccountSheet> {
  @override
  void initState() {
    super.initState();
  }

  // Plaintext seed
  FocusNode _seedInputFocusNode = FocusNode();
  TextEditingController _seedInputController = TextEditingController();
  // Mnemonic Phrase
  FocusNode _mnemonicFocusNode = FocusNode();
  TextEditingController _mnemonicController = TextEditingController();

  // Index
  FocusNode _indexInputFocusNode = FocusNode();
  TextEditingController _indexInputController = TextEditingController();
  var defaultIndex = 0;

  bool _seedMode = false; // False if restoring phrase, true if restoring seed

  bool _seedIsValid = false;
  bool _showSeedError = false;
  bool _mnemonicIsValid = false;
  String _mnemonicError;

  void _importAdHocAccount() async {
    // Validations
    int selectedIndex = _indexInputController.text.isEmpty
        ? 0
        : int.tryParse(_indexInputController.text);
    if (selectedIndex == null || selectedIndex < 0) {
      sl.get<UIUtil>().showSnackbar(
          AppLocalization.of(context).adHocAccountInvalidIndex, context);
      return;
    }

    if (_seedMode && !NanoSeeds.isValidSeed(_seedInputController.text)) {
      sl
          .get<UIUtil>()
          .showSnackbar(AppLocalization.of(context).seedInvalid, context);
      return;
    }

    if (!_seedMode &&
        !NanoMnemomics.validateMnemonic(_mnemonicController.text.split(' '))) {
      sl.get<UIUtil>().showSnackbar(
          AppLocalization.of(context).secretPhraseInvalid, context);
      return;
    }

    String seed = _seedMode
        ? _seedInputController.text
        : NanoMnemomics.mnemonicListToSeed(_mnemonicController.text.split(' '));

    // Derive private key
    String privateKey = NanoUtil.seedToPrivate(seed, selectedIndex);

    // See if account exists
    bool accountExists = await sl.get<DBHelper>().accountExists(privateKey);
    if (accountExists) {
      sl.get<UIUtil>().showSnackbar(
          AppLocalization.of(context).importedAdHocAccountAlreadyExists,
          context);
      return;
    }

    // Add account
    try {
      Account acct = await sl.get<DBHelper>().addAccountWithPrivateKey(
          accountName: AppLocalization.of(context).defaultNewAccountNameAdHoc,
          privateKey: privateKey);
      widget.accountAddedCallback(acct);
      Navigator.of(context).pop();
    } catch (e) {
      sl.get<Logger>().e("Error importing account: $e");
      sl.get<UIUtil>().showSnackbar(
          AppLocalization.of(context).adHocAccountImportedError, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // The main column that holds everything
    return SafeArea(
      minimum:
          EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.035),
      child: Column(
        children: <Widget>[
          // A row for the header of the sheet, balance text and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              //Empty SizedBox
              SizedBox(
                width: 60,
                height: 60,
              ),

              // Container for the header, address and balance text
              Column(
                children: <Widget>[
                  // Sheet handle
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    height: 5,
                    width: MediaQuery.of(context).size.width * 0.15,
                    decoration: BoxDecoration(
                      color: StateContainer.of(context).curTheme.text10,
                      borderRadius: BorderRadius.circular(100.0),
                    ),
                  ),
                ],
              ),
              // Secret phrase / seed toggle
              Container(
                width: 50,
                height: 50,
                margin: EdgeInsetsDirectional.only(top: 10.0, end: 10.0),
                child: FlatButton(
                  highlightColor: StateContainer.of(context).curTheme.text15,
                  splashColor: StateContainer.of(context).curTheme.text15,
                  onPressed: () {
                    setState(() {
                      _seedMode = !_seedMode;
                    });
                  },
                  child: Icon(_seedMode ? Icons.vpn_key : AppIcons.seed,
                      size: 24,
                      color: StateContainer.of(context).curTheme.text),
                  padding: EdgeInsets.all(13.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100.0)),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                ),
              ),
            ],
          ),
          // A main container that holds everything
          Expanded(
            child: KeyboardAvoider(
              duration: Duration(milliseconds: 0),
              autoScroll: true,
              focusPadding: 40,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 64),
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(
                          left: smallScreen(context) ? 24 : 32,
                          right: smallScreen(context) ? 24 : 32),
                      alignment: Alignment.centerLeft,
                      child: AutoSizeText(
                        _seedMode
                            ? AppLocalization.of(context).seed
                            : AppLocalization.of(context).secretPhrase,
                        style: TextStyle(
                          color: StateContainer.of(context).curTheme.text,
                          fontSize: 22.0,
                          fontFamily: 'NunitoSans',
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.left,
                        maxLines: null,
                        stepGranularity: 0.1,
                      ),
                    ),
                    // Explanation text for secret phrase
                    Container(
                      margin: EdgeInsets.only(
                          left: smallScreen(context) ? 24 : 32,
                          right: smallScreen(context) ? 24 : 32,
                          top: 6.0),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _seedMode
                            ? AppLocalization.of(context).importSeedHint
                            : AppLocalization.of(context)
                                .importSecretPhraseHint,
                        style: AppStyles.textStyleParagraph(context),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    // Input
                    TextFieldTapRegion(
                      onTapOutside: (ev) {
                        _seedInputFocusNode.unfocus();
                        _mnemonicFocusNode.unfocus();
                      },
                      child: _seedMode
                          ? AppTextField(
                              leftMargin: smallScreen(context) ? 24 : 32,
                              rightMargin: smallScreen(context) ? 24 : 32,
                              topMargin: 16,
                              focusNode: _seedInputFocusNode,
                              controller: _seedInputController,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(64),
                                UpperCaseTextFormatter()
                              ],
                              textInputAction: TextInputAction.done,
                              maxLines: null,
                              autocorrect: false,
                              prefixButton: TextFieldButton(
                                icon: AppIcons.scan,
                                onPressed: () {
                                  if (NanoSeeds.isValidSeed(
                                      _seedInputController.text)) {
                                    return;
                                  }
                                  // Scan QR for seed
                                  sl.get<UIUtil>().cancelLockEvent();
                                  BarcodeScanner.scan(StateContainer.of(context)
                                          .curTheme
                                          .qrScanTheme)
                                      .then((result) {
                                    if (result != null &&
                                        NanoSeeds.isValidSeed(result)) {
                                      _seedInputController.text = result;
                                      setState(() {
                                        _seedIsValid = true;
                                      });
                                    } else if (result != null &&
                                        NanoMnemomics.validateMnemonic(
                                            result.split(' '))) {
                                      _mnemonicController.text = result;
                                      _mnemonicFocusNode.unfocus();
                                      _seedInputFocusNode.unfocus();
                                      setState(() {
                                        _seedMode = false;
                                        _mnemonicError = null;
                                        _mnemonicIsValid = true;
                                      });
                                    } else {
                                      sl.get<UIUtil>().showSnackbar(
                                          AppLocalization.of(context)
                                              .qrInvalidSeed,
                                          context);
                                    }
                                  });
                                },
                              ),
                              fadePrefixOnCondition: true,
                              prefixShowFirstCondition: !NanoSeeds.isValidSeed(
                                  _seedInputController.text),
                              suffixButton: TextFieldButton(
                                icon: AppIcons.paste,
                                onPressed: () {
                                  if (NanoSeeds.isValidSeed(
                                      _seedInputController.text)) {
                                    return;
                                  }
                                  Clipboard.getData("text/plain")
                                      .then((ClipboardData data) {
                                    if (data == null || data.text == null) {
                                      return;
                                    } else if (NanoSeeds.isValidSeed(
                                        data.text)) {
                                      _seedInputController.text = data.text;
                                      setState(() {
                                        _seedIsValid = true;
                                      });
                                    } else if (NanoMnemomics.validateMnemonic(
                                        data.text.split(' '))) {
                                      _mnemonicController.text = data.text;
                                      _mnemonicFocusNode.unfocus();
                                      _seedInputFocusNode.unfocus();
                                      setState(() {
                                        _seedMode = false;
                                        _mnemonicError = null;
                                        _mnemonicIsValid = true;
                                      });
                                    }
                                  });
                                },
                              ),
                              fadeSuffixOnCondition: true,
                              suffixShowFirstCondition: !NanoSeeds.isValidSeed(
                                  _seedInputController.text),
                              keyboardType: TextInputType.text,
                              style: _seedIsValid
                                  ? AppStyles.textStyleSeed(context)
                                  : AppStyles.textStyleSeedGray(context),
                              onChanged: (text) {
                                // Always reset the error message to be less annoying
                                setState(() {
                                  _showSeedError = false;
                                });
                                // If valid seed, clear focus/close keyboard
                                if (NanoSeeds.isValidSeed(text)) {
                                  _seedInputFocusNode.unfocus();
                                  setState(() {
                                    _seedIsValid = true;
                                  });
                                } else {
                                  setState(() {
                                    _seedIsValid = false;
                                  });
                                }
                              })
                          : // Mnemonic mode
                          AppTextField(
                              leftMargin: smallScreen(context) ? 24 : 32,
                              rightMargin: smallScreen(context) ? 24 : 32,
                              topMargin: 16,
                              focusNode: _mnemonicFocusNode,
                              controller: _mnemonicController,
                              inputFormatters: [
                                SingleSpaceInputFormatter(),
                                LowerCaseTextFormatter(),
                                FilteringTextInputFormatter.allow(
                                  RegExp("[a-zA-Z ]"),
                                ),
                              ],
                              textInputAction: TextInputAction.done,
                              maxLines: null,
                              autocorrect: false,
                              prefixButton: TextFieldButton(
                                icon: AppIcons.scan,
                                onPressed: () {
                                  if (NanoMnemomics.validateMnemonic(
                                      _mnemonicController.text.split(' '))) {
                                    return;
                                  }
                                  // Scan QR for mnemonic
                                  sl.get<UIUtil>().cancelLockEvent();
                                  BarcodeScanner.scan(StateContainer.of(context)
                                          .curTheme
                                          .qrScanTheme)
                                      .then((result) {
                                    if (result != null &&
                                        NanoMnemomics.validateMnemonic(
                                            result.split(' '))) {
                                      _mnemonicController.text = result;
                                      setState(() {
                                        _mnemonicIsValid = true;
                                      });
                                    } else if (result != null &&
                                        NanoSeeds.isValidSeed(result)) {
                                      _seedInputController.text = result;
                                      _mnemonicFocusNode.unfocus();
                                      _seedInputFocusNode.unfocus();
                                      setState(() {
                                        _seedMode = true;
                                        _seedIsValid = true;
                                        _showSeedError = false;
                                      });
                                    } else {
                                      sl.get<UIUtil>().showSnackbar(
                                          AppLocalization.of(context)
                                              .qrMnemonicError,
                                          context);
                                    }
                                  });
                                },
                              ),
                              fadePrefixOnCondition: true,
                              prefixShowFirstCondition:
                                  !NanoMnemomics.validateMnemonic(
                                      _mnemonicController.text.split(' ')),
                              suffixButton: TextFieldButton(
                                icon: AppIcons.paste,
                                onPressed: () {
                                  if (NanoMnemomics.validateMnemonic(
                                      _mnemonicController.text.split(' '))) {
                                    return;
                                  }
                                  Clipboard.getData("text/plain")
                                      .then((ClipboardData data) {
                                    if (data == null || data.text == null) {
                                      return;
                                    } else if (NanoMnemomics.validateMnemonic(
                                        data.text.split(' '))) {
                                      _mnemonicController.text = data.text;
                                      setState(() {
                                        _mnemonicIsValid = true;
                                      });
                                    } else if (NanoSeeds.isValidSeed(
                                        data.text)) {
                                      _seedInputController.text = data.text;
                                      _mnemonicFocusNode.unfocus();
                                      _seedInputFocusNode.unfocus();
                                      setState(() {
                                        _seedMode = true;
                                        _seedIsValid = true;
                                        _showSeedError = false;
                                      });
                                    }
                                  });
                                },
                              ),
                              fadeSuffixOnCondition: true,
                              suffixShowFirstCondition:
                                  !NanoMnemomics.validateMnemonic(
                                      _mnemonicController.text.split(' ')),
                              keyboardType: TextInputType.text,
                              style: _mnemonicIsValid
                                  ? AppStyles.textStyleParagraphPrimary(context)
                                  : AppStyles.textStyleParagraph(context),
                              onChanged: (text) {
                                if (text.length < 3) {
                                  setState(() {
                                    _mnemonicError = null;
                                  });
                                } else if (_mnemonicError != null) {
                                  if (!text
                                      .contains(_mnemonicError.split(' ')[0])) {
                                    setState(() {
                                      _mnemonicError = null;
                                    });
                                  }
                                }
                                // If valid mnemonic, clear focus/close keyboard
                                if (NanoMnemomics.validateMnemonic(
                                    text.split(' '))) {
                                  _mnemonicFocusNode.unfocus();
                                  setState(() {
                                    _mnemonicIsValid = true;
                                    _mnemonicError = null;
                                  });
                                } else {
                                  setState(() {
                                    _mnemonicIsValid = false;
                                  });
                                  // Validate each mnemonic word
                                  if (text.endsWith(" ") && text.length > 1) {
                                    int lastSpaceIndex = text
                                        .substring(0, text.length - 1)
                                        .lastIndexOf(" ");
                                    if (lastSpaceIndex == -1) {
                                      lastSpaceIndex = 0;
                                    } else {
                                      lastSpaceIndex++;
                                    }
                                    String lastWord = text.substring(
                                        lastSpaceIndex, text.length - 1);
                                    if (!NanoMnemomics.isValidWord(lastWord)) {
                                      setState(() {
                                        _mnemonicIsValid = false;
                                        setState(() {
                                          _mnemonicError =
                                              AppLocalization.of(context)
                                                  .mnemonicInvalidWord
                                                  .replaceAll("%1", lastWord);
                                        });
                                      });
                                    }
                                  }
                                }
                              },
                            ),
                    ),
                    // "Invalid Seed" text that appears if the input is invalid
                    Container(
                      margin: EdgeInsets.only(
                        top: 5,
                        left: smallScreen(context) ? 24 : 32,
                        right: smallScreen(context) ? 24 : 32,
                      ),
                      child: Text(
                          !_seedMode
                              ? _mnemonicError == null
                                  ? ""
                                  : _mnemonicError
                              : _showSeedError
                                  ? AppLocalization.of(context).seedInvalid
                                  : "",
                          style: TextStyle(
                            fontSize: 14.0,
                            color: _seedMode
                                ? _showSeedError
                                    ? StateContainer.of(context)
                                        .curTheme
                                        .primary
                                    : Colors.transparent
                                : _mnemonicError != null
                                    ? StateContainer.of(context)
                                        .curTheme
                                        .primary
                                    : Colors.transparent,
                            fontFamily: 'NunitoSans',
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    // Header for the "Account Index"
                    Container(
                      margin: EdgeInsets.only(
                          left: smallScreen(context) ? 24 : 32,
                          right: smallScreen(context) ? 24 : 32,
                          top: 12),
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  AppLocalization.of(context).accountIndexTitle,
                              style: TextStyle(
                                color: StateContainer.of(context).curTheme.text,
                                fontSize: 22.0,
                                fontFamily: 'NunitoSans',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: "  " +
                                  AppLocalization.of(context)
                                      .optionalFieldIndicator,
                              style: TextStyle(
                                color:
                                    StateContainer.of(context).curTheme.text60,
                                fontSize: 16.0,
                                fontFamily: 'NunitoSans',
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    // Explanation text for index
                    Container(
                      margin: EdgeInsets.only(
                          left: smallScreen(context) ? 24 : 32,
                          right: smallScreen(context) ? 24 : 32,
                          top: 6.0),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Index of the account you want to import.",
                        style: AppStyles.textStyleParagraph(context),
                        textAlign: TextAlign.start,
                      ),
                    ),
                    // Index field
                    TextFieldTapRegion(
                      onTapOutside: (ev) {
                        _indexInputFocusNode.unfocus();
                      },
                      child: AppTextField(
                        leftMargin: smallScreen(context) ? 24 : 32,
                        rightMargin: smallScreen(context) ? 24 : 32,
                        topMargin: 16,
                        hintText: defaultIndex.toString(),
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: false,
                          signed: false,
                        ),
                        focusNode: _indexInputFocusNode,
                        controller: _indexInputController,
                        inputFormatters: [],
                        textInputAction: TextInputAction.done,
                        maxLines: null,
                        autocorrect: false,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          //A column with "Import" and "Cancel" buttons
          Container(
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    // Import Button
                    AppButton.buildAppButton(
                      context,
                      AppButtonType.PRIMARY,
                      AppLocalization.of(context).import,
                      Dimens.BUTTON_TOP_DIMENS,
                      onPressed: _importAdHocAccount,
                      disabled: _seedMode && !_seedIsValid ||
                          !_seedMode && !_mnemonicIsValid,
                    ),
                  ],
                ),
                Row(
                  children: <Widget>[
                    // Cancel Button
                    AppButton.buildAppButton(
                        context,
                        AppButtonType.PRIMARY_OUTLINE,
                        AppLocalization.of(context).cancel,
                        Dimens.BUTTON_BOTTOM_DIMENS, onPressed: () {
                      Navigator.pop(context);
                    })
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
