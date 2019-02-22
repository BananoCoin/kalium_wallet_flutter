import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:kalium_wallet_flutter/model/wallet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'package:event_taxi/event_taxi.dart';
import 'package:kalium_wallet_flutter/themes.dart';
import 'package:kalium_wallet_flutter/model/available_themes.dart';
import 'package:kalium_wallet_flutter/model/available_currency.dart';
import 'package:kalium_wallet_flutter/model/available_language.dart';
import 'package:kalium_wallet_flutter/model/address.dart';
import 'package:kalium_wallet_flutter/model/state_block.dart';
import 'package:kalium_wallet_flutter/model/vault.dart';
import 'package:kalium_wallet_flutter/network/model/block_types.dart';
import 'package:kalium_wallet_flutter/network/model/request_item.dart';
import 'package:kalium_wallet_flutter/network/model/request/accounts_balances_request.dart';
import 'package:kalium_wallet_flutter/network/model/request/account_history_request.dart';
import 'package:kalium_wallet_flutter/network/model/request/fcm_update_request.dart';
import 'package:kalium_wallet_flutter/network/model/request/subscribe_request.dart';
import 'package:kalium_wallet_flutter/network/model/request/blocks_info_request.dart';
import 'package:kalium_wallet_flutter/network/model/request/pending_request.dart';
import 'package:kalium_wallet_flutter/network/model/request/process_request.dart';
import 'package:kalium_wallet_flutter/network/model/response/account_history_response.dart';
import 'package:kalium_wallet_flutter/network/model/response/account_history_response_item.dart';
import 'package:kalium_wallet_flutter/network/model/response/callback_response.dart';
import 'package:kalium_wallet_flutter/network/model/response/error_response.dart';
import 'package:kalium_wallet_flutter/network/model/response/blocks_info_response.dart';
import 'package:kalium_wallet_flutter/network/model/response/subscribe_response.dart';
import 'package:kalium_wallet_flutter/network/model/response/process_response.dart';
import 'package:kalium_wallet_flutter/network/model/response/pending_response.dart';
import 'package:kalium_wallet_flutter/network/model/response/pending_response_item.dart';
import 'package:kalium_wallet_flutter/util/sharedprefsutil.dart';
import 'package:kalium_wallet_flutter/util/nanoutil.dart';
import 'package:kalium_wallet_flutter/network/account_service.dart';
import 'package:kalium_wallet_flutter/bus/events.dart';

class _InheritedStateContainer extends InheritedWidget {
  // Data is your entire state. In our case just 'User'
  final StateContainerState data;

  // You must pass through a child and your state.
  _InheritedStateContainer({
    Key key,
    @required this.data,
    @required Widget child,
  }) : super(key: key, child: child);

  // This is a built in method which you can use to check if
  // any state has changed. If not, no reason to rebuild all the widgets
  // that rely on your state.
  @override
  bool updateShouldNotify(_InheritedStateContainer old) => true;
}

class StateContainer extends StatefulWidget {
  // You must pass through a child.
  final Widget child;

  StateContainer({@required this.child});

  // This is the secret sauce. Write your own 'of' method that will behave
  // Exactly like MediaQuery.of and Theme.of
  // It basically says 'get the data from the widget of this type.
  static StateContainerState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_InheritedStateContainer)
            as _InheritedStateContainer)
        .data;
  }

  @override
  StateContainerState createState() => StateContainerState();
}

/// App InheritedWidget
/// This is where we handle the global state and also where
/// we interact with the server and make requests/handle+propagate responses
///
/// Basically the central hub behind the entire app
class StateContainerState extends State<StateContainer> {
  final Logger log = Logger("StateContainerState");
  // Minimum receive = 0.01 BANANO
  String receiveMinimum = BigInt.from(10).pow(27).toString();

  AppWallet wallet;
  String currencyLocale;
  Locale deviceLocale = Locale('en', 'US');
  AvailableCurrency curCurrency = AvailableCurrency(AvailableCurrencyEnum.USD);
  LanguageSetting curLanguage = LanguageSetting(AvailableLanguage.DEFAULT);
  BaseTheme curTheme = KaliumTheme();

