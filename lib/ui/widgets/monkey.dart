import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flare_flutter/flare_actor.dart';

import 'package:kalium_wallet_flutter/appstate_container.dart';

import '../../service_locator.dart';
import '../util/ui_util.dart';
import '../util/ui_util.dart';

class MonkeyWidget extends StatefulWidget {
  final String address;
  final double size;

  MonkeyWidget({Key key, @required this.address, @required this.size}) : super(key: key);

  @override
  _MonkeyWidgetState createState() => _MonkeyWidgetState();
}

class _MonkeyWidgetState extends State<MonkeyWidget> {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: 
      Container(
        width: widget.size,
        height: widget.size,
        child: SvgPicture.network(
            UIUtil.getMonkeyURL(widget.address),
            key: Key(UIUtil.getMonkeyURL(widget.address)),
            placeholderBuilder: (BuildContext context) =>
                Container(
                  child: FlareActor(
                    "assets/monkey_placeholder_animation.flr",
                    animation: "main",
                    fit: BoxFit.contain,
                    color: StateContainer.of(context)
                        .curTheme
                        .primary,
                  ),
                )),
      )    
    );
  }
}