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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final body = Uri(
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
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(
        Uri.parse(PaySolutionCheckout.gatewayUrl),
        method: LoadRequestMethod.post,
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: utf8.encode(body),
      );
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
          if (_loading) const Center(child: CircularProgressIndicator(color: Colors.yellow)),
        ],
      ),
    );
  }
}
