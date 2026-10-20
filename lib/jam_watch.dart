import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fuzik_mobile/services/fetch_videos.dart';
import 'collaboration.dart';
import 'httpsVideoPlayer.dart';
import 'youtube_player.dart';

const _apiBase = 'https://engine01.fuzikapp.com';
const _mediaBase = 'https://media05.fuzikapp.com';
const _headers = {'Referer': 'https://fuzikapp.com'};

class JamWatchScreen extends StatefulWidget {
  final String title;
  final String youTubeCode;
  final String profileUrl;
  final String description;
  final String videoUrl; // the jam id/url used by the API
  final bool isSolo;
  final String previewUrl;

  const JamWatchScreen({
    super.key,
    required this.title,
    required this.youTubeCode,
    required this.profileUrl,
    required this.description,
    required this.videoUrl,
    this.isSolo = false,
    required this.previewUrl,
  });

  @override
  State<JamWatchScreen> createState() => _JamWatchScreenState();
}

class _JamWatchScreenState extends State<JamWatchScreen> {
  // Loaded data
  Video videoDetail = const Video();
  String videoInitializationError = '';
  bool isLoading = true;

  List<String> instruments = [];
  String jamTitle = '';
  String apiDescription = '';
  String ownerName = '';
  String ownerPic = '';
  String musicianEmail = '';
  String? _jamUrlFromApi;

  // Interaction state
  bool _isLiked = false;
  bool _isFan = false;
  int _viewCount = 0;

  String get jamUrl => _jamUrlFromApi ?? widget.videoUrl;
  String get _userEmail =>
      Supabase.instance.client.auth.currentUser?.email ?? 'unregistered';

  @override
  void initState() {
    super.initState();
    initializeVideoDetails();
  }

  // ---------------------------------------------------------------- helpers

  String cleanText(String? raw) {
    if (raw == null) return '';
    return raw.replaceAll(RegExp(r'\\+n'), '\n').trim();
  }

