import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flare_flutter/flare_actor.dart';

import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/util/fileutil.dart';

class MonkeyWidget extends StatefulWidget {
  final String address;
  final MonkeySize size;

  MonkeyWidget({Key key, @required this.address, @required this.size}) : super(key: key);

  @override
  _MonkeyWidgetState createState() => _MonkeyWidgetState();
}

class _MonkeyWidgetState extends State<MonkeyWidget> {
  File monkeyFile;
  String lastAddress;

  @override
  void initState() {
    super.initState();
    this.lastAddress = widget.address;
    _getMonkey();
  }

  Future<void> _getMonkey() async {
    if (widget.address != null) {
      File monkeyF = await sl.get<UIUtil>().downloadOrRetrieveMonkey(context, widget.address, widget.size);
      bool isValid = true;
      if (widget.size != MonkeySize.SVG) {
        if (!await FileUtil().pngHasValidSignature(monkeyF)) {
          isValid = false;
        }
      }
      if (isValid) {
        if (mounted) {
          setState(() {
            monkeyFile = monkeyF;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.address != lastAddress) {
      setState(() {
        this.lastAddress = widget.address;
        this.monkeyFile = null;
      });
      _getMonkey();
    }
    return RepaintBoundary(
      child: monkeyFile == null ?
        FlareActor("assets/monkey_placeholder_animation.flr",
            animation: "main",
            fit: BoxFit.contain,
            color: StateContainer.of(context).curTheme.primary)
        : widget.size == MonkeySize.SVG ? SvgPicture.file(monkeyFile) : Image.file(monkeyFile),
    );
  }
}