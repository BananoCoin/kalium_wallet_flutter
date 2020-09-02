import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:kalium_wallet_flutter/ui/widgets/sheet_util.dart';
import 'package:kalium_wallet_flutter/util/sharedprefsutil.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';

import '../../app_icons.dart';

class AvatarPage extends StatefulWidget {
  @override
  _AvatarPageState createState() => _AvatarPageState();
}

class _AvatarPageState extends State<AvatarPage>
    with SingleTickerProviderStateMixin {
  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  AnimationController _controller;
  Animation<Color> bgColorAnimation;
  Animation<Offset> offsetTween;
  bool hasEnoughFunds;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bgColorAnimation = ColorTween(
      begin: Colors.transparent,
      end: StateContainer.of(context).curTheme.overlay70,
    ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn));
    offsetTween = Tween<Offset>(begin: Offset(0, 200), end: Offset(0, 0))
        .animate(CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOut,
            reverseCurve: Curves.easeIn));
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          resizeToAvoidBottomPadding: false,
          backgroundColor: bgColorAnimation.value,
          key: _scaffoldKey,
          body: LayoutBuilder(
            builder: (context, constraints) => SafeArea(
              bottom: false,
              minimum: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height * 0.10),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        // Gesture Detector
                        Container(
                          child: GestureDetector(onTapDown: (details) {
                            _controller.reverse();
                            Navigator.pop(context);
                          }),
                        ),
                        // Avatar
                        Container(
                          margin: EdgeInsetsDirectional.only(
                              bottom: MediaQuery.of(context).size.height * 0.2),
                          child: ClipOval(
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.width,
                              child: ClipOval(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: <Widget>[
                                    Hero(
                                      tag: "avatar",
                                      child: SvgPicture.network(
                                        UIUtil.getMonkeyURL(
                                            StateContainer.of(context)
                                                .selectedAccount
                                                .address),
                                        key: Key(UIUtil.getMonkeyURL(
                                            StateContainer.of(context)
                                                .selectedAccount
                                                .address)),
                                        placeholderBuilder:
                                            (BuildContext context) => Container(
                                          child: FlareActor(
                                            "assets/ntr_placeholder_animation.flr",
                                            animation: "main",
                                            fit: BoxFit.contain,
                                            color: StateContainer.of(context)
                                                .curTheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    /* // Button for the interaction
                                    FlatButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(2000.0)),
                                      highlightColor:
                                          StateContainer.of(context).curTheme.text15,
                                      splashColor:
                                          StateContainer.of(context).curTheme.text15,
                                      padding: EdgeInsets.all(0.0),
                                      child: Container(
                                        color: Colors.transparent,
                                      ),
                                    ) */
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
