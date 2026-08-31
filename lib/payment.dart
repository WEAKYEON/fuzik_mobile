import 'package:flutter/material.dart';

import 'wallet_api.dart';

class Payment extends StatefulWidget {
  final WalletApi api;
  final String email;
  final CoinPack pack;

  const Payment({
    super.key,
    required this.api,
    required this.email,
    required this.pack,
  });

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  String _selectedPayment = 'card';
  bool _submitting = false;

  final List<Map<String, String>> _paymentMethods = WalletApi.paymentMethods;

  Future<void> _confirmPurchase() async {
    setState(() => _submitting = true);
    try {
      await widget.api.purchaseCoinPackage(
        email: widget.email,
        packCode: widget.pack.code,
        paymentMethod: _selectedPayment,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase successful.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.yellow,
            size: 32,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Package summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B1B),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.yellow,
                    width: 3,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pack.name,
                            style: const TextStyle(
                              color: Colors.yellow,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            widget.pack.coinsLabel.toLowerCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      '฿${widget.pack.price}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Payment method title
              const Text(
                'Payment method',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Payment methods
              ..._paymentMethods.map(_buildPaymentMethod),

              const SizedBox(height: 28),

              // Divider
              const Divider(
                color: Colors.white24,
                thickness: 1,
              ),

              const SizedBox(height: 36),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 22,
                    ),
                  ),

                  Text(
                    '฿${widget.pack.price} THB',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 42),

              // Confirm purchase button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _confirmPurchase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.yellow.withValues(
                      alpha: 0.5,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Confirm Purchase',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Disclaimer
              const Center(
                child: Text(
                  'Coins are added to your PR balance instantly after payment. '
                  'Purchases are non-refundable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(Map<String, String> method) {
    final String code = method['code']!;
    final String label = method['label']!;
    final bool isSelected = _selectedPayment == code;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPayment = code;
        });
      },
      child: Container(
        width: double.infinity,
        height: 100,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Colors.yellow
                : Colors.white12,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.yellow
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Colors.yellow
                      : Colors.white24,
                  width: 4,
                ),
              ),
            ),

            const SizedBox(width: 28),

            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}