  // If callback is locked
  bool _locked = false;

  // This map stashes pending process requests, this is because we need to update these requests
  // after a blocks_info with the balance after send, and sign the block
  Map<String, StateBlock> previousPendingMap = Map();

  // Maps previous block requested to next block
  Map<String, StateBlock> pendingResponseBlockMap = Map();

  // Maps all pending receives to previous blocks
  Map<String, StateBlock> pendingBlockMap = Map();

  @override
  void initState() {
    super.initState();
    // Register RxBus
    _registerBus();
    // Set currency locale here for the UI to access
    SharedPrefsUtil.inst.getCurrency(deviceLocale).then((currency) {
      setState(() {
        currencyLocale = currency.getLocale().toString();
        curCurrency = currency;
      });
    });
    // Get default language setting
    SharedPrefsUtil.inst.getLanguage().then((language) {
      setState(() {
        curLanguage = language;
      });
    });
    // Get theme default
    SharedPrefsUtil.inst.getTheme().then((theme) {
      updateTheme(theme, setIcon: false);
    });
  }

  // Subscriptions
  StreamSubscription<ConnStatusEvent> _connStatusSub;
  StreamSubscription<SubscribeEvent> _subscribeEventSub;
  StreamSubscription<HistoryEvent> _historyEventSub;
  StreamSubscription<PriceEvent> _priceEventSub;
  StreamSubscription<BlocksInfoEvent> _blocksInfoEventSub;
  StreamSubscription<PendingEvent> _pendingSub;
  StreamSubscription<ProcessEvent> _processSub;
  StreamSubscription<CallbackEvent> _callbackSub;
  StreamSubscription<ErrorEvent> _errorSub;
  StreamSubscription<FcmUpdateEvent> _fcmUpdateSub;

  // Register RX event listenerss
  void _registerBus() {
    _subscribeEventSub =
        EventTaxiImpl.singleton().registerTo<SubscribeEvent>().listen((event) {
      handleSubscribeResponse(event.response);
    });
    _historyEventSub =
        EventTaxiImpl.singleton().registerTo<HistoryEvent>().listen((event) {
      AccountHistoryResponse historyResponse = event.response;
      // Special handling if from transfer
      RequestItem topItem = AccountService.peek();
      if (topItem != null && topItem.fromTransfer) {
        AccountHistoryRequest origRequest = AccountService.pop().request;
        historyResponse.account = origRequest.account;
        EventTaxiImpl.singleton()
            .fire(TransferAccountHistoryEvent(response: historyResponse));
        return;
      }

      bool postedToHome = false;
      // Iterate list in reverse (oldest to newest block)
      for (AccountHistoryResponseItem item in historyResponse.history) {
        // If current list doesn't contain this item, insert it and the rest of the items in list and exit loop
        if (!wallet.history.contains(item)) {
          int startIndex = 0; // Index to start inserting into the list
          int lastIndex = historyResponse.history.indexWhere((item) =>
              wallet.history.contains(
                  item)); // Last index of historyResponse to insert to (first index where item exists in wallet history)
          lastIndex =
              lastIndex <= 0 ? historyResponse.history.length : lastIndex;
          setState(() {
            wallet.history.insertAll(
                0, historyResponse.history.getRange(startIndex, lastIndex));
            // Send list to home screen
            EventTaxiImpl.singleton()
                .fire(HistoryHomeEvent(items: wallet.history));
          });
          postedToHome = true;
          break;
        }
      }
      setState(() {
        wallet.historyLoading = false;
      });
      if (!postedToHome) {
        EventTaxiImpl.singleton().fire(HistoryHomeEvent(items: wallet.history));
      }
      AccountService.pop();
      AccountService.processQueue();
      requestPending();
    });
    _priceEventSub =
        EventTaxiImpl.singleton().registerTo<PriceEvent>().listen((event) {
      // PriceResponse's get pushed periodically, it wasn't a request we made so don't pop the queue
      setState(() {
        wallet.nanoPrice = event.response.nanoPrice.toString();
        wallet.btcPrice = event.response.btcPrice.toString();
        wallet.localCurrencyPrice = event.response.price.toString();
      });
    });
    _blocksInfoEventSub =
        EventTaxiImpl.singleton().registerTo<BlocksInfoEvent>().listen((event) {
      handleBlocksInfoResponse(event.response);
    });
    _connStatusSub =
        EventTaxiImpl.singleton().registerTo<ConnStatusEvent>().listen((event) {
      if (event.status == ConnectionStatus.CONNECTED) {
        requestUpdate();
      } else {
        AccountService.initCommunication();
      }
    });
    _callbackSub =
        EventTaxiImpl.singleton().registerTo<CallbackEvent>().listen((event) {
      handleCallbackResponse(event.response);
    });
    _processSub =
        EventTaxiImpl.singleton().registerTo<ProcessEvent>().listen((event) {
      handleProcessResponse(event.response);
    });
    _pendingSub =
        EventTaxiImpl.singleton().registerTo<PendingEvent>().listen((event) {
      handlePendingResponse(event.response);
    });
    _errorSub =
        EventTaxiImpl.singleton().registerTo<ErrorEvent>().listen((event) {
      handleErrorResponse(event.response);
    });
    _fcmUpdateSub =
        EventTaxiImpl.singleton().registerTo<FcmUpdateEvent>().listen((event) {
      SharedPrefsUtil.inst.getNotificationsOn().then((enabled) {
        AccountService.sendRequest(FcmUpdateRequest(
            account: wallet.address, fcmToken: event.token, enabled: enabled));
      });
    });
  }

