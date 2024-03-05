import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kalium_wallet_flutter/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:kalium_wallet_flutter/dimens.dart';
import 'package:kalium_wallet_flutter/service_locator.dart';
import 'package:kalium_wallet_flutter/ui/widgets/buttons.dart';
import 'package:kalium_wallet_flutter/ui/widgets/sheets.dart';
import 'package:kalium_wallet_flutter/ui/util/ui_util.dart';
import 'package:kalium_wallet_flutter/ui/receive/share_card.dart';
import 'package:kalium_wallet_flutter/model/wallet.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as Math;

import 'package:share_plus/share_plus.dart';

class ReceiveSheet extends StatefulWidget {
  final Widget qrWidget;

  ReceiveSheet({this.qrWidget}) : super();

  _ReceiveSheetStateState createState() => _ReceiveSheetStateState();
}

class _ReceiveSheetStateState extends State<ReceiveSheet> {
  GlobalKey shareCardKey;
  ByteData shareImageData;

  // Address copied items
  // Current state references
  bool _showShareCard;
  bool _addressCopied;
  // Timer reference so we can cancel repeated events
  Timer _addressCopiedTimer;

  Future<Uint8List> _capturePng() async {
    if (shareCardKey != null && shareCardKey.currentContext != null) {
      RenderRepaintBoundary boundary =
          shareCardKey.currentContext.findRenderObject();
      ui.Image image = await boundary.toImage(pixelRatio: 5.0);
      ByteData byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData.buffer.asUint8List();
    } else {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Set initial state of copy button
    _addressCopied = false;
    // Create our SVG-heavy things in the constructor because they are slower operations
    // Share card initialization
    shareCardKey = GlobalKey();
    _showShareCard = false;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum:
          EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.035),
      child: Column(
        children: <Widget>[
          // A row for the address text and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              //Empty SizedBox
              SizedBox(
                width: 60,
                height: 60,
              ),
              //Container for the address text and sheet handle
              Column(
                children: <Widget>[
                  // Sheet handle
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    height: 5,
                    width: MediaQuery.of(context).size.width * 0.15,
                    decoration: BoxDecoration(
                      color: StateContainer.of(context).curTheme.text10,
                      borderRadius: BorderRadius.circular(100.0),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 15.0),
                    child: sl.get<UIUtil>().threeLineAddressText(
                        context, StateContainer.of(context).wallet.address,
                        type: ThreeLineAddressTextType.PRIMARY60),
                  ),
                ],
              ),
              //Empty SizedBox
              SizedBox(
                width: 60,
                height: 60,
              ),
            ],
          ),

          //MonkeyQR which takes all the available space left from the buttons & address text
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(
                      top: 20, bottom: 28, start: 20, end: 20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double availableWidth = constraints.maxWidth;
                      double availableHeight = constraints.maxHeight;
                      double widthDivideFactor = 1.3;
                      double computedMaxSize = Math.min(
                          availableWidth / widthDivideFactor, availableHeight);
                      return Center(
                        child: Stack(
                          children: <Widget>[
                            _showShareCard
                                ? Container(
                                    child: AppShareCard(
                                        shareCardKey,
                                        SvgPicture.asset(
                                            'assets/monkeyQR.svg')),
                                    alignment: AlignmentDirectional(0.0, 0.0),
                                  )
                                : SizedBox(),
                            // This is for hiding the share card
                            Center(
                              child: Container(
                                width: 260,
                                height: 150,
                                color: StateContainer.of(context)
                                    .curTheme
                                    .backgroundDark,
                              ),
                            ),
                            // Background/border part the monkeyQR
                            Center(
                              child: Container(
                                width: computedMaxSize,
                                height: computedMaxSize,
                                child: SvgPicture.asset('assets/monkeyQR.svg'),
                              ),
                            ),
                            // Actual QR part of the monkeyQR
                            Center(
                              child: Container(
                                margin: EdgeInsets.only(
                                  top: computedMaxSize / 4.27,
                                ),
                                width: computedMaxSize / 2.2,
                                child: widget.qrWidget,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          //A column with Copy Address and Share Address buttons
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  AppButton.buildAppButton(
                      context,
                      // Share Address Button
                      _addressCopied
                          ? AppButtonType.SUCCESS
                          : AppButtonType.PRIMARY,
                      _addressCopied
                          ? AppLocalization.of(context).addressCopied
                          : AppLocalization.of(context).copyAddress,
                      Dimens.BUTTON_TOP_DIMENS, onPressed: () {
                    Clipboard.setData(new ClipboardData(
                        text: StateContainer.of(context).wallet.address));
                    setState(() {
                      // Set copied style
                      _addressCopied = true;
                    });
                    if (_addressCopiedTimer != null) {
                      _addressCopiedTimer.cancel();
                    }
                    _addressCopiedTimer =
                        new Timer(const Duration(milliseconds: 800), () {
                      if (mounted) {
                        setState(() {
                          _addressCopied = false;
                        });
                      }
                    });
                  }),
                ],
              ),
              Row(
                children: <Widget>[
                  AppButton.buildAppButton(
                    context,
                    // Share Address Button
                    AppButtonType.PRIMARY_OUTLINE,
                    AppLocalization.of(context).addressShare,
                    Dimens.BUTTON_BOTTOM_DIMENS,
                    disabled: _showShareCard,
                    onPressed: () {
                      String receiveCardFileName =
                          "share_${StateContainer.of(context).wallet.address}.png";
                      getApplicationDocumentsDirectory().then((directory) {
                        String filePath =
                            "${directory.path}/$receiveCardFileName";
                        File f = File(filePath);
                        setState(() {
                          _showShareCard = true;
                        });
                        Future.delayed(new Duration(milliseconds: 50), () {
                          if (_showShareCard) {
                            _capturePng().then((byteData) {
                              if (byteData != null) {
                                f.writeAsBytes(byteData).then((file) {
                                  sl.get<UIUtil>().cancelLockEvent();
                                  List<XFile> filesToShare = [XFile(file.path)];
                                  Share.shareXFiles(filesToShare,
                                      text: StateContainer.of(context)
                                          .wallet
                                          .address);
                                });
                              } else {
                                // TODO - show a something went wrong message
                              }
                              setState(() {
                                _showShareCard = false;
                              });
                            });
                          }
                        });
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
