import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'package:event_taxi/event_taxi.dart';
import 'package:flutter_nano_ffi/flutter_nano_ffi.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/bus/events.dart';
import 'package:kalium_wallet_flutter/network/model/response/account_balance_item.dart';
import 'package:kalium_wallet_flutter/ui/transfer/transfer_manual_entry_sheet.dart';
import 'package:kalium_wallet_flutter/ui/widgets/auto_resize_text.dart';
import 'package:kalium_wallet_flutter/ui/widgets/sheets.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:kalium_wallet_flutter/ui/widgets/dialog.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/util/caseconverter.dart';
import 'package:kalium_wallet_flutter/util/nanoutil.dart';

class AppTransferOverviewSheet {
  static const int NUM_SWEEP = 15; // Number of accounts to sweep from a seed

  NanoUtil _nanoUtil;

  // accounts to private keys/account balances
  Map<String, AccountBalanceItem> privKeyBalanceMap = Map();

  bool _animationOpen = false;

  StreamSubscription<AccountsBalancesEvent> _balancesSub;

  Future<bool> _onWillPop() async {
    if (_balancesSub != null) {
      _balancesSub.cancel();
    }
    return true;
  }

  AppTransferOverviewSheet() {
    _nanoUtil = NanoUtil();
  }

  mainBottomSheet(BuildContext context) {
    // Handle accounts balances response
    _balancesSub = EventTaxiImpl.singleton()
        .registerTo<AccountsBalancesEvent>()
        .listen((event) {
      if (_animationOpen) {
        Navigator.of(context).pop();
      }
      List<String> accountsToRemove = List();
      event.response.balances
          .forEach((String account, AccountBalanceItem balItem) {
        BigInt balance = BigInt.parse(balItem.balance);
        BigInt pending = BigInt.parse(balItem.pending);
        if (balance + pending == BigInt.zero) {
          accountsToRemove.add(account);
        } else {
          // Update balance of this item
          privKeyBalanceMap[account].balance = balItem.balance;
          privKeyBalanceMap[account].pending = balItem.pending;
        }
      });
      accountsToRemove.forEach((String account) {
        privKeyBalanceMap.remove(account);
      });
      if (privKeyBalanceMap.length == 0) {
        sl.get<UIUtil>().showSnackbar(
            AppLocalization.of(context).transferNoFundsKal, context);
        return;
      }
      // Go to confirmation screen
      EventTaxiImpl.singleton()
          .fire(TransferConfirmEvent(balMap: privKeyBalanceMap));
      Navigator.of(context).pop();
    });

    void manualEntryCallback(String seed) {
      Navigator.of(context).pop();
      startTransfer(context, seed, manualEntry: true);
    }

    AppSheets.showAppHeightNineSheet(
        context: context,
        onDisposed: _onWillPop,
        builder: (BuildContext context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return WillPopScope(
              onWillPop: _onWillPop,
              child: SafeArea(
                minimum: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.035,
                ),
                child: Container(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      // A container for the header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Emtpy SizedBox
                          SizedBox(
                            height: 60,
                            width: 60,
                          ),
                          // The header
                          Column(
                            children: <Widget>[
                              // Sheet handle
                              Container(
                                margin: EdgeInsets.only(top: 10),
                                height: 5,
                                width: MediaQuery.of(context).size.width * 0.15,
                                decoration: BoxDecoration(
                                  color: StateContainer.of(context)
                                      .curTheme
                                      .text10,
                                  borderRadius: BorderRadius.circular(100.0),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 15.0),
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width -
                                            140),
                                child: AutoSizeText(
                                  CaseChange.toUpperCase(
                                      AppLocalization.of(context)
                                          .transferHeader,
                                      context),
                                  style: AppStyles.textStyleHeader(context),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  stepGranularity: 0.1,
                                ),
                              ),
                            ],
                          ),
                          // Emtpy SizedBox
                          SizedBox(
                            height: 60,
                            width: 60,
                          ),
                        ],
                      ),

                      // A container for the illustration and paragraphs
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              constraints: BoxConstraints(
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.2,
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.6),
                              child: Stack(
                                children: <Widget>[
                                  Center(
                                    child: SvgPicture.asset(
                                        'assets/transferfunds_illustration_start_paperwalletonly.svg',
                                        color: StateContainer.of(context)
                                            .curTheme
                                            .text45,
                                        width:
                                            MediaQuery.of(context).size.width),
                                  ),
                                  Center(
                                    child: SvgPicture.asset(
                                      'assets/transferfunds_illustration_start_kaliumwalletonly.svg',
                                      color: StateContainer.of(context)
                                          .curTheme
                                          .primary,
                                      width: MediaQuery.of(context).size.width,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              alignment: AlignmentDirectional(-1, 0),
                              margin: EdgeInsets.symmetric(
                                  horizontal: smallScreen(context) ? 35 : 50,
                                  vertical: 20),
                              child: AutoSizeText(
                                AppLocalization.of(context)
                                    .transferIntroKal
                                    .replaceAll("%1",
                                        AppLocalization.of(context).scanQrCode),
                                style: AppStyles.textStyleParagraph(context),
                                textAlign: TextAlign.start,
                                maxLines: 6,
                                stepGranularity: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Row(
                        children: <Widget>[
                          AppButton.buildAppButton(
                            context,
                            AppButtonType.PRIMARY,
                            AppLocalization.of(context).scanQrCode,
                            Dimens.BUTTON_TOP_DIMENS,
                            onPressed: () {
                              sl.get<UIUtil>().cancelLockEvent();
                              BarcodeScanner.scan(StateContainer.of(context)
                                      .curTheme
                                      .qrScanTheme)
                                  .then((value) {
                                if (!NanoSeeds.isValidSeed(value)) {
                                  sl.get<UIUtil>().showSnackbar(
                                      AppLocalization.of(context).qrInvalidSeed,
                                      context);
                                  return;
                                }
                                startTransfer(context, value);
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          AppButton.buildAppButton(
                            context,
                            AppButtonType.PRIMARY_OUTLINE,
                            AppLocalization.of(context).manualEntry,
                            Dimens.BUTTON_BOTTOM_DIMENS,
                            onPressed: () {
                              AppTransferManualEntrySheet(manualEntryCallback)
                                  .mainBottomSheet(context);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  void startTransfer(BuildContext context, String seed,
      {bool manualEntry = false}) {
    // Show loading overlay
    _animationOpen = true;
    AnimationType animation = manualEntry
        ? AnimationType.TRANSFER_SEARCHING_MANUAL
        : AnimationType.TRANSFER_SEARCHING_QR;
    Navigator.of(context).push(AnimationLoadingOverlay(
        animation,
        StateContainer.of(context).curTheme.animationOverlayStrong,
        StateContainer.of(context).curTheme.animationOverlayMedium,
        onPoppedCallback: () {
      _animationOpen = false;
    }));
    // Get accounts from seed
    getAccountsFromSeed(context, seed).then((accountsToRequest) {
      // Make balances request
      StateContainer.of(context)
          .requestAccountsBalances(accountsToRequest, fromTransfer: true);
    });
  }

  /// Get NUM_SWEEP accounts from seed to request balances for
Future<List<String>> getAccountsFromSeed(BuildContext context, String seed) async {
    List<String> accountsToRequest = List();
    String privKey;
    String address;
    // Get NUM_SWEEP private keys + accounts from seed
    for (int i = 0; i < NUM_SWEEP; i++) {
      privKey = NanoUtil.seedToPrivate(seed, i);
      address = NanoUtil.seedToAddress(seed, i);
      // Don't add this if it is the currently logged in account
      if (address != StateContainer.of(context).wallet.address) {
        privKeyBalanceMap.putIfAbsent(
            address, () => AccountBalanceItem(privKey: privKey));
        accountsToRequest.add(address);
      }
    }
    // Also treat this seed as a private key
    address = NanoAccounts.createAccount(
        NanoAccountType.BANANO, NanoKeys.createPublicKey(seed));
    if (address != StateContainer.of(context).wallet.address) {
      privKeyBalanceMap.putIfAbsent(
          address, () => AccountBalanceItem(privKey: seed));
      accountsToRequest.add(address);
    }
    return accountsToRequest;
  }
}
