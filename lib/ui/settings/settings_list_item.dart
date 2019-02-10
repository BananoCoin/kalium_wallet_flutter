import 'package:flutter/material.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/app_icons.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/model/setting_item.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/ui/widgets/auto_resize_text.dart';

class AppSettings {
  //Settings item with a dropdown option
  static Widget buildSettingsListItemDoubleLine(
      BuildContext context,
      String heading,
      SettingSelectionItem defaultMethod,
      IconData icon,
      Function onPressed,
      {bool disabled = false}) {
    return IgnorePointer(
      ignoring: disabled,
      child: FlatButton(
        highlightColor: StateContainer.of(context).curTheme.text15,
        splashColor: StateContainer.of(context).curTheme.text15,
        onPressed: () {
          onPressed();
        },
        padding: EdgeInsets.all(0.0),
        child: Container(
          height: 60.0,
          margin: EdgeInsets.only(left: 30.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(right: 13.0),
                child: Container(
                  child: Icon(icon,
                      color: disabled
                          ? StateContainer.of(context).curTheme.primary45
                          : StateContainer.of(context).curTheme.primary,
                      size: 24),
                  margin: EdgeInsets.only(top: 3, left: 3, bottom: 3, right: 3),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    heading,
                    style: disabled
                        ? AppStyles.textStyleSettingItemHeader45(context)
                        : AppStyles.textStyleSettingItemHeader(context),
                  ),
                  Text(
                    defaultMethod.getDisplayName(context),
                    style: disabled
                        ? AppStyles.textStyleSettingItemSubheader30(context)
                        : AppStyles.textStyleSettingItemSubheader(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Settings item without any dropdown option but rather a direct functionality
  static Widget buildSettingsListItemSingleLine(
      BuildContext context, String heading, IconData settingIcon,
      {Function onPressed}) {
    return FlatButton(
      highlightColor: StateContainer.of(context).curTheme.text15,
      splashColor: StateContainer.of(context).curTheme.text15,
      onPressed: () {
        if (onPressed != null) {
          onPressed();
        } else {
          return;
        }
      },
      padding: EdgeInsets.all(0.0),
      child: Container(
        height: 60.0,
        margin: new EdgeInsets.only(left: 30.0),
        child: Row(
          children: <Widget>[
            Container(
              margin: new EdgeInsets.only(right: 13.0),
              child: Container(
                child: new Icon(
                  settingIcon,
                  color: StateContainer.of(context).curTheme.primary,
                  size: 24,
                ),
                margin: EdgeInsets.only(
                  top: 3,
                  left: settingIcon == AppIcons.logout ? 6 : settingIcon == AppIcons.changerepresentative? 0: settingIcon == AppIcons.backupseed ? 1: settingIcon == AppIcons.transferfunds ? 2:3,
                  bottom: 3,
                  right: settingIcon == AppIcons.logout ? 0 : settingIcon == AppIcons.changerepresentative? 6: settingIcon == AppIcons.backupseed ? 5: settingIcon == AppIcons.transferfunds ? 4:3,
                ),
              ),
            ),
            Container( 
              width: UIUtil.drawerWidth(context)-100,
              child: Text(
                heading,
                style: AppStyles.textStyleSettingItemHeader(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
