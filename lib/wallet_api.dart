import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

final ValueNotifier<WalletSummary?> walletSummaryNotifier =
    ValueNotifier<WalletSummary?>(null);

class CoinPack {
  final String code;
  final String name;
  final String coinsLabel;
  final int price;
  final bool featured;

  const CoinPack({
    required this.code,
    required this.name,
    required this.coinsLabel,
    required this.price,
    this.featured = false,
  });

  factory CoinPack.fromJson(Map<String, dynamic> json) {
    return CoinPack(
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      coinsLabel: (json['coinsLabel'] ?? json['coins_label'] ?? '').toString(),
      price: int.tryParse((json['price'] ?? 0).toString()) ?? 0,
      featured: json['featured'] == true,
    );
  }
}

class WalletSummary {
  final int? freeBalance;
  final int? freeCap;
  final int? paidBalance;

  const WalletSummary({this.freeBalance, this.freeCap, this.paidBalance});
}

class CollaborationQueueCharge {
  final bool success;
  final String? error;

  const CollaborationQueueCharge({
    required this.success,
    this.error,
  });
}

class WalletApi {
  WalletApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 20);
  static const int freeCap = 200;
  static const int collaborationQueueFee = 120;
  static const String _depositEmail = 'omiesensei@gmail.com';
  static const String _activitiesEmail = 'ohm@tetrasolution.com';

  static const List<CoinPack> defaultPacks = [
    CoinPack(code: 'test', name: 'Test Pack', coinsLabel: '1 Coins', price: 2),
    CoinPack(code: 'adagio', name: 'Adagio Pack', coinsLabel: '50 Coins', price: 99),
    CoinPack(
      code: 'allegro',
      name: 'Allegro Pack',
      coinsLabel: '90 + 10 Coins',
      price: 169,
    ),
    CoinPack(
      code: 'presto',
      name: 'Presto Pack',
      coinsLabel: '170 + 30 Coins',
      price: 269,
      featured: true,
    ),
  ];

  String get _engineUrl =>
      (dotenv.env['ENGINE_URL'] ?? 'https://engine01.fuzikapp.com')
          .replaceAll(RegExp(r'/+$'), '');

  String get _realmFree => dotenv.env['REALM_FREE'] ?? 'REALM00000002';

  String get _realmPaid => dotenv.env['REALM_PAID'] ?? 'REALM00000001';

  String? get currentEmail => Supabase.instance.client.auth.currentUser?.email;

  Future<int?> _tokenBalance(String realmId, String email) async {
    final uri = Uri.parse('$_engineUrl/check_balance').replace(
      queryParameters: {
        'q': 'a',
        'realm_id': realmId,
        'email_account': email,
      },
    );
    final res = await _client.get(uri).timeout(_timeout);
    if (res.statusCode != 200) return null;
    final body = json.decode(res.body);
    if (body is Map && body['balance'] != null) {
      final raw = body['balance'].toString().split(' ').first;
      return int.tryParse(raw) ?? double.tryParse(raw)?.toInt();
    }
    return null;
  }

  Future<WalletSummary> fetchSummary() async {
    final email = currentEmail;
    if (email == null || email.isEmpty) {
      const empty = WalletSummary();
      walletSummaryNotifier.value = empty;
      return empty;
    }

    final results = await Future.wait([
      _tokenBalance(_realmFree, email),
      _tokenBalance(_realmPaid, email),
    ]);
    final summary = WalletSummary(
      freeBalance: results[0],
      freeCap: results[0] == null ? null : freeCap,
      paidBalance: results[1],
    );
    walletSummaryNotifier.value = summary;
    return summary;
  }

  Future<String?> fetchRefno() async {
    try {
      final uri = Uri.parse('$_engineUrl/refno');
      final res = await _client.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body);
      if (body is List && body.isNotEmpty) {
        return body[0]['refno']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> recordDeposit({
    required String refno,
    required num amount,
  }) async {
    final email = currentEmail;
    if (email == null || email.isEmpty) return false;

    try {
      final uri = Uri.parse('$_engineUrl/transfer').replace(
        queryParameters: {
          'from_email': email,
          'to_email': _depositEmail,
          'amount': '$amount',
          'remark': 'Deposit-$refno',
          'realm_id': _realmPaid,
          'void': '1',
        },
      );
      final res = await _client.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return false;
      final body = json.decode(res.body);
      return body is Map && body['result'] == 'Success';
    } catch (_) {
      return false;
    }
  }

  Future<bool> confirmDeposits() async {
    try {
      final uri = Uri.parse('$_engineUrl/confirm_all');
      final res = await _client.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return false;
      final body = json.decode(res.body);
      return body is List &&
          body.isNotEmpty &&
          body[0] is Map &&
          body[0]['result'] == 'Success';
    } catch (_) {
      return false;
    }
  }

  Future<List<CoinPack>> fetchPacks() async {
    try {
      final uri = Uri.parse(
        '$_engineUrl/coin_packages',
      ).replace(queryParameters: {'q': 'a'});
      final res = await _client.get(uri).timeout(_timeout);
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        if (body is List && body.isNotEmpty) {
          return body
              .whereType<Map<String, dynamic>>()
              .map(CoinPack.fromJson)
              .toList();
        }
      }
    } catch (_) {}
    return defaultPacks;
  }

  Future<CollaborationQueueCharge> chargeCollaborationQueueFee() async {
    final email = currentEmail;
    if (email == null || email.isEmpty) {
      return const CollaborationQueueCharge(
        success: false,
        error: 'You need to be signed in to send a collaboration to the queue.',
      );
    }

    try {
      final uri = Uri.parse('$_engineUrl/transfer').replace(
        queryParameters: {
          'from_email': email,
          'to_email': _activitiesEmail,
          'amount': '$collaborationQueueFee',
          'remark': 'Purchase',
          'realm_id': _realmFree,
          'void': '0',
        },
      );
      final res = await _client.get(uri).timeout(_timeout);
      final body = json.decode(res.body);
      if (body is Map && body['result'] == 'Success') {
        unawaited(fetchSummary());
        return const CollaborationQueueCharge(success: true);
      }
      final error = body is Map ? body['remark']?.toString() : null;
      return CollaborationQueueCharge(
        success: false,
        error: error ?? 'Could not complete the charge.',
      );
    } catch (_) {
      return const CollaborationQueueCharge(
        success: false,
        error: 'Unable to reach the token service. Please try again.',
      );
    }
  }

  void dispose() => _client.close();
}
