import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/config/api_config.dart';

enum CheckoutResult { completed, cancelled, failed }

/// Hosts the Pesapal checkout inside the app. When the user is redirected
/// back to the plugin's `return_url`, we pop with [CheckoutResult.completed]
/// so the caller can start polling /access/order-status.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.url,
    required this.reference,
  });

  final String url;
  final String reference;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final WebViewController _controller;
  bool _returned = false;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onNavigationRequest: (req) {
            if (_isReturnUrl(req.url)) {
              _finish(CheckoutResult.completed);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (err) {
            // Ignore minor subresource errors; only fail on main frame.
            if (err.isForMainFrame ?? false) {
              _finish(CheckoutResult.failed);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  bool _isReturnUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final returnUri = Uri.parse(ApiConfig.paymentReturnUrl);
    // Match host and (optionally) path.
    if (uri.host != returnUri.host) return false;
    if (returnUri.path.isNotEmpty && uri.path.startsWith(returnUri.path)) {
      return true;
    }
    return false;
  }

  void _finish(CheckoutResult result) {
    if (_returned) return;
    _returned = true;
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _finish(CheckoutResult.cancelled),
        ),
        title: const Text('Complete Payment'),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}