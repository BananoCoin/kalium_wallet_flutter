import 'package:flutter/material.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/themes.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/ui/widgets/app_simpledialog.dart';
import 'package:kalium_wallet_flutter/util/caseconverter.dart';

class AppDialogs {
  static void showConfirmDialog(
      var context, var title, var content, var buttonText, Function onPressed,
      {String cancelText}) {
    if (cancelText == null) {
      cancelText = AppLocalization.of(context).cancel.toUpperCase();
    }
    showAppDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(
            title,
            style: AppStyles.textStyleButtonPrimaryOutline(context),
          ),
          content: Text(content, style: AppStyles.textStyleParagraph(context)),
          actions: <Widget>[
            FlatButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0)),
              padding: EdgeInsets.all(12),
              child: Container(
                constraints: BoxConstraints(maxWidth: 100),
                child: Text(
                  cancelText,
                  style: AppStyles.textStyleDialogButtonText(context),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.0)),
              padding: EdgeInsets.all(12),
              child: Container(
                constraints: BoxConstraints(maxWidth: 100),
                child: Text(
                  buttonText,
                  style: AppStyles.textStyleDialogButtonText(context),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onPressed();
              },
            ),
          ],
        );
      },
    );
  }

  static void showInfoDialog(var context, var title, var content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AppAlertDialog(
          title: Text(
            title,
            style: AppStyles.textStyleButtonPrimaryOutline(context),
          ),
          content: Text(content, style: AppStyles.textStyleParagraph(context)),
          actions: <Widget>[
            FlatButton(
              child: Text(
                AppLocalization.of(context).cancel.toUpperCase(),
                style: AppStyles.textStyleDialogButtonText(context),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

enum AnimationType {
  SEND,
  GENERIC,
  TRANSFER_SEARCHING_QR,
  TRANSFER_SEARCHING_MANUAL,
  TRANSFER_TRANSFERRING
}

class AnimationLoadingOverlay extends ModalRoute<void> {
  AnimationType type;
  Function onPoppedCallback;
  Color overlay85;
  Color overlay70;

  AnimationLoadingOverlay(this.type, this.overlay85, this.overlay70, {this.onPoppedCallback});

  @override
  Duration get transitionDuration => Duration(milliseconds: 0);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor {
    if (type == AnimationType.TRANSFER_TRANSFERRING ||
        type == AnimationType.TRANSFER_SEARCHING_QR ||
        type == AnimationType.TRANSFER_SEARCHING_MANUAL) {
      return overlay85;
    }
    return overlay70;
  }

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => false;

  @override
  void didComplete(void result) {
    if (this.onPoppedCallback != null) {
      this.onPoppedCallback();
    }
    super.didComplete(result);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: _buildOverlayContent(context),
      ),
    );
  }

  Widget _getAnimation(BuildContext context) {
    switch (type) {
      case AnimationType.SEND:
        return Stack(
          children: <Widget>[
            Center(
              child: FlareActor(
                "assets/send_animation_bananasonly.flr",
                animation: "main",
                fit: BoxFit.contain,
                color: StateContainer.of(context).curTheme.primary,
              ),
            ),
            Center(
              child: FlareActor(
                "assets/send_animation_shadowsonly.flr",
                animation: "main",
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      case AnimationType.TRANSFER_SEARCHING_QR:
        return Stack(
          children: <Widget>[
            Center(
              child: FlareActor(
                "assets/searchseedqr_animation_qronly.flr",
                animation: "main",
                fit: BoxFit.contain,
              ),
            ),
            Center(
              child: FlareActor(
                "assets/searchseedqr_animation_glassonly.flr",
                animation: "main",
                fit: BoxFit.contain,
              ),
            ),
            Center(
              child: FlareActor(
                "assets/searchseedqr_animation_magnifyingglassonly.flr",
                animation: "main",
                fit: BoxFit.contain,
                color: StateContainer.of(context).curTheme.primary,
              ),
            ),
          ],
        );
      case AnimationType.TRANSFER_SEARCHING_MANUAL:
        return Stack(
          children: <Widget>[
            Center(
              child: FlareActor(
                "assets/searchseedmanual_animation_seedonly.flr",
                animation: "main",
                fit: BoxFit.contain,
                color: StateContainer.of(context).curTheme.primary30,
              ),
            ),
            Center(
              child: FlareActor(
                "assets/searchseedmanual_animation_glassonly.flr",
                animation: "main",
                fit: BoxFit.contain,
              ),
            ),
            Center(
              child: FlareActor(
                "assets/searchseedmanual_animation_magnifyingglassonly.flr",
                animation: "main",
                fit: BoxFit.contain,
                color: StateContainer.of(context).curTheme.primary,
              ),
            ),
          ],
        );
      case AnimationType.TRANSFER_TRANSFERRING:
        return Stack(
          children: <Widget>[
            FlareActor(
              "assets/transfer_animation_paperwalletonly.flr",
              animation: "main",
              fit: BoxFit.contain,
            ),
            FlareActor(
              "assets/transfer_animation_kaliumwalletonly.flr",
              animation: "main",
              fit: BoxFit.contain,
              color: StateContainer.of(context).curTheme.primary,
            ),
          ],
        );
      case AnimationType.GENERIC:
      default:
        return CircularProgressIndicator(
            valueColor: new AlwaysStoppedAnimation<Color>(
                StateContainer.of(context).curTheme.primary60));
    }
  }

  Widget _buildOverlayContent(BuildContext context) {
    switch (type) {
      case AnimationType.TRANSFER_SEARCHING_QR:
        return Center(
          child: Container(
            margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.15),
            width: MediaQuery.of(context).size.width / 1.1,
            height: MediaQuery.of(context).size.width / 1.1,
            child: _getAnimation(context),
          ),
        );
      case AnimationType.TRANSFER_SEARCHING_MANUAL:
        return Center(
          child: Container(
            margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.15),
            width: MediaQuery.of(context).size.width / 1.1,
            height: MediaQuery.of(context).size.width / 1.1,
            child: _getAnimation(context),
          ),
        );
      case AnimationType.TRANSFER_TRANSFERRING:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                alignment: AlignmentDirectional(0, -0.5),
                width: MediaQuery.of(context).size.width / 1.4,
                height: MediaQuery.of(context).size.width / 1.4 / 2,
                child: _getAnimation(context),
              ),
              Container(
                margin: EdgeInsetsDirectional.only(
                    start: 10,
                    top: 20,
                    bottom: MediaQuery.of(context).size.height * 0.15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                        CaseChange.toUpperCase(
                            AppLocalization.of(context).transferLoading,
                            context),
                        style: AppStyles.textStyleHeader2Colored(context)),
                    Container(
                      margin: EdgeInsets.only(bottom: 7),
                      width: 33.333,
                      height: 8.866,
                      child: FlareActor(
                        "assets/threedot_animation.flr",
                        animation: "main",
                        fit: BoxFit.contain,
                        color: StateContainer.of(context).curTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      default:
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: type == AnimationType.SEND
              ? MainAxisAlignment.end
              : MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: type == AnimationType.SEND
                  ? EdgeInsets.only(bottom: 10.0, left: 90, right: 90)
                  : EdgeInsets.zero,
              //Widgth/Height ratio is needed because BoxFit is not working as expected
              width: type == AnimationType.SEND ? double.infinity : 100,
              height: type == AnimationType.SEND
                  ? MediaQuery.of(context).size.width
                  : 100,
              child: _getAnimation(context),
            ),
          ],
        );
    }
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}
