import 'package:flutter/material.dart';
import 'package:fuzik_mobile/main_layout.dart';
import 'package:fuzik_mobile/services/video_downloader.dart';
import 'package:fuzik_mobile/services/fetch_videos.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../wallet_api.dart';

class DownloadButton extends StatefulWidget {
  final String videoUrl; //This videoUrl represents the code e.g 8A5xi09j50
  final String videoLink;
  const DownloadButton({
    super.key,
    required this.videoUrl,
    required this.videoLink,
  });

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool _downloading = false;
  bool _checkingAccess = false;
  static const _webOrigin = String.fromEnvironment('JAM_DOWNLOAD_WEB_BASE_URL');
  static const downloadPrice = 150; // FZ; charged by the server only.
  final ValueNotifier<double?> _progress = ValueNotifier<double?>(0);
  final downloader = VideoDownloader();

  Future<void> downloadVideo(
    String videoLink,
    String videoCode,
    String accessToken,
  ) async {
    DownloadResult result;
    if (_downloading) return;
    if (!await hasNetwork()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "You are offline!",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }
    setState(() {
      _downloading = true;
    });
    _progress.value = 0;
    try {
      result = await downloader.downloadToGallery(
        headers: {'Authorization': 'Bearer $accessToken'},
        url: videoLink, // the media URL, not the jam2_watch API URL
        fileName:
            'fuzik_${widget.videoUrl}', //This videoUrl represents the code e.g 8A5xi09j50
        onProgress: (p) {
          if (mounted) _progress.value = p; // null means the size is unknown
        },
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
        content: Text(
          result.isSuccess
              ? 'Saved to your gallery'
              : result.message ?? 'Cancelled',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Future<bool> showCoinUsageConfirmationForVideoDownload() async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Download"),
          content: Text(
            "Download costs $downloadPrice FZ. You can download this Jam again for 30 days without another charge. Continue?",
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<bool> showMiniCoinShopDialog() async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Insufficient Coins"),
          content: Text(
            "You don't have enough FZ coins to download this video. Would you like to visit the coin shop?",
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Go to Coin Shop'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Uri get _origin {
    final uri = Uri.tryParse(_webOrigin);
    final local =
        uri != null &&
        ['localhost', '127.0.0.1', '10.0.2.2'].contains(uri.host);
    if (uri == null ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.path.isNotEmpty && uri.path != '/' ||
        (uri.scheme != 'https' && !(uri.scheme == 'http' && local))) {
      throw StateError('Jam Download server is not configured.');
    }
    return uri;
  }

  Future<Map<String, dynamic>> _request(
    Uri uri, {
    bool purchase = false,
  }) async {
    var session = Supabase.instance.client.auth.currentSession;
    if (session == null) throw StateError('Please sign in again.');
    if (session.isExpired) {
      session = (await Supabase.instance.client.auth.refreshSession()).session;
    }
    if (session == null) throw StateError('Please sign in again.');
    final headers = {
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
    };
    // Never retry a charge automatically after an uncertain response. A later
    // tap starts with the read-only entitlement check instead.
    final response =
        await (purchase
                ? http.post(
                    uri,
                    headers: headers,
                    body: jsonEncode({'jamUrl': widget.videoUrl}),
                  )
                : http.get(uri, headers: headers))
            .timeout(const Duration(seconds: 45));
    if (response.statusCode == 402) {
      if (mounted && await showMiniCoinShopDialog() && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MainLayout(goToWallet: true)),
        );
      }
      return {};
    }
    if (response.statusCode == 401) throw StateError('Please sign in again.');
    if (response.statusCode == 503 || response.statusCode == 404) {
      throw StateError('Jam Download is not available on this server yet.');
    }
    if (response.statusCode != 200) {
      throw StateError(
        'Could not confirm download access. Try again to check your existing purchase.',
      );
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw StateError('Invalid download response.');
    }
    return data;
  }

  Future<void> _startDownload() async {
    if (_checkingAccess || _downloading) return;
    setState(() => _checkingAccess = true);
    try {
      final origin = _origin;
      var access = await _request(
        origin
            .resolve('/api/jam_download_access')
            .replace(queryParameters: {'j': widget.videoUrl}),
      );
      if (!mounted || access.isEmpty) return;
      if (access['enabled'] != true) {
        throw StateError('Jam Download is not enabled on this server yet.');
      }
      if (access['active'] != true) {
        if (!await showCoinUsageConfirmationForVideoDownload() || !mounted) {
          return;
        }
        access = await _request(
          origin.resolve('/api/transfer_token'),
          purchase: true,
        );
        if (!mounted || access.isEmpty) return;
      }
      // Refresh from the ledger even when saving the purchased video later fails.
      try {
        await WalletApi().fetchSummary();
      } catch (_) {}
      if (!mounted) return;
      final link = access['downloadUrl'];
      final expiry = access['expiresAt'];
      final expiresAt = expiry is num
          ? DateTime.fromMillisecondsSinceEpoch(expiry.toInt())
          : null;
      if (link is! String ||
          expiresAt == null ||
          !expiresAt.isAfter(DateTime.now())) {
        throw StateError('The server did not confirm download access.');
      }
      final url = origin.resolve(link);
      if (url.origin != origin.origin ||
          url.path != '/api/download_jam' ||
          url.queryParameters['j'] != widget.videoUrl ||
          (url.queryParameters['ticket'] ?? '').isEmpty) {
        throw StateError('Invalid protected download URL.');
      }
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) throw StateError('Please sign in again.');
      // Do not fall back to videoLink: that is the playback source.
      await downloadVideo(url.toString(), widget.videoUrl, token);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message
                : 'Download could not be completed. Try again to check your existing purchase.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingAccess = false);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    downloader.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _downloading
        ? SizedBox(
            width: 120,
            height: 200,
            child: Column(
              children: [
                ValueListenableBuilder<double?>(
                  valueListenable: _progress,
                  builder: (context, p, _) {
                    final saving = p != null && p >= 1.0;
                    return Column(
                      children: [
                        LinearProgressIndicator(
                          value: saving ? null : p,
                        ), // null shows the "unknown length" animation
                        const SizedBox(height: 6),
                        Text(
                          saving
                              ? "Saving to gallary"
                              : p == null
                              ? 'Downloading...'
                              : '${(p * 100).toStringAsFixed(0)}%',
                        ),
                      ],
                    );
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () {
                    downloader.cancel();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          )
        : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.yellow,
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withValues(alpha: 0.5),
                  spreadRadius: 2,
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              color: Colors.black,
              icon: _checkingAccess
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              onPressed: _checkingAccess ? null : _startDownload,
            ),
          );
  }
}
