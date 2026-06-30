import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TurnstileWidget extends StatefulWidget {
  const TurnstileWidget({
    super.key,
    required this.siteKey,
    this.onTokenChanged,
    this.resetKey = 0,
  });

  final String siteKey;
  final ValueChanged<String?>? onTokenChanged;
  final int resetKey;

  @override
  State<TurnstileWidget> createState() => _TurnstileWidgetState();
}

class _TurnstileWidgetState extends State<TurnstileWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'TurnstileChannel',
        onMessageReceived: (message) {
          final token = message.message.trim();
          widget.onTokenChanged?.call(token.isEmpty ? null : token);
        },
      )
      ..loadHtmlString(_buildHtml(widget.siteKey));
  }

  @override
  void didUpdateWidget(covariant TurnstileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.siteKey != widget.siteKey || oldWidget.resetKey != widget.resetKey) {
      widget.onTokenChanged?.call(null);
      _controller.loadHtmlString(_buildHtml(widget.siteKey));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }

  String _buildHtml(String siteKey) {
  final escapedKey = siteKey.replaceAll("'", "\\'");
  return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <script src="https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onTurnstileLoad" async defer></script>
    <style>
      html, body { margin: 0; padding: 0; background: transparent; }
      #turnstile { display: flex; justify-content: center; align-items: center; min-height: 70px; }
    </style>
  </head>
  <body>
    <div id="turnstile"></div>
    <script>
      function postToken(token) {
        if (window.TurnstileChannel) {
          TurnstileChannel.postMessage(token || '');
        }
      }
      function onTurnstileLoad() {
        turnstile.render('#turnstile', {
          sitekey: '$escapedKey',
          theme: 'light',
          callback: function(token) { postToken(token); },
          'expired-callback': function() { postToken(''); },
          'error-callback': function() { postToken(''); }
        });
      }
    </script>
  </body>
</html>
''';
  }
}
