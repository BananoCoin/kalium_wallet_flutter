import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:kalium_wallet_flutter/ui/widgets/auto_resize_text.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AppShareCard extends StatefulWidget {
  final GlobalKey key;
  final Widget monkeySvg;

  AppShareCard(this.key, this.monkeySvg);

  @override
  _AppShareCardState createState() => _AppShareCardState(key, monkeySvg);
}

class _AppShareCardState extends State<AppShareCard> {
  GlobalKey globalKey;
  Widget monkeySvg;

  _AppShareCardState(this.globalKey, this.monkeySvg);

  @override
  Widget build(BuildContext context) {
    double addressTextSize = 9.8;
    double addressLineHeight = 1.2;
    return RepaintBoundary(
      key: globalKey,
      child: Container(
        height: 125,
        width: 241,
        decoration: BoxDecoration(
          color: StateContainer.of(context).curTheme.backgroundDark,
          borderRadius: BorderRadius.circular(12.5),
        ),
        child: Container(
          margin: EdgeInsets.only(left: 12.5, right: 12.5, top: 12.5),
          constraints: BoxConstraints.expand(),
          // The main row that holds monkeyQR, logo, the address, ticker and the website text
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // A container for monkeyQR
              Container(
                margin: EdgeInsets.only(bottom: 12.5),
                width: 105,
                height: 105,
                child: Stack(
                  children: <Widget>[
                    // Background/border part of monkeyQR
                    Center(
                      child: Container(
                        width: 105,
                        height: 105,
                        child: monkeySvg,
                      ),
                    ),
                    // Actual QR part of the monkeyQR
                    Center(
                      child: Container(
                        margin: EdgeInsets.only(top: 23.5),
                        child: QrImage(
                          padding: EdgeInsets.all(0.0),
                          size: 45.5,
                          data: StateContainer.of(context).wallet.address,
                          version: 6,
                          errorCorrectionLevel: QrErrorCorrectLevel.Q,
                          gapless: false,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // A column for logo, address, ticker and website text
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Logo
                  Container(
                    width: 97,
                    child: RichText(
                      maxLines: 1,
                      text: TextSpan(
                        children: [
                          // Currency Icon
                          TextSpan(
                            text: "\u{e801} ",
                            style: TextStyle(
                              color:
                                  StateContainer.of(context).curTheme.primary,
                              fontFamily: "AppIcons",
                              fontWeight: FontWeight.w400,
                              fontSize: 14.8,
                            ),
                          ),
                          TextSpan(
                            text: "BANANO",
                            style: TextStyle(
                              fontFamily: 'NeueHansKendrick',
                              color:
                                  StateContainer.of(context).curTheme.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Address
                  Container(
                    width: 97,
                    padding: EdgeInsets.only(bottom: 6),
                    alignment: AlignmentDirectional.centerStart,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        // First row of the address
                        RichText(
                          text: TextSpan(
                            children: [
                              // Primary part of the first row
                              TextSpan(
                                text: StateContainer.of(context)
                                    .wallet
                                    .address
                                    .substring(0, 11),
                                style: TextStyle(
                                  color: StateContainer.of(context)
                                      .curTheme
                                      .primary,
                                  fontFamily: "OverpassMono",
                                  fontWeight: FontWeight.w100,
                                  fontSize: addressTextSize,
                                  height: addressLineHeight,
                                ),
                              ),
                              TextSpan(
                                text: StateContainer.of(context)
                                    .wallet
                                    .address
                                    .substring(11, 16),
                                style: TextStyle(
                                  color:
                                      StateContainer.of(context).curTheme.text,
                                  fontFamily: "OverpassMono",
                                  fontWeight: FontWeight.w100,
                                  fontSize: addressTextSize,
                                  height: addressLineHeight,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                        ),
                        // Second row of the address
                        RichText(
                          text: TextSpan(
                            text: StateContainer.of(context)
                                .wallet
                                .address
                                .substring(16, 32),
                            style: TextStyle(
                              color: StateContainer.of(context).curTheme.text,
                              fontFamily: "OverpassMono",
                              fontWeight: FontWeight.w100,
                              fontSize: addressTextSize,
                              height: addressLineHeight,
                            ),
                          ),
                          maxLines: 1,
                        ),
                        // Third row of the address
                        RichText(
                          text: TextSpan(
                            text: StateContainer.of(context)
                                .wallet
                                .address
                                .substring(32, 48),
                            style: TextStyle(
                              color: StateContainer.of(context).curTheme.text,
                              fontFamily: "OverpassMono",
                              fontWeight: FontWeight.w100,
                              fontSize: addressTextSize,
                              height: addressLineHeight,
                            ),
                          ),
                          maxLines: 1,
                        ),
                        // Fourth(last) row of the address
                        RichText(
                          text: TextSpan(
                            children: [
                              // Text colored part of the last row
                              TextSpan(
                                text: StateContainer.of(context)
                                    .wallet
                                    .address
                                    .substring(48, 58),
                                style: TextStyle(
                                  color:
                                      StateContainer.of(context).curTheme.text,
                                  fontFamily: "OverpassMono",
                                  fontWeight: FontWeight.w100,
                                  fontSize: addressTextSize,
                                  height: addressLineHeight,
                                ),
                              ),
                              // Primary colored part of the last row
                              TextSpan(
                                text: StateContainer.of(context)
                                    .wallet
                                    .address
                                    .substring(58, 64),
                                style: TextStyle(
                                  color: StateContainer.of(context)
                                      .curTheme
                                      .primary,
                                  fontFamily: "OverpassMono",
                                  fontWeight: FontWeight.w100,
                                  fontSize: addressTextSize,
                                  height: addressLineHeight,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  // Ticker & Website
                  Container(
                    width: 97,
                    margin: EdgeInsets.only(bottom: 12),
                    child: AutoSizeText(
                      "\$BAN      BANANO.CC",
                      minFontSize: 1.0,
                      stepGranularity: 0.1,
                      maxLines: 1,
                      style: TextStyle(
                        color: StateContainer.of(context).curTheme.primary,
                        fontFamily: "NeueHansKendrick",
                        fontWeight: FontWeight.w500,
                      ),
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
}
