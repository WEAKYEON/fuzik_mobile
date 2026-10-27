import 'dart:async';
import 'dart:convert';
import 'dart:math';

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
  final bool alreadyCharged;
  final String? error;

  const CollaborationQueueCharge({
    required this.success,
    this.alreadyCharged = false,
    this.error,
  });
}

class WalletApi {
  WalletApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 20);
  static const int freeCap = 200;
  static const int collaborationQueueFee = 120;

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

  String get _tokenUrl =>
      (dotenv.env['TOKEN_URL'] ?? 'https://tetrasolution.com/token_app/api')
          .replaceAll(RegExp(r'/+$'), '');

  String get _realmFree => dotenv.env['REALM_FREE'] ?? 'REALM00000002';

  String get _realmPaid => dotenv.env['REALM_PAID'] ?? 'REALM00000001';

  String? get currentEmail => Supabase.instance.client.auth.currentUser?.email;

  String? get _accessToken =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  static String generateRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<int?> _tokenBalance(String realmId, String email) async {
    final uri = Uri.parse('$_tokenUrl/check_balance_by_email.php').replace(
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
      final raw = body['balance'].toString();
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

  Future<CollaborationQueueCharge> chargeCollaborationQueueFee({
    required String requestId,
  }) async {
    final token = _accessToken;
    if (token == null || token.isEmpty) {
      return const CollaborationQueueCharge(
        success: false,
        error: 'You need to be signed in to send a collaboration to the queue.',
      );
    }

    try {
      final uri = Uri.parse('$_engineUrl/submit_collaboration_token');
      final res = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'request_id': requestId}),
          )
          .timeout(_timeout);
      final body = json.decode(res.body);
      if (body is Map && body['result'] == 'Success') {
        unawaited(fetchSummary());
        return CollaborationQueueCharge(
          success: true,
          alreadyCharged: body['already_charged'] == true,
        );
      }
      final error = body is Map ? body['error']?.toString() : null;
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
