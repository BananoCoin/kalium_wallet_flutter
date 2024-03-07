import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_nano_ffi/flutter_nano_ffi.dart';

import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/model/db/appdb.dart';
import 'package:kalium_wallet_flutter/model/db/account.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/localization.dart';

import '../model/vault.dart';

class NanoUtil {
  static String seedToPrivate(String seed, int index) {
    return NanoKeys.seedToPrivate(seed, index);
  }

  static String privateToAddress(String privateKey) {
    return NanoAccounts.createAccount(
        NanoAccountType.BANANO, NanoKeys.createPublicKey(privateKey));
  }

  static String seedToAddress(String seed, int index) {
    return NanoAccounts.createAccount(NanoAccountType.BANANO,
        NanoKeys.createPublicKey(seedToPrivate(seed, index)));
  }

  Future<void> loginAccount(BuildContext context) async {
    Account selectedAcct = await sl.get<DBHelper>().getSelectedAccount();
    if (selectedAcct == null) {
      selectedAcct = Account(
          index: 0,
          lastAccess: 0,
          name: AppLocalization.of(context).defaultAccountName,
          address: NanoUtil.seedToAddress(await sl.get<Vault>().getSeed(), 0),
          selected: true);
      await sl.get<DBHelper>().saveAccount(selectedAcct);
    }
    await StateContainer.of(context).updateWallet(account: selectedAcct);
  }
}
