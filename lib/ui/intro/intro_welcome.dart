import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/styles.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:flare_flutter/flare_actor.dart';

class IntroWelcomePage extends StatefulWidget {
  @override
  _IntroWelcomePageState createState() => _IntroWelcomePageState();
}

class _IntroWelcomePageState extends State<IntroWelcomePage> {
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
                //A widget that holds welcome animation + paragraph
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        //Container for the animation
                        Container(
                          //Width/Height ratio for the animation is needed because BoxFit is not working as expected
                          width: double.infinity,
                          height: MediaQuery.of(context).size.width * 5 / 8,
                          child: Stack(
                            children: <Widget>[
                              Center(
                                child: FlareActor(
                                  "assets/welcome_animation_bananasonly.flr",
                                  animation: "main",
                                  fit: BoxFit.contain,
                                  color: StateContainer.of(context).curTheme.primary,
                                ),
                              ),
                              Center(
                                child: FlareActor(
                                  "assets/welcome_animation_monkeysonly.flr",
                                  animation: "main",
                                  fit: BoxFit.contain,
                                ),
                              )
                            ],
                          ),
                        ),
                        //Container for the paragraph
                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 20),
                          child: Text(
                            AppLocalization.of(context).welcomeText,
                            style: AppStyles.textStyleParagraph(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                //A column with "New Wallet" and "Import Wallet" buttons
                Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        // New Wallet Button
                        AppButton.buildAppButton(
                            context,
                            AppButtonType.PRIMARY,
                            AppLocalization.of(context).newWallet,
                            Dimens.BUTTON_TOP_DIMENS, onPressed: () {
                          Navigator.of(context).pushNamed('/intro_backup');
                        }),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        // Import Wallet Button
                        AppButton.buildAppButton(
                            context,
                            AppButtonType.PRIMARY_OUTLINE,
                            AppLocalization.of(context).importWallet,
                            Dimens.BUTTON_BOTTOM_DIMENS, onPressed: () {
                          Navigator.of(context).pushNamed('/intro_import');
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
}
