// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ko locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ko';

  final messages = _notInlinedMessages(_notInlinedMessages);
  static _notInlinedMessages(_) => <String, Function> {
    "exampleCardFromKal" : MessageLookupByLibrary.simpleMessage("임의의 발송자로부터"),
    "exampleCardIntroKal" : MessageLookupByLibrary.simpleMessage("Kalium에 오신 것을 환영합니다. BANANO를 받으시면 거래가 다음과 같이 표시됩니다."),
    "exampleCardToKal" : MessageLookupByLibrary.simpleMessage("임의의 수령인에게"),
    "logoutDetailKal" : MessageLookupByLibrary.simpleMessage("로그 아웃하면 시드와 모든 Kalium 관련 데이터가 삭제됩니다. 귀하의 시드가 백업되지 않은 경우 귀하의 자금을 다시  복구 할 수 없습니다."),
    "notificationBodyKal" : MessageLookupByLibrary.simpleMessage("이 거래를 보려면 Kalium을 여십시오."),
    "notificationTitleKal" : MessageLookupByLibrary.simpleMessage("% s개의 BANANO을 받았습니다"),
    "scanInstructionsKal" : MessageLookupByLibrary.simpleMessage("Banano QR 코드 주소를 스캔하하세요"),
    "sendAmountConfirmKal" : MessageLookupByLibrary.simpleMessage("%1 Banano를 발송하시겠습니까?"),
    "welcomeTextKal" : MessageLookupByLibrary.simpleMessage("Kalium에 오신 것을 환영합니다. 계속하려면, 새 지갑을 만들거나 기존 지갑을 불러오세요.")
  };
}
