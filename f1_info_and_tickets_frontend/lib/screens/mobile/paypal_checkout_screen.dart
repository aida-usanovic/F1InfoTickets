import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../api/providers.dart';
import '../../core/api_exception.dart';
import '../../widgets/feedback.dart';

/// How the PayPal checkout ended; returned by [PayPalCheckoutScreen].
sealed class PayPalOutcome {
  const PayPalOutcome();
}

/// The order was captured and the tickets were created.
class PayPalPaid extends PayPalOutcome {
  const PayPalPaid();
}

/// The user left PayPal without paying.
class PayPalCancelled extends PayPalOutcome {
  const PayPalCancelled();
}

/// PayPal could not be opened or the payment could not be completed; [error] carries the server's message.
class PayPalFailed extends PayPalOutcome {
  final Object error;

  const PayPalFailed(this.error);
}

/// PayPal approval page in a web view. When PayPal redirects to [returnUrl] the order is captured on the server;
/// the screen closes with a [PayPalOutcome].
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
              Navigator.pop(context, const PayPalCancelled());
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame != true || _capturing || !mounted) return;
            Navigator.pop(
              context,
              PayPalFailed(ApiException('The PayPal page could not be opened. Check your internet connection and try again.')),
            );
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
      if (mounted) Navigator.pop(context, const PayPalPaid());
    } catch (e) {
      // The cart screen shows the message, so it is not lost when this screen closes.
      if (mounted) Navigator.pop(context, PayPalFailed(e));
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
    if (confirmed && mounted) Navigator.pop(context, const PayPalCancelled());
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
