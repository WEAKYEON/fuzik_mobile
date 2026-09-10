import 'package:flutter/material.dart';

import 'wallet_api.dart';

class PaySolution extends StatefulWidget {
  final CoinPack pack;

  const PaySolution({super.key, required this.pack});

  @override
  State<PaySolution> createState() => _PaySolutionState();
}

class _PaySolutionState extends State<PaySolution> {
  static const Color _cardColor = Color(0xFF1B1B1B);
  static const Color _borderColor = Color(0xFF27272A);

  static const Map<String, String> _referenceNumbers = {
    'test': '000000000004',
    'adagio': '000000000001',
    'allegro': '000000000002',
    'presto': '000000000003',
  };

  bool _confirmed = false;

  String get _referenceNumber =>
      _referenceNumbers[widget.pack.code] ?? '000000000000';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: _confirmed ? _buildSuccess() : _buildSummary(),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBackButton(),
        const SizedBox(height: 28),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              _buildRow('Reference No.', _referenceNumber),
              const Divider(color: _borderColor, height: 1),
              _buildRow('Product', widget.pack.name),
              const Divider(color: _borderColor, height: 1),
              _buildRow('Coins', widget.pack.coinsLabel),
              const Divider(color: _borderColor, height: 1),
              _buildRow('Amount', '฿${widget.pack.price} THB', emphasize: true),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _buildPrimaryButton('Confirm Purchase', () {
          setState(() => _confirmed = true);
        }),
        const SizedBox(height: 16),
        const Text(
          'Coins are added to your PR balance instantly after payment. '
          'Purchases are non-refundable.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const SizedBox(height: 72),
        const Icon(Icons.check_circle, color: Color(0xFF4ADE80), size: 72),
        const SizedBox(height: 20),
        const Text(
          'Payment successful',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$_referenceNumber · ฿${widget.pack.price} THB',
          style: const TextStyle(color: Colors.white54, fontSize: 14),
        ),
        const SizedBox(height: 44),
        _buildPrimaryButton('Back to Wallet', () {
          Navigator.pop(context);
        }),
      ],
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Row(
        children: const [
          Icon(Icons.arrow_back, color: Colors.white, size: 26),
          SizedBox(width: 8),
          Text(
            'Payment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: emphasize ? Colors.white : Colors.white54,
              fontSize: 14,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasize ? Colors.yellow : Colors.white,
              fontSize: emphasize ? 18 : 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.yellow,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
