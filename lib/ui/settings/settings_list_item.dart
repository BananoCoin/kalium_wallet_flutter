import 'package:flutter/material.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/app_icons.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';
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
          margin: EdgeInsetsDirectional.only(start: 30.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsetsDirectional.only(end: 13.0),
                child: Container(
                  child: Icon(icon,
                      color: disabled
                          ? StateContainer.of(context).curTheme.primary45
                          : StateContainer.of(context).curTheme.primary,
                      size: 24),
                  margin: EdgeInsets.all(3),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: sl.get<UIUtil>().drawerWidth(context)-100,
                    child: AutoSizeText(
                      heading,
                      style: disabled
                          ? AppStyles.textStyleSettingItemHeader45(context)
                          : AppStyles.textStyleSettingItemHeader(context),
                      maxLines: 1,
                      stepGranularity: 0.1,
                      minFontSize: 8,
                    ),
                  ),
                  Container(
                    width: sl.get<UIUtil>().drawerWidth(context)-100,
                    child: AutoSizeText(
                      defaultMethod.getDisplayName(context),
                      style: disabled
                          ? AppStyles.textStyleSettingItemSubheader30(context)
                          : AppStyles.textStyleSettingItemSubheader(context),
                      maxLines: 1,
                      stepGranularity: 0.1,
                      minFontSize: 8,
                    ),
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
        margin: EdgeInsetsDirectional.only(start: 30.0),
        child: Row(
          children: <Widget>[
            Container(
              margin: EdgeInsetsDirectional.only(end: 13.0),
              child: Container(
                child: Icon(
                  settingIcon,
                  color: StateContainer.of(context).curTheme.primary,
                  size: 24,
                ),
                margin: EdgeInsetsDirectional.only(
                  top: 3,
                  start: settingIcon == AppIcons.logout ? 6 : settingIcon == AppIcons.changerepresentative? 0: settingIcon == AppIcons.backupseed ? 1: settingIcon == AppIcons.transferfunds ? 2:3,
                  bottom: 3,
                  end: settingIcon == AppIcons.logout ? 0 : settingIcon == AppIcons.changerepresentative? 6: settingIcon == AppIcons.backupseed ? 5: settingIcon == AppIcons.transferfunds ? 4:3,
                ),
              ),
            ),
            Container( 
              width: sl.get<UIUtil>().drawerWidth(context)-100,
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
