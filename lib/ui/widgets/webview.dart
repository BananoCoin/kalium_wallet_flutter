import 'package:flutter/material.dart';
import 'package:kalium_wallet_flutter/appstate_container.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewDisplayScreen extends StatefulWidget {
  final String url;

  const WebviewDisplayScreen({Key key, @required this.url}) : super(key: key);

  @override
  _WebviewDisplayScreenState createState() => _WebviewDisplayScreenState();
}

class _WebviewDisplayScreenState extends State<WebviewDisplayScreen> {
  WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: StateContainer.of(context).curTheme.backgroundDark,
        brightness: StateContainer.of(context).curTheme.brightness,
        iconTheme:
            IconThemeData(color: StateContainer.of(context).curTheme.text),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