  @override
  void dispose() {
    _destroyBus();
    super.dispose();
  }

  void _destroyBus() {
    if (_connStatusSub != null) {
      _connStatusSub.cancel();
    }
    if (_subscribeEventSub != null) {
      _subscribeEventSub.cancel();
    }
    if (_historyEventSub != null) {
      _historyEventSub.cancel();
    }
    if (_priceEventSub != null) {
      _priceEventSub.cancel();
    }
    if (_blocksInfoEventSub != null) {
      _blocksInfoEventSub.cancel();
    }
    if (_pendingSub != null) {
      _pendingSub.cancel();
    }
    if (_processSub != null) {
      _processSub.cancel();
    }
    if (_callbackSub != null) {
      _callbackSub.cancel();
    }
    if (_errorSub != null) {
      _errorSub.cancel();
    }
    if (_fcmUpdateSub != null) {
      _fcmUpdateSub.cancel();
    }
  }

  // Update the global wallet instance with a new address
  void updateWallet({address}) {
    setState(() {
      wallet = AppWallet(address: address, loading: true);
      requestUpdate();
    });
  }

  // Change language
  void updateLanguage(LanguageSetting language) {
    setState(() {
      curLanguage = language;
      deviceLocale = deviceLocale;
    });
  }

  // Change theme
  void updateTheme(ThemeSetting theme, {bool setIcon = true}) {
    setState(() {
      curTheme = theme.getTheme();
    });
    if (setIcon) {
      AppIcon.setAppIcon(theme.getTheme().appIcon);
    }
  }

  void updateDeviceLocale(Locale locale) {
    setState(() {
      deviceLocale = locale;
    });
  }

  void disconnect() {
    AccountService.reset(suspend: true);
  }

  void reconnect() {
    AccountService.initCommunication(unsuspend: true);
  }

  void lockCallback() {
    _locked = true;
  }

  void unlockCallback() {
    _locked = false;
  }

  ///
  /// When an error is returned from server
  ///
  void handleErrorResponse(ErrorResponse errorResponse) {
    RequestItem prevRequest = AccountService.pop();
    AccountService.processQueue();
    if (errorResponse.error == null) {
      return;
    }
    // 1) Unreceivable error, due to already having received the block typically
    // This is a no-op for now

    // 2) Process/work errors
    if (errorResponse.error.toLowerCase().contains("process") ||
        errorResponse.error.toLowerCase().contains("work")) {
      if (prevRequest != null && prevRequest.request is ProcessRequest) {
        ProcessRequest origRequest = prevRequest.request;
        if (origRequest.subType == BlockTypes.SEND) {
          // Send send failed event
          EventTaxiImpl.singleton()
              .fire(SendFailedEvent(response: errorResponse));
        }
        pendingBlockMap.clear();
        pendingResponseBlockMap.clear();
        previousPendingMap.clear();
        requestUpdate();
      }
    }
    // 3) Error from transfer request
    if (prevRequest != null && prevRequest.fromTransfer) {
      EventTaxiImpl.singleton()
          .fire(TransferErrorEvent(response: errorResponse));
    }
  }