  /// Reads the first non-empty value among [keys] (handles key spelling variants).
  String _field(Map<String, dynamic> d, List<String> keys) {
    for (final k in keys) {
      final v = d[k]?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  Future<http.Response?> _request(String path, Map<String, String> params) async {
    try {
      final uri = Uri.parse('$_apiBase/$path').replace(queryParameters: params);
      return await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      debugPrint('REQUEST ERROR ($path): $e');
      return null;
    }
  }

  Future<dynamic> _getJson(String path, Map<String, String> params) async {
    final r = await _request(path, params);
    if (r == null || r.statusCode != 200) return null;
    try {
      return jsonDecode(r.body);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------- loading

  Future<void> initializeVideoDetails() async {
    final result = await getVideoDetail(
      isSolo: widget.isSolo,
      videoUrl: widget.videoUrl,
    );
    if (!mounted) return;

    if (result.hasError || result.videoDetail.isEmpty) {
      setState(() {
        videoInitializationError =
            result.hasError ? result.error : 'Video not found.';
        isLoading = false;
      });
      return;
    }

    final data = Map<String, dynamic>.from(result.videoDetail[0] as Map);

    final list = <String>[];
    for (var i = 1; i <= 4; i++) {
      final value = _field(data, [
        'video0${i}_instrument',
        'video0${i}_instrunment', // spelling used elsewhere in the app
      ]).trim();
      final lower = value.toLowerCase();
      if (value.isNotEmpty &&
          lower != 'undefined' &&
          lower != 'null' &&
          lower != 'none') {
        list.add(value);
      }
    }

    final landscape = int.tryParse(data['layout_l_num']?.toString() ?? '') ?? 0;
    final portrait = int.tryParse(data['layout_p_num']?.toString() ?? '') ?? 0;
    final pieces = landscape + portrait > 0 ? landscape + portrait : list.length;
    final title = pieces > 0
        ? '$pieces-piece collaboration - ${list.join(', ')}'
        : 'Collaboration';

    // One setState, so the UI never shows a half-updated state.
    setState(() {
      videoDetail = result;
      instruments = list;
      jamTitle = title;
      apiDescription = data['description']?.toString() ?? '';
      ownerName = data['owner_display_name']?.toString() ?? '';
      ownerPic = data['owner_display_pic']?.toString() ?? '';
      musicianEmail = data['musician_email']?.toString() ?? '';
      _jamUrlFromApi = data['url']?.toString();
      isLoading = false;
    });

    // Player is already visible; load the extras without blocking it.
    if (!widget.isSolo) {
      await _addJamViewCount();
      await _loadJamExtras();
    }
  }

  Future<void> _addJamViewCount() async {
    if (jamUrl.isEmpty) return;
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    await _request('add_jam2_count', {'j': jamUrl, 'email': email});
  }

  Future<void> _loadJamExtras() async {
    final results = await Future.wait([
      _getJson('get_jam_like', {'jam2_url': jamUrl, 'user_email': _userEmail}),
      musicianEmail.isEmpty
          ? Future<dynamic>.value(null)
          : _getJson('get_fan', {
              'musician_email': musicianEmail,
              'user_email': _userEmail,
            }),
      _getJson('get_jam2_count', {'j': jamUrl}),
    ]);
    if (!mounted) return;

    bool yes(dynamic d) =>
        d is List && d.isNotEmpty && d[0]['result'] == 'Yes';

    setState(() {
      _isLiked = yes(results[0]);
      _isFan = yes(results[1]);
      final c = results[2];
      if (c is List && c.isNotEmpty) {
        _viewCount = int.tryParse('${c[0]['view_count']}') ?? 0;
      }
    });
  }

  // ---------------------------------------------------------------- actions

  Future<void> _toggleLike() async {
    final newLike = _isLiked ? 'No' : 'Yes';
    final r = await _request('add_jam_like', {
      'jam2_url': jamUrl,
      'user_email': _userEmail,
      'like': newLike,
    });
    if (!mounted || r == null || r.statusCode != 200) return;
    setState(() => _isLiked = newLike == 'Yes');
  }

  Future<void> _toggleFan() async {
    if (musicianEmail.isEmpty) return;
    final newFan = _isFan ? 'No' : 'Yes';
    final r = await _request('add_fan', {
      'musician_email': musicianEmail,
      'user_email': _userEmail,
      'fan': newFan,
    });
    if (!mounted || r == null || r.statusCode != 200) return;
    setState(() => _isFan = newFan == 'Yes');
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(text: 'https://www.fuzikapp.com/webapp/jam_watch/$jamUrl'),
    );
  }

  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final ready = !isLoading && videoInitializationError.isEmpty;
    final title = jamTitle.isNotEmpty
        ? jamTitle
        : cleanText(widget.title);
    final description = cleanText(
      widget.description.isNotEmpty ? widget.description : apiDescription,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildPlayer(),
            const SizedBox(height: 20),

            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 16),

            if (ready) ...[
              _buildOwnerRow(),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildPillButton(
                    _isFan ? Icons.person : Icons.person_add,
                    'Fan',
                    _isFan ? Colors.red : const Color(0xFFFFB300),
                    _toggleFan,
                  ),
                  _buildPillButton(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    _isLiked ? 'Liked' : 'Like',
                    _isLiked ? Colors.red : const Color(0xFFFFB300),
                    _toggleLike,
                  ),
                  _buildPillButton(
                    Icons.share,
                    'Share',
                    const Color(0xFFFFB300),
                    _share,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            const Divider(color: Colors.white24, thickness: 1),
            const SizedBox(height: 16),

            const Text(
              'Description',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (description.isNotEmpty)
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                  height: 1.6,
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerRow() {
    final hasPic = ownerPic.isNotEmpty;
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white,
          backgroundImage:
              hasPic ? CachedNetworkImageProvider('$_mediaBase/$ownerPic') : null,
          child: hasPic
              ? null
              : const Icon(Icons.music_note, color: Colors.black),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Created by ${ownerName.isEmpty ? 'Unknown' : ownerName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_viewCount views',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPillButton(
    IconData icon,
    String label,
    Color iconColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: iconColor, size: 18),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
      ),
    );
  }

  Widget buildPlayer() {
    if (widget.youTubeCode.isNotEmpty) {
      return YouTubeScreen(
        youTubeurl: 'https://www.youtube.com/watch?v=${widget.youTubeCode}',
      );
    }
    if (isLoading) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (videoInitializationError.isNotEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Text(
            videoInitializationError,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return HttpsVideoPlayer(
      videoUrl: widget.videoUrl,
      isSolo: widget.isSolo,
      previewUrl: widget.previewUrl,
      videoDetail: videoDetail,
    );
  }
}

class Video {
  final String error;
  final List<dynamic> videoDetail;
  const Video({this.error = '', this.videoDetail = const []});

  bool get hasError => error.isNotEmpty;
}

Future<Video> getVideoDetail({bool isSolo = false, String videoUrl = ''}) async {
  if (!await hasNetwork()) {
    return const Video(error: 'No connection. Please connect to network');
  }
  try {
    final url = isSolo
        ? Uri.parse('$_apiBase/play2_watch?p=$videoUrl')
        : Uri.parse('$_apiBase/jam2_watch?j=${Uri.encodeComponent(videoUrl)}');
    debugPrint('$url');
    final response =
        await http.get(url, headers: _headers).timeout(const Duration(seconds: 30));
    if (response.statusCode == 500) {
      return const Video(
          error: 'Sorry. Internal Server error. Please try again later.');
    }
    if (response.statusCode == 200) {
      final detail = List<dynamic>.from(jsonDecode(response.body));
      return Video(videoDetail: detail);
    }
    return const Video(error: 'Sorry. Cannot get the video. Please try again.');
  } on TimeoutException {
    return const Video(error: 'Sorry. Your connection is too slow.');
  } on SocketException {
    return const Video(
        error: 'Could not reach the server. Check your connection.');
  } on FormatException {
    return const Video(
        error: 'Received an unexpected response from the server.');
  } catch (e) {
    return Video(error: 'Cannot get the video. Error: $e');
  }
}