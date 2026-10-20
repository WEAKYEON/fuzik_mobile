import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'paysolution_webview.dart';
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

  late final String _referenceNumber;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _referenceNumber = _generateRefno();
  }

  static String _generateRefno() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (100 + Random().nextInt(900)).toString();
    final combined = '$timestamp$random';
    final last12 = combined.substring(combined.length - 12);
    return last12.padLeft(12, '0');
  }

  Future<void> _submitPayment() async {
    if (_submitting) return;
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) return;

    setState(() => _submitting = true);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaySolutionCheckout(
          pack: widget.pack,
          refno: _referenceNumber,
          customerEmail: email,
        ),
      ),
    );
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: _buildSummary(),
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
        _buildPrimaryButton(
          _submitting ? 'Redirecting…' : 'Confirm Purchase',
          _submitting ? null : _submitPayment,
        ),
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

  Widget _buildPrimaryButton(String label, VoidCallback? onPressed) {
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
