import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'wallet_api.dart';

class PaySolutionCheckout extends StatefulWidget {
  final CoinPack pack;
  final String refno;
  final String customerEmail;

  const PaySolutionCheckout({
    super.key,
    required this.pack,
    required this.refno,
    required this.customerEmail,
  });

  static const String gatewayUrl = 'https://payments.paysolutions.asia/payment';
  static const String merchantId = '68347300';
  static const String currencyCode = '00';
  static const String lang = 'EN';

  @override
  State<PaySolutionCheckout> createState() => _PaySolutionCheckoutState();
}

class _PaySolutionCheckoutState extends State<PaySolutionCheckout> {
  late final WebViewController _controller;
  late final String _requestBody;
  bool _loading = true;
  bool _completed = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _requestBody = Uri(
      queryParameters: {
        'customeremail': widget.customerEmail,
        'productdetail': 'coin-pack-${widget.pack.code}',
        'refno': widget.refno,
        'merchantid': PaySolutionCheckout.merchantId,
        'cc': PaySolutionCheckout.currencyCode,
        'total': '${widget.pack.price}',
        'lang': PaySolutionCheckout.lang,
      },
    ).query;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _loading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              setState(() {
                _loading = false;
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (request) {
            final host = Uri.tryParse(request.url)?.host ?? '';
            if (host.endsWith('paysolutions.asia')) {
              return NavigationDecision.navigate;
            }
            _finish();
            return NavigationDecision.prevent;
          },
        ),
      );
    _load();
  }

  void _load() {
    _controller.loadRequest(
      Uri.parse(PaySolutionCheckout.gatewayUrl),
      method: LoadRequestMethod.post,
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
      body: utf8.encode(_requestBody),
    );
  }

  void _retry() {
    setState(() => _hasError = false);
    _load();
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B1B1B),
        foregroundColor: Colors.white,
        title: const Text('Payment'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading && !_hasError)
            const Center(
              child: CircularProgressIndicator(color: Colors.yellow),
            ),
          if (_hasError) _buildErrorOverlay(),
        ],
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: Colors.white54, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Connection problem',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We could not reach the payment gateway. Check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      elevation: 0,
                    ),
                    child: const Text('Try Again'),
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
