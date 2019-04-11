import 'package:get_it/get_it.dart';

import 'package:kalium_wallet_flutter/network/account_service.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/util/numberutil.dart';

GetIt sl = new GetIt();

void setupServiceLocator() {
  sl.registerLazySingleton<AccountService>(() => AccountService());
  sl.registerLazySingleton<UIUtil>(() => UIUtil());
  sl.registerLazySingleton<NumberUtil>(() => NumberUtil());
}