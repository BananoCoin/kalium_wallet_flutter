import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flare_flutter/flare_actor.dart';

import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';

class MonkeyWidget extends StatefulWidget {
  final String address;

  MonkeyWidget({Key key, @required this.address}) : super(key: key);

  @override
  _MonkeyWidgetState createState() => _MonkeyWidgetState();
}

class _MonkeyWidgetState extends State<MonkeyWidget> {
  File monkeyFile;

  @override
  void initState() {
    super.initState();
    _getMonkey();
  }

  Future<void> _getMonkey() async {
    if (widget.address != null) {
      File monkeyF = await sl.get<UIUtil>().downloadOrRetrieveMonkey(context, widget.address, MonkeySize.SVG);
      setState(() {
        monkeyFile = monkeyF;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: monkeyFile == null ?
        FlareActor("assets/monkey_placeholder_animation.flr",
            animation: "main",
            fit: BoxFit.contain,
            color: StateContainer.of(context).curTheme.primary)
        : SvgPicture.file(monkeyFile),
    );
  }
}