import 'package:flutter/material.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/ui/util/exceptions.dart';

enum AppButtonType { PRIMARY, PRIMARY_OUTLINE, SUCCESS, SUCCESS_OUTLINE, TEXT_OUTLINE }

class AppButton {
  // Primary button builder
  static Widget buildAppButton(BuildContext context,
      AppButtonType type, String buttonText, List<double> dimens,
      {Function onPressed, bool disabled = false}) {
    switch (type) {
      case AppButtonType.PRIMARY:
        return Expanded(
          child: Container(
            margin:
                EdgeInsets.fromLTRB(dimens[0], dimens[1], dimens[2], dimens[3]),
            child: FlatButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0)),
              color: disabled ? StateContainer.of(context).curTheme.primary60 : StateContainer.of(context).curTheme.primary,
              child: Text(buttonText,
                  textAlign: TextAlign.center,
                  style: AppStyles.textStyleButtonPrimary(context)),
              padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 20),
              onPressed: () {
                if (onPressed != null && !disabled) {
                  onPressed();
                }
                return;
              },
              highlightColor: StateContainer.of(context).curTheme.background40,
              splashColor: StateContainer.of(context).curTheme.background40,
            ),
          ),
        );
      case AppButtonType.PRIMARY_OUTLINE:
        return Expanded(
          child: Container(
            margin:
                EdgeInsets.fromLTRB(dimens[0], dimens[1], dimens[2], dimens[3]),
            child: OutlineButton(
              textColor: disabled ? StateContainer.of(context).curTheme.primary60 : StateContainer.of(context).curTheme.primary,
              borderSide: BorderSide(color: disabled? StateContainer.of(context).curTheme.primary60 : StateContainer.of(context).curTheme.primary, width: 2.0),
              highlightedBorderColor: disabled ? StateContainer.of(context).curTheme.primary60 : StateContainer.of(context).curTheme.primary,
              splashColor: StateContainer.of(context).curTheme.primary30,
              highlightColor: StateContainer.of(context).curTheme.primary15,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0)),
              child: Text(buttonText,
                  textAlign: TextAlign.center,
                  style: disabled ? AppStyles.textStyleButtonPrimaryOutlineDisabled(context) : AppStyles.textStyleButtonPrimaryOutline(context)),
              padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 20),
              onPressed: () {
                if (onPressed != null && !disabled) {
                  onPressed();
                }
                return;
              },
            ),
          ),
        );
      case AppButtonType.SUCCESS:
        return Expanded(
          child: Container(
            margin:
                EdgeInsets.fromLTRB(dimens[0], dimens[1], dimens[2], dimens[3]),
            child: FlatButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0)),
              color: StateContainer.of(context).curTheme.success,
              child: Text(buttonText,
                  textAlign: TextAlign.center,
                  style: AppStyles.textStyleButtonPrimaryGreen(context)),
              padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 20),
              onPressed: () {
                if (onPressed != null && !disabled) {
                  onPressed();
                }
                return;
              },
              highlightColor: StateContainer.of(context).curTheme.success30,
              splashColor: StateContainer.of(context).curTheme.successDark,
            ),
          ),
        );
      case AppButtonType.SUCCESS_OUTLINE:
        return Expanded(
          child: Container(
            margin:
                EdgeInsets.fromLTRB(dimens[0], dimens[1], dimens[2], dimens[3]),
            child: OutlineButton(
              textColor: StateContainer.of(context).curTheme.success,
              borderSide: BorderSide(color: StateContainer.of(context).curTheme.success, width: 2.0),
              highlightedBorderColor: StateContainer.of(context).curTheme.success,
              splashColor: StateContainer.of(context).curTheme.success30,
              highlightColor: StateContainer.of(context).curTheme.success15,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0)),
              child: Text(buttonText,
                  textAlign: TextAlign.center,
                  style: AppStyles.textStyleButtonSuccessOutline(context)),
              padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 20),
              onPressed: () {
                if (onPressed != null) {
                  onPressed();
                }
                return;
              },
            ),
          ),
        );
        case AppButtonType.TEXT_OUTLINE:
        return Expanded(
          child: Container(
            margin:
                EdgeInsets.fromLTRB(dimens[0], dimens[1], dimens[2], dimens[3]),
            child: OutlineButton(
              textColor: StateContainer.of(context).curTheme.text,
              borderSide: BorderSide(color: StateContainer.of(context).curTheme.text, width: 2.0),
              highlightedBorderColor: StateContainer.of(context).curTheme.text,
              splashColor: StateContainer.of(context).curTheme.text30,
              highlightColor: StateContainer.of(context).curTheme.text15,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100.0)),
              child: Text(buttonText,
                  textAlign: TextAlign.center,
                  style: AppStyles.textStyleButtonTextOutline(context)),
              padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 20),
              onPressed: () {
                if (onPressed != null) {
                  onPressed();
                }
                return;
              },
            ),
          ),
        );
      default:
        throw new UIException("Invalid Button Type $type");
    }
  } //
}
