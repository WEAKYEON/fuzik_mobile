import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'paysolution.dart';
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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;
  final GlobalKey _packsSectionKey = GlobalKey();
  double? _usdRate;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOffline = results.every((r) => r == ConnectivityResult.none);
    if (_wasOffline && !isOffline) _refresh();
    _wasOffline = isOffline;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _api.dispose();
    super.dispose();
  }

  Future<List<CoinPack>> _load() async {
    final results = await Future.wait([
      _api.fetchSummary(),
      _api.fetchPacks(),
      _api.fetchUsdRate(),
    ]);
    if (mounted) {
      setState(() => _usdRate = results[2] as double?);
    }
    return results[1] as List<CoinPack>;
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  void _scrollToPacks() {
    final context = _packsSectionKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _openPaySolution(CoinPack pack) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaySolution(pack: pack),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.yellow,
          backgroundColor: _cardColor,
          onRefresh: _refresh,
          child: FutureBuilder<List<CoinPack>>(
            future: _future,
            builder: (context, snapshot) {
              //final packs = snapshot.data ?? WalletApi.defaultPacks;

              final packs = List<CoinPack>.from(
              snapshot.data ?? WalletApi.defaultPacks,
              )..sort((a, b) => a.price.compareTo(b.price));

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
                      'Manage your coins, see ways to earn, and check your activity history.',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                    const SizedBox(height: 28),

                    _buildBalanceSection(),
                    const SizedBox(height: 32),

                    Text(
                      'Buy coins',
                      key: _packsSectionKey,
                      style: const TextStyle(
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
                          onBuy: () => _openPaySolution(pack),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
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

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildBalanceCard(
                  badge: 'PR',
                  badgeColor: Colors.yellow,
                  badgeTextColor: Colors.black,
                  label: 'Paid',
                  amount: paidAmount,
                  footer: _buildSeePacksButton(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBalanceCard(
                  badge: 'FZ',
                  badgeColor: const Color(0xFF8AB4F8),
                  badgeTextColor: Colors.black,
                  label: 'Free',
                  amount: freeAmount,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeePacksButton() {
    return OutlinedButton(
      onPressed: _scrollToPacks,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF60A5FA),
        side: const BorderSide(color: Color(0xFF60A5FA)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: const Text(
        'See packs ↓',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBalanceCard({
    required String badge,
    required Color badgeColor,
    required Color badgeTextColor,
    required String label,
    required String amount,
    Widget? footer,
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
          if (footer != null) ...[
            const SizedBox(height: 6),
            footer,
          ],
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
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    children: [
                      TextSpan(text: '${pack.baseCoins}'),
                      if (pack.bonusCoins > 0)
                        TextSpan(
                          text: ' + ${pack.bonusCoins}',
                          style: const TextStyle(color: Color(0xFF4ADE80)),
                        ),
                      const TextSpan(text: ' Coins'),
                    ],
                  ),
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
              if (usdEstimate(pack, _usdRate) != null)
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    children: [
                      TextSpan(text: '≈ \$${usdEstimate(pack, _usdRate)} USD '),
                      const TextSpan(
                        text: '(estimated)',
                        style: TextStyle(color: Colors.white38),
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
