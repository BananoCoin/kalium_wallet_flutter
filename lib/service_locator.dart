import 'package:get_it/get_it.dart';

import 'package:kalium_wallet_flutter/network/account_service.dart';

GetIt sl = new GetIt();

void setupServiceLocator() {
  sl.registerLazySingleton<AccountService>(() => AccountService());
}