  ///
  /// When a STATE block comes back successfully with a hash
  ///
  /// @param processResponse Process Response
  ///
  void handleProcessResponse(ProcessResponse processResponse) {
    // see what type of request sent this response
    bool doUpdate = true;
    RequestItem lastRequest = AccountService.pop();
    // We always store the block we send for processing in a Map, get the entire block using hash
    StateBlock previous = pendingResponseBlockMap.remove(processResponse.hash);
    // Standard process response handling (not from seed sweep/transfer)
    if (previous != null && !lastRequest.fromTransfer) {
      // Update the frontier on process responses to avoid forks
      // We use wallet.blockCount in history requests, to attempt to only request TXs we don't have, so update that too
      if (previous.subType == BlockTypes.OPEN) {
        setState(() {
          wallet.frontier = processResponse.hash;
          wallet.blockCount = 1;
        });
      } else {
        setState(() {
          wallet.frontier = processResponse.hash;
          wallet.blockCount = wallet.blockCount + 1;
        });
        if (previous.subType == BlockTypes.SEND) {
          // post send event to let UI know send was successful
          EventTaxiImpl.singleton().fire(SendCompleteEvent(previous: previous));
        } else if (previous.subType == BlockTypes.RECEIVE) {
          // Routine to handle multiple pending receives
          // Handle next receive if there is one, we store these in a Map also
          StateBlock frontier = pendingBlockMap.remove(processResponse.hash);
          if (frontier != null && pendingBlockMap.length > 0) {
            StateBlock nextBlock =
                pendingBlockMap.remove(pendingBlockMap.keys.first);
            nextBlock.previous = frontier.hash;
            nextBlock.representative = frontier.representative;
            nextBlock.setBalance(frontier.balance);
            doUpdate = false;
            _getPrivKey().then((result) {
              nextBlock.sign(result);
              pendingBlockMap.putIfAbsent(nextBlock.hash, () => nextBlock);
              pendingResponseBlockMap.putIfAbsent(
                  nextBlock.hash, () => nextBlock);
              AccountService.queueRequest(ProcessRequest(
                  block: json.encode(nextBlock.toJson()),
                  subType: nextBlock.subType));
              AccountService.processQueue();
            });
          }
        } else if (previous.subType == BlockTypes.CHANGE) {
          // Tell UI change rep was successful
          EventTaxiImpl.singleton().fire(RepChangedEvent(previous: previous));
        }
      }
    } else {
      // From seed sweep, UI gets a different response
      doUpdate = false;
      EventTaxiImpl.singleton().fire(TransferProcessEvent(
          account: previous.account,
          hash: processResponse.hash,
          balance: previous.balance));
    }
    if (doUpdate) {
      requestUpdate();
    } else {
      AccountService.processQueue();
    }
  }

  // Handle pending response
  void handlePendingResponse(PendingResponse response) {
    RequestItem prevRequest = AccountService.pop();
    if (prevRequest != null && prevRequest.fromTransfer) {
      // Transfer/sweep pending requests get different handling
      PendingRequest pendingRequest = prevRequest.request;
      response.account = pendingRequest.account;
      EventTaxiImpl.singleton().fire(TransferPendingEvent(response: response));
    } else {
      // Initiate receive/open request for each pending
      response.blocks.forEach((hash, pendingResponseItem) {
        PendingResponseItem pendingResponseItemN = pendingResponseItem;
        pendingResponseItemN.hash = hash;
        handlePendingItem(pendingResponseItemN);
      });
      if (response.blocks.length == 0) {
        AccountService.processQueue();
      }
    }
  }

