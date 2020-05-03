import 'dart:async';

import 'package:flutter/material.dart';

import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/model/db/appdb.dart';
import 'package:kalium_wallet_flutter/model/db/contact.dart';
import 'package:kalium_wallet_flutter/network/account_service.dart';
import 'package:kalium_wallet_flutter/network/model/response/process_response.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/ui/send/send_complete_sheet.dart';
import 'package:kalium_wallet_flutter/ui/util/routes.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:kalium_wallet_flutter/ui/widgets/dialog.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/ui/widgets/sheet_util.dart';
import 'package:kalium_wallet_flutter/util/nanoutil.dart';
import 'package:kalium_wallet_flutter/util/numberutil.dart';
import 'package:kalium_wallet_flutter/util/sharedprefsutil.dart';
import 'package:kalium_wallet_flutter/util/biometrics.dart';
import 'package:kalium_wallet_flutter/util/hapticutil.dart';
import 'package:kalium_wallet_flutter/util/caseconverter.dart';
import 'package:kalium_wallet_flutter/model/authentication_method.dart';
import 'package:kalium_wallet_flutter/model/vault.dart';
import 'package:kalium_wallet_flutter/ui/widgets/security.dart';

class SendConfirmSheet extends StatefulWidget {
  final String amountRaw;
  final String destination;
  final String contactName;
  final String localCurrency;
  final bool maxSend;
  SendConfirmSheet(
      {this.amountRaw,
      this.destination,
      this.contactName,
      this.localCurrency,
      this.maxSend = false})
      : super();

  _SendConfirmSheetState createState() => _SendConfirmSheetState();
}

class _SendConfirmSheetState extends State<SendConfirmSheet> {
  String amount;
  bool animationOpen;
  bool sent;
  bool isMantaTransaction;
  StateContainerState state;

