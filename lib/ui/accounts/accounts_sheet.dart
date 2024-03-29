import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:event_taxi/event_taxi.dart';
import 'package:kalium_wallet_flutter/bus/events.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/network/account_service.dart';
import 'package:kalium_wallet_flutter/network/model/response/accounts_balances_response.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/model/db/appdb.dart';
import 'package:kalium_wallet_flutter/model/db/account.dart';
import 'package:kalium_wallet_flutter/ui/accounts/accountdetails_sheet.dart';
import 'package:kalium_wallet_flutter/ui/accounts/import_external_account_sheet.dart';
import 'package:kalium_wallet_flutter/ui/widgets/app_simpledialog.dart';
import 'package:kalium_wallet_flutter/ui/widgets/auto_resize_text.dart';
import 'package:kalium_wallet_flutter/ui/widgets/flat_button.dart';
import 'package:kalium_wallet_flutter/ui/widgets/sheet_util.dart';
import 'package:kalium_wallet_flutter/ui/widgets/sheets.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:kalium_wallet_flutter/ui/widgets/dialog.dart';
import 'package:kalium_wallet_flutter/ui/widgets/monkey.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/util/caseconverter.dart';
import 'package:kalium_wallet_flutter/util/numberutil.dart';
import 'package:logger/logger.dart';
import 'package:kalium_wallet_flutter/app_icons.dart';

class AppAccountsSheet {
  List<Account> accounts;

  AppAccountsSheet(this.accounts);

  mainBottomSheet(BuildContext context) {
    AppSheets.showAppHeightNineSheet(
        context: context,
        builder: (BuildContext context) {
          return AppAccountsWidget(accounts: accounts);
        });
  }
}

class AppAccountsWidget extends StatefulWidget {
  final List<Account> accounts;

  AppAccountsWidget({Key key, @required this.accounts}) : super(key: key);

  @override
  _AppAccountsWidgetState createState() => _AppAccountsWidgetState();
}

class _AppAccountsWidgetState extends State<AppAccountsWidget> {
  static const int MAX_ACCOUNTS = 250;
  final GlobalKey expandedKey = GlobalKey();

  bool _addingAccount;
  ScrollController _scrollController = new ScrollController();

  StreamSubscription<AccountModifiedEvent> _accountModifiedSub;
  bool _accountIsChanging;

  @override
  void initState() {
    super.initState();
    _registerBus();
    this._addingAccount = false;
    this._accountIsChanging = false;
  }

  @override
  void dispose() {
    _destroyBus();
    super.dispose();
  }

  void _registerBus() {
    _accountModifiedSub = EventTaxiImpl.singleton()
        .registerTo<AccountModifiedEvent>()
        .listen((event) {
      if (event.deleted) {
        if (event.account.selected) {
          Future.delayed(Duration(milliseconds: 50), () {
            setState(() {
              widget.accounts
                  .where((a) =>
                      a.id == StateContainer.of(context).selectedAccount.id)
                  .forEach((account) {
                account.selected = true;
              });
            });
          });
        }
        setState(() {
          widget.accounts.removeWhere((a) => a.id == event.account.id);
        });
      } else {
        // Name change
        setState(() {
          widget.accounts.removeWhere((a) => a.id == event.account.id);
          widget.accounts.add(event.account);
          widget.accounts.sort((a, b) {
            // Sort by acct_index first, then by id for adhoc accounts
            if ((a.index >= 0 && b.index >= 0) ||
                (a.index < 0 && b.index < 0)) {
              int indexCompare = a.index.compareTo(b.index);
              if (indexCompare != 0) return indexCompare;
              // Sort by ID
              return a.id.compareTo(b.id);
            } else if (a.index < 0 && b.index >= 0) {
              // a should come after b
              return 1;
            } else {
              // a should come before b
              return -1;
            }
          });
        });
      }
    });
  }

  void _destroyBus() {
    if (_accountModifiedSub != null) {
      _accountModifiedSub.cancel();
    }
  }

