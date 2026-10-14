import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../api/providers.dart';
import '../../widgets/feedback.dart';

/// PayPal approval page in a web view. When PayPal redirects to [returnUrl] the order is captured on the server;
/// the screen closes with `true` after a successful payment and with `false` when the user cancels.
class PayPalCheckoutScreen extends StatefulWidget {
  // Never loaded: the web view intercepts these redirects.
  static const returnUrl = 'https://f1infotickets.app/paypal/return';
  static const cancelUrl = 'https://f1infotickets.app/paypal/cancel';

  final String approvalUrl;
  final String orderId;

  const PayPalCheckoutScreen({super.key, required this.approvalUrl, required this.orderId});

  @override
  State<PayPalCheckoutScreen> createState() => _PayPalCheckoutScreenState();
}

class _PayPalCheckoutScreenState extends State<PayPalCheckoutScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onNavigationRequest: (request) {
            if (request.url.startsWith(PayPalCheckoutScreen.returnUrl)) {
              _capture();
              return NavigationDecision.prevent;
            }
            if (request.url.startsWith(PayPalCheckoutScreen.cancelUrl)) {
              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    _open();
  }

  /// Clears the previous PayPal session so the buyer always signs in with the account they choose.
  Future<void> _open() async {
    await WebViewCookieManager().clearCookies();
    await _controller.loadRequest(Uri.parse(widget.approvalUrl));
  }

  Future<void> _capture() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      await PaymentProvider().capture(widget.orderId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showError(context, e);
      Navigator.pop(context, false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await confirmAction(
      context,
      title: 'Cancel payment',
      message: 'Leave PayPal without paying? Your cart stays as it is.',
      confirmLabel: 'Leave',
      destructive: true,
    );
    if (confirmed && mounted) Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_capturing) _cancel();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PayPal'),
          leading: IconButton(tooltip: 'Close', icon: const Icon(Icons.close), onPressed: _capturing ? null : _cancel),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _progress < 100 || _capturing
                ? LinearProgressIndicator(value: _capturing ? null : _progress / 100)
                : const SizedBox(height: 3),
          ),
        ),
        body: _capturing
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Completing your payment...')],
                ),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}