  /// Handle account_subscribe response
  void handleSubscribeResponse(SubscribeResponse response) {
    // Check next request to update block count
    if (response.blockCount != null && !wallet.historyLoading) {
      // Raise minimum receive if high pending block count
      if (response.pendingCount != null && response.pendingCount > 50) {
        // Raise receive minimum to 1 BANANO
        receiveMinimum = BigInt.from(10).pow(29).toString();
      }
      // Choose correct blockCount to minimize bandwidth
      // This is can still be improved because history excludes change/open, blockCount doesn't
      // Get largest count we have + 5 (just a safe-buffer)
      int count = max(response.blockCount, wallet.history.length) + 5;
      // Subtract by what we already have to get amount we want to request
      count -= wallet.history.length;
      // Minimum of 10 to request
      count = count <= 0 ? 10 : count;
      AccountService.requestQueue.forEach((requestItem) {
        if (requestItem.request is AccountHistoryRequest) {
          requestItem.request.count = count;
        }
      });
    }
    // Set currency locale here for the UI to access
    SharedPrefsUtil.inst.getCurrency(deviceLocale).then((currency) {
      setState(() {
        currencyLocale = currency.getLocale().toString();
        curCurrency = currency;
      });
    });
    // Server gives us a UUID for future requests on subscribe
    if (response.uuid != null) {
      SharedPrefsUtil.inst.setUuid(response.uuid);
    }
    setState(() {
      wallet.loading = false;
      wallet.frontier = response.frontier;
      wallet.representative = response.representative;
      wallet.representativeBlock = response.representativeBlock;
      wallet.openBlock = response.openBlock;
      wallet.blockCount = response.blockCount;
      if (response.balance == null) {
        wallet.accountBalance = BigInt.from(0);
      } else {
        wallet.accountBalance = BigInt.tryParse(response.balance);
      }
      wallet.localCurrencyPrice = response.price.toString();
      wallet.nanoPrice = response.nanoPrice.toString();
      wallet.btcPrice = response.btcPrice.toString();
    });
    AccountService.pop();
    AccountService.processQueue();
  }

  /// Handle blocks_info response
  /// Typically, this preceeds a process request. And we want to update
  /// that request with data from the previous block (which is what we got from this request)
  void handleBlocksInfoResponse(BlocksInfoResponse resp) {
    String hash = resp.blocks.keys.first;
    StateBlock previousBlock =
        StateBlock.fromJson(json.decode(resp.blocks[hash].contents));
    StateBlock nextBlock = previousPendingMap.remove(hash);
    RequestItem lastRequest = AccountService.pop();
    if (nextBlock == null) {
      return;
    }

    // Update data on our next pending request
    nextBlock.representative = previousBlock.representative;
    nextBlock.setBalance(previousBlock.balance);
    if (nextBlock.subType == BlockTypes.SEND && nextBlock.balance == "0") {
      // In case of a max send, go back and update sendAmount with the balance
      nextBlock.sendAmount = wallet.accountBalance.toString();
    }
    _getPrivKey().then((result) {
      if (lastRequest.fromTransfer) {
        nextBlock.sign(nextBlock.privKey);
      } else {
        nextBlock.sign(result);
      }
      pendingResponseBlockMap.putIfAbsent(nextBlock.hash, () => nextBlock);
      // If this is of type RECEIVE, update its data in our pending map
      if (nextBlock.subType == BlockTypes.RECEIVE &&
          !lastRequest.fromTransfer) {
        StateBlock prevReceive = pendingBlockMap.remove(nextBlock.link);
        if (prevReceive != null) {
          print("put ${nextBlock.hash}");
          pendingBlockMap.putIfAbsent(nextBlock.hash, () => nextBlock);
        }
      }
      AccountService.queueRequest(
          ProcessRequest(
              block: json.encode(nextBlock.toJson()),
              subType: nextBlock.subType),
          fromTransfer: lastRequest.fromTransfer);
      AccountService.processQueue();
    });
  }