  void _externalAccountAdded(Account newAccount) {
    _requestBalances(context, [newAccount]);
    StateContainer.of(context).updateRecentlyUsedAccounts();
    widget.accounts.add(newAccount);
    setState(() {
      _addingAccount = false;
      widget.accounts.sort((a, b) {
        // Sort by acct_index first, then by id for adhoc accounts
        if ((a.index >= 0 && b.index >= 0) || (a.index < 0 && b.index < 0)) {
          int indexCompare = a.index.compareTo(b.index);
          if (indexCompare != 0) return indexCompare;
          // Sort by ID
          return a.id.compareTo(b.id);
        } else if (a.index < 0 && b.index >= 0) {
          // a should come after b
          return 1;
        } else {
          // a should come before b
          return -1;
        }
      });
      // Scroll if list is full
      if (expandedKey.currentContext != null) {
        RenderBox box = expandedKey.currentContext.findRenderObject();
        if (widget.accounts.length * (smallScreen(context) ? 72.0 : 87.0) >=
            box.size.height) {
          _scrollController.animateTo(
            widget.accounts.indexWhere((a) => a.id == newAccount.id) *
                        (smallScreen(context) ? 72.0 : 87.0) >
                    _scrollController.position.maxScrollExtent
                ? _scrollController.position.maxScrollExtent +
                    (smallScreen(context) ? 72.0 : 87.0)
                : widget.accounts.indexWhere((a) => a.id == newAccount.id) *
                    (smallScreen(context) ? 72.0 : 87.0),
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 200),
          );
        }
      }
    });
    sl.get<UIUtil>().showSnackbar(
        AppLocalization.of(context).adHocAccountImportedSuccess, context);
  }

  Future<void> _requestBalances(
      BuildContext context, List<Account> accounts) async {
    List<String> addresses = List();
    accounts.forEach((account) {
      if (account.address != null) {
        addresses.add(account.address);
      }
    });
    try {
      AccountsBalancesResponse resp =
          await sl.get<AccountService>().requestAccountsBalances(addresses);
      await _handleAccountsBalancesResponse(resp);
    } catch (e) {
      sl.get<Logger>().e("Error", error: e);
    }
  }

  Future<void> _handleAccountsBalancesResponse(
      AccountsBalancesResponse resp) async {
    // Handle balances event
    widget.accounts.forEach((account) {
      resp.balances.forEach((address, balance) {
        String combinedBalance = (BigInt.tryParse(balance.balance) +
                BigInt.tryParse(balance.pending))
            .toString();
        if (account.address == address && combinedBalance != account.balance) {
          sl.get<DBHelper>().updateAccountBalance(account, combinedBalance);
          setState(() {
            account.balance = combinedBalance;
          });
        }
      });
    });
  }

  Future<void> _changeAccount(Account account, StateSetter setState) async {
    // Change account
    widget.accounts.forEach((a) {
      if (a.selected) {
        setState(() {
          a.selected = false;
        });
      } else if (account.id == a.id) {
        setState(() {
          a.selected = true;
        });
      }
    });
    await sl.get<DBHelper>().changeAccount(account);
    EventTaxiImpl.singleton()
        .fire(AccountChangedEvent(account: account, delayPop: true));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        minimum: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.035,
        ),
        child: Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              //A container for the header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: 60, width: 60),
                  //A column for the header
                  Container(
                    margin: EdgeInsets.only(top: 30.0, bottom: 15),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 140),
                    child: AutoSizeText(
                      CaseChange.toUpperCase(
                          AppLocalization.of(context).accounts, context),
                      style: AppStyles.textStyleHeader(context),
                      maxLines: 1,
                      stepGranularity: 0.1,
                    ),
                  ),
                  // Three dot button
                  Container(
                    width: 50,
                    height: 50,
                    margin: EdgeInsetsDirectional.only(top: 10.0, end: 10.0),
                    child: FlatButton(
                      highlightColor:
                          StateContainer.of(context).curTheme.text15,
                      splashColor: StateContainer.of(context).curTheme.text15,
                      onPressed: () {
                        showDialog(
                          barrierColor:
                              StateContainer.of(context).curTheme.barrier,
                          context: context,
                          builder: _buildMoreOptionsDialog,
                        );
                      },
                      child: Icon(Icons.more_horiz_rounded,
                          size: 28,
                          color: StateContainer.of(context).curTheme.text),
                      padding: EdgeInsets.all(11.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100.0)),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                    ),
                  ),
                ],
              ),

              //A list containing accounts
              Expanded(
                  key: expandedKey,
                  child: Stack(
                    children: <Widget>[
                      widget.accounts == null
                          ? Center(
                              child: Text("Loading"),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              itemCount: widget.accounts.length,
                              controller: _scrollController,
                              itemBuilder: (BuildContext context, int index) {
                                return _buildAccountListItem(
                                    context, widget.accounts[index], setState);
                              },
                            ),
                      //List Top Gradient
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          height: 20.0,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                StateContainer.of(context)
                                    .curTheme
                                    .backgroundDark00,
                                StateContainer.of(context)
                                    .curTheme
                                    .backgroundDark,
                              ],
                              begin: AlignmentDirectional(0.5, 1.0),
                              end: AlignmentDirectional(0.5, -1.0),
                            ),
                          ),
                        ),
                      ),
                      // List Bottom Gradient
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 20.0,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                StateContainer.of(context)
                                    .curTheme
                                    .backgroundDark,
                                StateContainer.of(context)
                                    .curTheme
                                    .backgroundDark00
                              ],
                              begin: AlignmentDirectional(0.5, 1.0),
                              end: AlignmentDirectional(0.5, -1.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
              SizedBox(
                height: 15,
              ),
              //A row with Add Account button
              Row(
                children: <Widget>[
                  widget.accounts == null ||
                          widget.accounts.length >= MAX_ACCOUNTS
                      ? SizedBox()
                      : AppButton.buildAppButton(
                          context,
                          AppButtonType.PRIMARY,
                          AppLocalization.of(context).addAccount,
                          Dimens.BUTTON_TOP_DIMENS,
                          disabled: _addingAccount,
                          onPressed: () {
                            if (!_addingAccount) {
                              setState(() {
                                _addingAccount = true;
                              });
                              sl
                                  .get<DBHelper>()
                                  .addAccount(
                                      nameBuilder: AppLocalization.of(context)
                                          .defaultNewAccountName)
                                  .then((newAccount) {
                                _requestBalances(context, [newAccount]);
                                StateContainer.of(context)
                                    .updateRecentlyUsedAccounts();
                                widget.accounts.add(newAccount);
                                setState(() {
                                  _addingAccount = false;
                                  widget.accounts.sort((a, b) {
                                    // Sort by acct_index first, then by id for adhoc accounts
                                    if ((a.index >= 0 && b.index >= 0) ||
                                        (a.index < 0 && b.index < 0)) {
                                      int indexCompare =
                                          a.index.compareTo(b.index);
                                      if (indexCompare != 0)
                                        return indexCompare;
                                      // Sort by ID
                                      return a.id.compareTo(b.id);
                                    } else if (a.index < 0 && b.index >= 0) {
                                      // a should come after b
                                      return 1;
                                    } else {
                                      // a should come before b
                                      return -1;
                                    }
                                  });
                                  // Scroll if list is full
                                  if (expandedKey.currentContext != null) {
                                    RenderBox box = expandedKey.currentContext
                                        .findRenderObject();
                                    if (widget.accounts.length *
                                            (smallScreen(context)
                                                ? 72.0
                                                : 87.0) >=
                                        box.size.height) {
                                      _scrollController.animateTo(
                                        widget.accounts.indexWhere((a) =>
                                                        a.id == newAccount.id) *
                                                    (smallScreen(context)
                                                        ? 72.0
                                                        : 87.0) >
                                                _scrollController
                                                    .position.maxScrollExtent
                                            ? _scrollController
                                                    .position.maxScrollExtent +
                                                (smallScreen(context)
                                                    ? 72.0
                                                    : 87.0)
                                            : widget.accounts.indexWhere((a) =>
                                                    a.id == newAccount.id) *
                                                (smallScreen(context)
                                                    ? 72.0
                                                    : 87.0),
                                        curve: Curves.easeOut,
                                        duration:
                                            const Duration(milliseconds: 200),
                                      );
                                    }
                                  }
                                });
                              });
                            }
                          },
                        ),
                ],
              ),
              //A row with Close button
              Row(
                children: <Widget>[
                  AppButton.buildAppButton(
                    context,
                    AppButtonType.PRIMARY_OUTLINE,
                    AppLocalization.of(context).close,
                    Dimens.BUTTON_BOTTOM_DIMENS,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildMoreOptionsDialog(BuildContext context) {
    var importExternalAccountSheet = new ImportExternalAccountSheet(
        accountAddedCallback: _externalAccountAdded);
    {
      return AppSimpleDialog(
          title: Container(
            margin: EdgeInsets.only(bottom: 10),
            child: Text(
              AppLocalization.of(context).accountsMoreOptionsMenuTitle,
              style: AppStyles.textStyleDialogHeader(context),
            ),
          ),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                Sheets.showAppHeightNineSheet(
                  context: context,
                  widget: importExternalAccountSheet,
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  AppLocalization.of(context)
                      .accountsMoreOptionsMenuImportAccountOption,
                  style: AppStyles.textStyleDialogOptions(context),
                ),
              ),
            )
          ]);
    }
  }

  Widget _buildAccountListItem(
      BuildContext context, Account account, StateSetter setState) {
    var isImportedAccount = account.index == -1;

    var innerContainerWidth = MediaQuery.of(context).size.width - 112;

    return Slidable(
      secondaryActions: _getSlideActionsForAccount(context, account, setState),
      actionExtentRatio: 0.24,
      actionPane: SlidableStrechActionPane(),
      child: FlatButton(
          highlightColor: StateContainer.of(context).curTheme.text15,
          splashColor: StateContainer.of(context).curTheme.text15,
          onPressed: () {
            if (!_accountIsChanging) {
              // Change account
              if (!account.selected) {
                setState(() {
                  _accountIsChanging = true;
                });
                _changeAccount(account, setState);
              }
            }
          },
          padding: EdgeInsets.all(0.0),
          child: Column(
            children: <Widget>[
              Divider(
                height: 2,
                color: StateContainer.of(context).curTheme.text15,
              ),
              Container(
                padding: EdgeInsetsDirectional.only(
                    start: 4, end: 20, top: 4, bottom: 4),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                        width: 5,
                        color: account.selected
                            ? StateContainer.of(context).curTheme.primary
                            : Colors.transparent),
                    right: BorderSide(
                      width: 5,
                      color: Colors.transparent,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        // Account Icon
                        MonkeyWidget(
                            size: smallScreen(context) ? 55 : 70,
                            address: account.address),
                        // Account name and address
                        Container(
                          padding: EdgeInsetsDirectional.only(
                              top: 8, bottom: 8, end: 8),
                          width: innerContainerWidth * 0.6,
                          margin: EdgeInsetsDirectional.only(
                              start: smallScreen(context) ? 10 : 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Account name
                              AutoSizeText(
                                account.name,
                                style: TextStyle(
                                  fontFamily: "NunitoSans",
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.0,
                                  color:
                                      StateContainer.of(context).curTheme.text,
                                ),
                                minFontSize: 8.0,
                                stepGranularity: 0.1,
                                maxLines: null,
                                textAlign: TextAlign.start,
                              ),
                              // Account address
                              AutoSizeText(
                                account.address.substring(0, 11) + "...",
                                style: TextStyle(
                                  fontFamily: "OverpassMono",
                                  fontWeight: FontWeight.w100,
                                  fontSize: 14.0,
                                  color: StateContainer.of(context)
                                      .curTheme
                                      .text60,
                                ),
                                minFontSize: 8.0,
                                stepGranularity: 0.1,
                                maxLines: 1,
                              ),
                              // Imported Account Badge
                              isImportedAccount
                                  ? Container(
                                      padding: EdgeInsetsDirectional.only(
                                        start: 6,
                                        end: 6,
                                        top: 0.5,
                                        bottom: 1.5,
                                      ),
                                      margin:
                                          EdgeInsets.only(top: 6, bottom: 3),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(5),
                                        ),
                                        color: StateContainer.of(context)
                                            .curTheme
                                            .primary10,
                                      ),
                                      child: AutoSizeText(
                                        AppLocalization.of(context)
                                            .importedAdHocAccountBadge,
                                        minFontSize: 8.0,
                                        stepGranularity: 0.1,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontFamily: "NunitoSans",
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14.0,
                                          color: StateContainer.of(context)
                                              .curTheme
                                              .primary,
                                        ),
                                      ),
                                    )
                                  : SizedBox()
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: innerContainerWidth * 0.4,
                      alignment: AlignmentDirectional(1, 0),
                      child: AutoSizeText.rich(
                        TextSpan(
                          children: [
                            // Currency Icon
                            TextSpan(
                              text: account.balance != null ? "" : "",
                              style: TextStyle(
                                fontFamily: 'AppIcons',
                                fontWeight: FontWeight.w400,
                                color: StateContainer.of(context).curTheme.text,
                                fontSize: 13.0,
                              ),
                            ),
                            // Main balance text
                            TextSpan(
                              text: account.balance != null && !account.selected
                                  ? NumberUtil.getRawAsUsableString(
                                      account.balance)
                                  : account.selected
                                      ? StateContainer.of(context)
                                          .wallet
                                          .getAccountBalanceDisplay()
                                      : "",
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: "NunitoSans",
                                  fontWeight: FontWeight.w900,
                                  color:
                                      StateContainer.of(context).curTheme.text),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        style: TextStyle(fontSize: 16.0),
                        stepGranularity: 0.1,
                        minFontSize: 1,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }

  List<Widget> _getSlideActionsForAccount(
      BuildContext context, Account account, StateSetter setState) {
    var isImportedAccount = account.index == -1;
    List<Widget> _actions = List();
    _actions.add(SlideAction(
        child: Container(
          margin: EdgeInsetsDirectional.only(start: 2, top: 1, bottom: 1),
          constraints: BoxConstraints.expand(),
          decoration: BoxDecoration(
            color: StateContainer.of(context).curTheme.primary,
          ),
          child: Icon(
            Icons.edit,
            color: StateContainer.of(context).curTheme.backgroundDark,
          ),
        ),
        onTap: () {
          AccountDetailsSheet(account).mainBottomSheet(context);
        }));
    if (account.index > 0 || isImportedAccount) {
      _actions.add(SlideAction(
          child: Container(
            margin: EdgeInsetsDirectional.only(start: 2, top: 1, bottom: 1),
            constraints: BoxConstraints.expand(),
            decoration: BoxDecoration(
              color: StateContainer.of(context).curTheme.primary,
            ),
            child: Icon(
              Icons.delete,
              color: StateContainer.of(context).curTheme.backgroundDark,
            ),
          ),
          onTap: () {
            AppDialogs.showConfirmDialog(
                context,
                isImportedAccount
                    ? CaseChange.toUpperCase(
                        AppLocalization.of(context).warning, context)
                    : AppLocalization.of(context).hideAccountHeader,
                isImportedAccount
                    ? AppLocalization.of(context)
                        .deleteImportedAdHocAccountDialogParagraph
                    : AppLocalization.of(context).removeAccountText.replaceAll(
                        "%1", AppLocalization.of(context).addAccount),
                isImportedAccount
                    ? CaseChange.toUpperCase(
                        AppLocalization.of(context).delete, context)
                    : CaseChange.toUpperCase(
                        AppLocalization.of(context).yes, context), () {
              // Remove account
              sl.get<DBHelper>().deleteAccount(account).then((id) {
                EventTaxiImpl.singleton().fire(
                    AccountModifiedEvent(account: account, deleted: true));
                setState(() {
                  widget.accounts.removeWhere((a) => a.id == account.id);
                });
              });
            },
                cancelText: isImportedAccount
                    ? CaseChange.toUpperCase(
                        AppLocalization.of(context).cancel, context)
                    : CaseChange.toUpperCase(
                        AppLocalization.of(context).no, context));
          }));
    }
    return _actions;
  }
}
