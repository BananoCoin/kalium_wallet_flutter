import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/app_icons.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:kalium_wallet_flutter/ui/widgets/security.dart';
import 'package:kalium_wallet_flutter/util/sharedprefsutil.dart';
import 'package:kalium_wallet_flutter/model/vault.dart';

class IntroBackupConfirm extends StatefulWidget {
  @override
  _IntroBackupConfirmState createState() => _IntroBackupConfirmState();
}

class _IntroBackupConfirmState extends State<IntroBackupConfirm> {
  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      key: _scaffoldKey,
      backgroundColor: StateContainer.of(context).curTheme.backgroundDark,
      body: LayoutBuilder(
        builder: (context, constraints) => Column(
              children: <Widget>[
                //A widget that holds the header, the paragraph and Back Button
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(
                        vertical: MediaQuery.of(context).size.height * 0.075),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            // Back Button
                            Container(
                              margin: EdgeInsets.only(left: 20),
                              height: 50,
                              width: 50,
                              child: FlatButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(50.0)),
                                  padding: EdgeInsets.all(0.0),
                                  child: Icon(AppIcons.back,
                                      color: StateContainer.of(context).curTheme.text, size: 24)),
                            ),
                          ],
                        ),
                        // The header
                        Container(
                          margin: EdgeInsets.only(top: 15.0, left: 50),
                          alignment: Alignment(-1, 0),
                          child: Text(
                            AppLocalization.of(context).backupYourSeed,
                            style: AppStyles.textStyleHeaderColored(context),
                          ),
                        ),
                        // The paragraph
                        Container(
                          margin:
                              EdgeInsets.only(left: 50, right: 50, top: 15.0),
                          child: Text(
                              AppLocalization.of(context).backupSeedConfirm,
                              style: AppStyles.textStyleParagraph(context)),
                        ),
                      ],
                    ),
                  ),
                ),

               //A column with YES and NO buttons
                Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        // YES Button
                        AppButton.buildAppButton(context, 
                            AppButtonType.PRIMARY,
                            AppLocalization.of(context).yes.toUpperCase(),
                            Dimens.BUTTON_TOP_DIMENS, 
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) {
                              return new PinScreen(PinOverlayType.NEW_PIN, (_pinEnteredCallback));
                            }));
                        }),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        // NO BUTTON
                        AppButton.buildAppButton(context, 
                            AppButtonType.PRIMARY_OUTLINE,
                            AppLocalization.of(context).no.toUpperCase(),
                            Dimens.BUTTON_BOTTOM_DIMENS, onPressed: () {
                              Navigator.of(context).pop();
                        }),
                      ],
                    ),
                  ],
                ),
              ],
            ),
      ),
    );
  }

  void _pinEnteredCallback(String pin) {
    Navigator.of(context).pop();
    SharedPrefsUtil.inst.setSeedBackedUp(true).then((result) {
      Vault.inst.writePin(pin).then((result) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
      });
    });
  }
}