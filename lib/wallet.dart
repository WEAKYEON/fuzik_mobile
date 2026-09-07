import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'wallet_api.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  static const Color _cardColor = Color(0xFF1B1B1B);

  final WalletApi _api = WalletApi();
  late Future<List<CoinPack>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<List<CoinPack>> _load() async {
    final results = await Future.wait([_api.fetchSummary(), _api.fetchPacks()]);
    return results[1] as List<CoinPack>;
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  Future<void> _openPayment() async {
    final uri = Uri.parse('https://tetrasolution.com/paysolution/payment');
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the payment page.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.yellow,
      backgroundColor: _cardColor,
      onRefresh: _refresh,
      child: FutureBuilder<List<CoinPack>>(
        future: _future,
        builder: (context, snapshot) {
          final packs = snapshot.data ?? WalletApi.defaultPacks;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wallet',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Manage your coins and buy more when you need them.',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 28),

                _buildBalanceSection(),
                const SizedBox(height: 32),

                const Text(
                  'Buy coins',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                ...packs.map(
                  (pack) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildPackageCard(
                      pack: pack,
                      onBuy: _openPayment,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceSection() {
    return ValueListenableBuilder<WalletSummary?>(
      valueListenable: walletSummaryNotifier,
      builder: (context, summary, _) {
        final freeAmount = summary?.freeBalance != null
            ? '${summary!.freeBalance}'
            : '—';
        final paidAmount = summary?.paidBalance != null
            ? '${summary!.paidBalance}'
            : '—';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildBalanceCard(
                badge: 'FZ',
                badgeColor: Colors.yellow,
                badgeTextColor: Colors.black,
                label: 'Free',
                amount: freeAmount,
                footer: 'Next coin in —',
                footerColor: Colors.yellow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBalanceCard(
                badge: 'PR',
                badgeColor: const Color(0xFF1E3A8A),
                badgeTextColor: Colors.white,
                label: 'Paid',
                amount: paidAmount,
                footer: 'See packs ↓',
                footerColor: const Color(0xFF60A5FA),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceCard({
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required String label,
    required String amount,
    required String footer,
    required Color footerColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(footer, style: TextStyle(color: footerColor, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPackageCard({
    required CoinPack pack,
    required VoidCallback onBuy,
  }) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: pack.featured
            ? Border.all(color: Colors.yellow, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pack.name,
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  pack.coinsLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '฿${pack.price}',
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: ' THB',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: onBuy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Buy',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!pack.featured) return card;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(padding: const EdgeInsets.only(top: 10), child: card),
        Positioned(
          left: 16,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.yellow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Best value',
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