  @override
  void initState() {
    super.initState();
    this.animationOpen = false;
    this.sent = false;
    // Derive amount from raw amount
    if (NumberUtil.getRawAsUsableString(widget.amountRaw).replaceAll(",", "") ==
        NumberUtil.getRawAsUsableDecimal(widget.amountRaw).toString()) {
      amount = NumberUtil.getRawAsUsableString(widget.amountRaw);
    } else {
      amount = NumberUtil.truncateDecimal(
                  NumberUtil.getRawAsUsableDecimal(widget.amountRaw),
                  digits: 6)
              .toStringAsFixed(6) +
          "~";
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    this.state = StateContainer.of(context);
  }

  void _showSendingAnimation(BuildContext context) {
    animationOpen = true;
    Navigator.of(context).push(AnimationLoadingOverlay(
        AnimationType.SEND,
        state.curTheme.animationOverlayStrong,
        state.curTheme.animationOverlayMedium,
        onPoppedCallback: () => animationOpen = false));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        minimum:
            EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.035),
        child: Column(
          children: <Widget>[
            // Sheet handle
            Container(
              margin: EdgeInsets.only(top: 10),
              height: 5,
              width: MediaQuery.of(context).size.width * 0.15,
              decoration: BoxDecoration(
                color: state.curTheme.text10,
                borderRadius: BorderRadius.circular(100.0),
              ),
            ),
            //The main widget that holds the text fields, "SENDING" and "TO" texts
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // "SENDING" TEXT
                  Container(
                    margin: EdgeInsets.only(bottom: 10.0),
                    child: Column(
                      children: <Widget>[
                        Text(
                          CaseChange.toUpperCase(
                              AppLocalization.of(context).sending, context),
                          style: AppStyles.textStyleHeader(context),
                        ),
                      ],
                    ),
                  ),
                  // Container for the amount text
                  Container(
                    margin: EdgeInsets.only(
                        left: MediaQuery.of(context).size.width * 0.105,
                        right: MediaQuery.of(context).size.width * 0.105),
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          state.curTheme.backgroundDarkest,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    // Amount text
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: '',
                        children: [
                          TextSpan(
                            text: "$amount",
                            style: TextStyle(
                              color:
                                  state.curTheme.primary,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'NunitoSans',
                            ),
                          ),
                          TextSpan(
                            text: " BAN",
                            style: TextStyle(
                              color:
                                  state.curTheme.primary,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w100,
                              fontFamily: 'NunitoSans',
                            ),
                          ),
                          TextSpan(
                            text: widget.localCurrency != null
                                ? " (${widget.localCurrency})"
                                : "",
                            style: TextStyle(
                              color:
                                  state.curTheme.primary,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'NunitoSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // "TO" text
                  Container(
                    margin: EdgeInsets.only(top: 30.0, bottom: 10),
                    child: Column(
                      children: <Widget>[
                        Text(
                          CaseChange.toUpperCase(
                              AppLocalization.of(context).to, context),
                          style: AppStyles.textStyleHeader(context),
                        ),
                      ],
                    ),
                  ),
                  // Address text
                  Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 25.0, vertical: 15.0),
                      margin: EdgeInsets.only(
                          left: MediaQuery.of(context).size.width * 0.105,
                          right: MediaQuery.of(context).size.width * 0.105),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: state
                            .curTheme
                            .backgroundDarkest,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: sl.get<UIUtil>().threeLineAddressText(
                              context, widget.destination,
                              contactName: widget.contactName)),
                ],
              ),
            ),

            //A container for CONFIRM and CANCEL buttons
            Container(
              child: Column(
                children: <Widget>[
                  // A row for CONFIRM Button
                  Row(
                    children: <Widget>[
                      // CONFIRM Button
                      AppButton.buildAppButton(
                          context,
                          AppButtonType.PRIMARY,
                          CaseChange.toUpperCase(
                              AppLocalization.of(context).confirm, context),
                          Dimens.BUTTON_TOP_DIMENS, onPressed: () async {
                        // Authenticate
                        AuthenticationMethod authMethod = await sl.get<SharedPrefsUtil>().getAuthMethod();
                        bool hasBiometrics = await sl.get<BiometricUtil>().hasBiometrics();
                        if (authMethod.method == AuthMethod.BIOMETRICS &&
                            hasBiometrics) {
                              try {
                                bool authenticated = await sl
                                                  .get<BiometricUtil>()
                                                  .authenticateWithBiometrics(
                                                      context,
                                                      AppLocalization.of(context)
                                                          .sendAmountConfirmKal
                                                          .replaceAll("%1", amount));
                                if (authenticated) {
                                  sl.get<HapticUtil>().fingerprintSucess();
                                  _showSendingAnimation(context);
                                  await _doSend();
                                }
                              } catch (e) {
                                await authenticateWithPin();
                              }
                            } else {
                              await authenticateWithPin();
                            }
                          }
                      )
                    ],
                  ),
                  // A row for CANCEL Button
                  Row(
                    children: <Widget>[
                      // CANCEL Button
                      AppButton.buildAppButton(
                          context,
                          AppButtonType.PRIMARY_OUTLINE,
                          CaseChange.toUpperCase(
                              AppLocalization.of(context).cancel, context),
                          Dimens.BUTTON_BOTTOM_DIMENS, onPressed: () {
                        Navigator.of(context).pop();
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  Future<void> _doSend() async {
    try {
      ProcessResponse resp = await sl.get<AccountService>().requestSend(
        state.wallet.representative,
        state.wallet.frontier,
        widget.amountRaw,
        widget.destination,
        state.wallet.address,
        NanoUtil.seedToPrivate(await sl.get<Vault>().getSeed(), state.selectedAccount.index),
        max: widget.maxSend
      );
      state.wallet.frontier = resp.hash;
      state.wallet.accountBalance += BigInt.parse(widget.amountRaw);
      // Show complete
      Contact contact = await sl.get<DBHelper>().getContactWithAddress(widget.destination);
      String contactName = contact == null ? null : contact.name;
      Navigator.of(context).popUntil(RouteUtils.withNameLike('/home'));
      state.requestUpdate();
      Sheets.showAppHeightNineSheet(
          context: context,
          closeOnTap: true,
          removeUntilHome: true,
          widget: SendCompleteSheet(
              amountRaw: widget.amountRaw,
              destination: widget.destination,
              contactName: contactName,
              localAmount: widget.localCurrency));
    } catch (e) {
      // Send failed
      if (animationOpen) {
        Navigator.of(context).pop();
      }
      sl.get<UIUtil>().showSnackbar(AppLocalization.of(context).sendError, context);
      Navigator.of(context).pop();
    }
  }

  Future<void> authenticateWithPin() async {
    // PIN Authentication
    sl.get<Vault>().getPin().then((expectedPin) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) {
        return new PinScreen(
          PinOverlayType.ENTER_PIN,
          (pin) async {
            Navigator.of(context).pop();
            _showSendingAnimation(context);
            await _doSend();
          },
          expectedPin: expectedPin,
          description: AppLocalization.of(context)
              .sendAmountConfirmKalPin
              .replaceAll("%1", amount),
        );
      }));
    });
  }
}