  /// Handle callback response
  /// Typically this means we need to pocket transactions
  void handleCallbackResponse(CallbackResponse resp) {
    if (_locked) {
      return;
    }
    log.fine("Received callback ${json.encode(resp.toJson())}");
    if (resp.isSend != "true") {
      log.fine("Is not send");
      AccountService.processQueue();
      return;
    }
    PendingResponseItem pendingItem = PendingResponseItem(
        hash: resp.hash, source: resp.account, amount: resp.amount);
    handlePendingItem(pendingItem);
  }

  void handlePendingItem(PendingResponseItem item) {
    BigInt amountBigInt = BigInt.tryParse(item.amount);
    if (amountBigInt != null) {
      if (amountBigInt < BigInt.parse(receiveMinimum)) {
        return;
      }
    }
    if (!AccountService.queueContainsRequestWithHash(item.hash) &&
        !pendingBlockMap.containsKey(item.hash)) {
      if (wallet.openBlock == null &&
          !AccountService.queueContainsOpenBlock()) {
        requestOpen("0", item.hash, item.amount);
      } else if (pendingBlockMap.length == 0) {
        requestReceive(wallet.frontier, item.hash, item.amount);
      } else {
        pendingBlockMap.putIfAbsent(item.hash, () {
          return StateBlock(
              subtype: BlockTypes.RECEIVE,
              previous: wallet.frontier,
              representative: wallet.representative,
              balance: item.amount,
              link: item.hash,
              account: wallet.address);
        });
      }
    }
  }

  Future<void> requestUpdate() async {
    if (wallet != null &&
        wallet.address != null &&
        Address(wallet.address).isValid()) {
      String uuid = await SharedPrefsUtil.inst.getUuid();
      String fcmToken = await FirebaseMessaging().getToken();
      bool notificationsEnabled =
          await SharedPrefsUtil.inst.getNotificationsOn();
      AccountService.clearQueue();
      pendingBlockMap.clear();
      pendingResponseBlockMap.clear();
      previousPendingMap.clear();
      AccountService.queueRequest(SubscribeRequest(
          account: wallet.address,
          currency: curCurrency.getIso4217Code(),
          uuid: uuid,
          fcmToken: fcmToken,
          notificationEnabled: notificationsEnabled));
      AccountService.queueRequest(
          AccountHistoryRequest(account: wallet.address));
      AccountService.processQueue();
    }
  }

  Future<void> requestSubscribe() async {
    if (wallet != null &&
        wallet.address != null &&
        Address(wallet.address).isValid()) {
      String uuid = await SharedPrefsUtil.inst.getUuid();
      String fcmToken = await FirebaseMessaging().getToken();
      bool notificationsEnabled =
          await SharedPrefsUtil.inst.getNotificationsOn();
      AccountService.removeSubscribeHistoryPendingFromQueue();
      AccountService.queueRequest(SubscribeRequest(
          account: wallet.address,
          currency: curCurrency.getIso4217Code(),
          uuid: uuid,
          fcmToken: fcmToken,
          notificationEnabled: notificationsEnabled));
      AccountService.processQueue();
    }
  }

  ///
  /// Request accounts_balances
  ///
  void requestAccountsBalances(List<String> accounts) {
    if (accounts != null && accounts.isNotEmpty) {
      AccountService.queueRequest(AccountsBalancesRequest(accounts: accounts));
      AccountService.processQueue();
    }
  }

  ///
  /// Request account history
  ///
  void requestAccountHistory(String account) {
    AccountService.queueRequest(
        AccountHistoryRequest(account: account, count: 1),
        fromTransfer: true);
    AccountService.processQueue();
  }

  ///
  /// Request pending blocks
  ///
  void requestPending({String account}) {
    if (wallet.address != null && account == null) {
      AccountService.queueRequest(PendingRequest(
          account: wallet.address, count: max(wallet.blockCount ?? 0, 10), threshold: receiveMinimum));
      AccountService.processQueue();
    } else {
      AccountService.queueRequest(PendingRequest(account: account, count: 20, threshold: receiveMinimum),
          fromTransfer: true);
      AccountService.processQueue();
    }
  }

  ///
  /// Create a state block send request
  ///
  /// @param previous - Previous Hash
  /// @param destination - Destination address
  /// @param amount - Amount to send in RAW
  ///
  void requestSend(String previous, String destination, String amount,
      {String privKey, String account, String localCurrencyAmount}) {
    String representative = wallet.representative;
    bool fromTransfer = privKey == null && account == null ? false : true;

    StateBlock sendBlock = StateBlock(
        subtype: BlockTypes.SEND,
        previous: previous,
        representative: representative,
        balance: amount,
        link: destination,
        account: !fromTransfer ? wallet.address : account,
        privKey: privKey,
        localCurrencyValue: localCurrencyAmount);
    previousPendingMap.putIfAbsent(previous, () => sendBlock);

    AccountService.queueRequest(BlocksInfoRequest(hashes: [previous]),
        fromTransfer: fromTransfer);
    AccountService.processQueue();
  }

  ///
  /// Create a state block receive request
  ///
  /// @param previous - Previous Hash
  /// @param source - source address
  /// @param balance - balance in RAW
  /// @param privKey - private key (optional, used for transfer)
  ///
  void requestReceive(String previous, String source, String balance,
      {String privKey, String account}) {
    String representative = wallet.representative;
    bool fromTransfer = privKey == null && account == null ? false : true;

    StateBlock receiveBlock = StateBlock(
        subtype: BlockTypes.RECEIVE,
        previous: previous,
        representative: representative,
        balance: balance,
        link: source,
        account: !fromTransfer ? wallet.address : account,
        privKey: privKey);
    previousPendingMap.putIfAbsent(previous, () => receiveBlock);
    if (!fromTransfer) {
      pendingBlockMap.putIfAbsent(source, () => receiveBlock);
    }

    AccountService.queueRequest(BlocksInfoRequest(hashes: [previous]),
        fromTransfer: fromTransfer);
    AccountService.processQueue();
  }

  ///
  /// Create a state block open request
  ///
  /// @param previous - Previous Hash
  /// @param source - source address
  /// @param balance - balance in RAW
  /// @param privKey - optional private key to use to sign block wen from transfer
  ///
  void requestOpen(String previous, String source, String balance,
      {String privKey, String account}) {
    String representative = wallet.representative;
    bool fromTransfer = privKey == null && account == null ? false : true;

    StateBlock openBlock = StateBlock(
        subtype: BlockTypes.OPEN,
        previous: previous,
        representative: representative,
        balance: balance,
        link: source,
        account: !fromTransfer ? wallet.address : account);
    _getPrivKey().then((result) {
      if (!fromTransfer) {
        openBlock.sign(result);
      } else {
        openBlock.sign(privKey);
      }
      pendingResponseBlockMap.putIfAbsent(openBlock.hash, () => openBlock);

      AccountService.queueRequest(
          ProcessRequest(
              block: json.encode(openBlock.toJson()), subType: BlockTypes.OPEN),
          fromTransfer: fromTransfer);
      AccountService.processQueue();
    });
  }

  ///
  /// Create a state block change request
  ///
  /// @param previous - Previous Hash
  /// @param balance - Current balance
  /// @param representative - representative
  ///
  void requestChange(String previous, String balance, String representative) {
    StateBlock changeBlock = StateBlock(
        subtype: BlockTypes.CHANGE,
        previous: previous,
        representative: representative,
        balance: balance,
        link:
            "0000000000000000000000000000000000000000000000000000000000000000",
        account: wallet.address);
    _getPrivKey().then((result) {
      changeBlock.sign(result);
      pendingResponseBlockMap.putIfAbsent(changeBlock.hash, () => changeBlock);

      AccountService.queueRequest(ProcessRequest(
          block: json.encode(changeBlock.toJson()),
          subType: BlockTypes.CHANGE));
      AccountService.processQueue();
    });
  }

  void logOut() {
    setState(() {
      wallet = AppWallet();
    });
    AccountService.clearQueue();
  }

  Future<String> _getPrivKey() async {
    return NanoUtil.seedToPrivate(await Vault.inst.getSeed(), 0);
  }

  // Simple build method that just passes this state through
  // your InheritedWidget
  @override
  Widget build(BuildContext context) {
    return _InheritedStateContainer(
      data: this,
      child: widget.child,
    );
  }
}
