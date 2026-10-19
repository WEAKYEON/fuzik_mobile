import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'youtube_player.dart';

class JamWatchScreen extends StatefulWidget {
  final String jamUrl;

  const JamWatchScreen({
    Key? key,
    required this.jamUrl,
  }) : super(key: key);

  @override
  State<JamWatchScreen> createState() => _JamWatchScreenState();
}

class _JamWatchScreenState extends State<JamWatchScreen> {
  late Future<Map<String, dynamic>> _jamFuture;
  bool _isLiked = false;
  bool _isFan = false;

  @override
  void initState() {
    super.initState();

    _jamFuture = _loadJamScreen();

  }
  Future<Map<String, dynamic>> _loadJamScreen() async {
    await _addJamViewCount();

    return _fetchJam();
  }

  Future<Map<String, dynamic>> _fetchJam() async {
    final response = await http.get(
      Uri.parse(
        'https://engine01.fuzikapp.com/jam2_watch'
            '?j=${Uri.encodeComponent(widget.jamUrl)}',
      ),
      headers: {
        'Referer': 'https://fuzikapp.com',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load collaboration');
    }

    final data = jsonDecode(response.body);
    debugPrint('JAM WATCH DATA: $data');

    if (data is List && data.isNotEmpty) {
      final jam = Map<String, dynamic>.from(data.first);

      await _getJamLike(
        jam['url']?.toString() ?? widget.jamUrl,
      );
      await _getFan(
        jam['musician_email']?.toString() ?? '',
      );

      return jam;
    }

    throw Exception('Collaboration not found');
  }

  Future<void> _addJamViewCount() async {
    if (widget.jamUrl.isEmpty) return;

    final email =
        Supabase.instance.client.auth.currentUser?.email ?? '';

    try {
      final response = await http.get(
        Uri.parse(
          'https://engine01.fuzikapp.com/add_jam2_count'
              '?j=${Uri.encodeComponent(widget.jamUrl)}'
              '&email=${Uri.encodeComponent(email)}',
        ),
        headers: {
          'Referer': 'https://fuzikapp.com',
        },
      );

      debugPrint(
        'ADD JAM VIEW STATUS: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint(
        'ADD JAM VIEW ERROR: $e',
      );
    }
  }

  Future<int> _getJamViewCount(String jamUrl) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://engine01.fuzikapp.com/get_jam2_count'
              '?j=${Uri.encodeComponent(jamUrl)}',
        ),
        headers: {
          'Referer': 'https://fuzikapp.com',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          return data[0]['view_count'] ?? 0;
        }
      }
    } catch (e) {
      debugPrint('GET JAM VIEW ERROR: $e');
    }

    return 0;
  }

  Future<void> _getJamLike(String jamUrl) async {
    try {
      final userEmail =
          Supabase.instance.client.auth.currentUser?.email ?? 'unregistered';

      final response = await http.get(
        Uri.parse(
          'https://engine01.fuzikapp.com/get_jam_like'
              '?jam2_url=${Uri.encodeComponent(jamUrl)}'
              '&user_email=${Uri.encodeComponent(userEmail)}',
        ),
        headers: {
          'Referer': 'https://fuzikapp.com',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          if (!mounted) return;

          setState(() {
            _isLiked = data[0]['result'] == 'Yes';
          });
        }
      }
    } catch (e) {
      debugPrint('GET JAM LIKE ERROR: $e');
    }
  }

  Future<void> _getFan(String musicianEmail) async {
    try {
      final userEmail =
          Supabase.instance.client.auth.currentUser?.email ?? 'unregistered';

      final response = await http.get(
        Uri.parse(
          'https://engine01.fuzikapp.com/get_fan'
              '?musician_email=${Uri.encodeComponent(musicianEmail)}'
              '&user_email=${Uri.encodeComponent(userEmail)}',
        ),
        headers: {
          'Referer': 'https://fuzikapp.com',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          setState(() {
            _isFan = data[0]['result'] == 'Yes';
          });
        }
      }
    } catch (e) {
      debugPrint('GET FAN ERROR: $e');
    }
  }

  Future<void> _toggleJamLike(String jamUrl) async {
    try {
      final userEmail =
          Supabase.instance.client.auth.currentUser?.email ?? 'unregistered';

      final newLike = _isLiked ? 'No' : 'Yes';

      final response = await http.get(
        Uri.parse(
          'https://engine01.fuzikapp.com/add_jam_like'
              '?jam2_url=${Uri.encodeComponent(jamUrl)}'
              '&user_email=${Uri.encodeComponent(userEmail)}'
              '&like=$newLike',
        ),
        headers: {
          'Referer': 'https://fuzikapp.com',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _isLiked = !_isLiked;
        });
      }
    } catch (e) {
      debugPrint('TOGGLE JAM LIKE ERROR: $e');
    }
  }

  Future<void> _toggleFan(String musicianEmail) async {
    try {
      final userEmail =
          Supabase.instance.client.auth.currentUser?.email ?? 'unregistered';

      final newFanStatus = _isFan ? 'No' : 'Yes';

      final response = await http.get(
        Uri.parse(
          'https://engine01.fuzikapp.com/add_fan'
              '?musician_email=${Uri.encodeComponent(musicianEmail)}'
              '&user_email=${Uri.encodeComponent(userEmail)}'
              '&fan=$newFanStatus',
        ),
        headers: {
          'Referer': 'https://fuzikapp.com',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _isFan = newFanStatus == 'Yes';
        });
      }
    } catch (e) {
      debugPrint('TOGGLE FAN ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(
          color: Colors.white,
        ),
      ),

      body: FutureBuilder<Map<String, dynamic>>(
        future: _jamFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD600),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text(
                'Could not load collaboration.',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            );
          }

          final jam = snapshot.data!;

          final jamUrl = jam['url']?.toString() ?? widget.jamUrl;


          final instruments = [
            jam['video01_instrument']?.toString() ?? '',
            jam['video02_instrument']?.toString() ?? '',
            jam['video03_instrument']?.toString() ?? '',
            jam['video04_instrument']?.toString() ?? '',
          ].where((instrument) {
            final value = instrument.trim();

            return value.isNotEmpty &&
                value.toLowerCase() != 'undefined' &&
                value.toLowerCase() != 'null' &&
                value.toLowerCase() != 'none';
          }).toList();

          final landscapeCount =
              int.tryParse(
                jam['layout_l_num']?.toString() ?? '',
              ) ??
                  0;

          final portraitCount =
              int.tryParse(
                jam['layout_p_num']?.toString() ?? '',
              ) ??
                  0;

          final pieceCount =
              landscapeCount + portraitCount;

          final jamTitle = pieceCount > 0
              ? '$pieceCount-piece collaboration - '
              '${instruments.join(', ')}'
              : instruments.isNotEmpty
              ? '${instruments.length}-piece collaboration - '
              '${instruments.join(', ')}'
              : 'Collaboration';

          final description =
              jam['description']?.toString() ?? '';

          final ownerName =
              jam['owner_display_name']?.toString() ?? 'Unknown';

          final musicianEmail =
              jam['musician_email']?.toString() ?? '';


          final viewCountFuture = _getJamViewCount(jamUrl);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Vd preview
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFD600),
                      width: 2,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      children: [
                        Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(
                              Icons.music_video,
                              color: Colors.white54,
                              size: 64,
                            ),
                          ),
                        ),


                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  jamTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      backgroundImage: (jam['owner_display_pic']?.toString().isNotEmpty ?? false)
                          ? CachedNetworkImageProvider(
                        'https://media05.fuzikapp.com/${jam['owner_display_pic']}',
                      )
                          : null,
                      child: (jam['owner_display_pic']?.toString().isNotEmpty ?? false)
                          ? null
                          : const Icon(
                        Icons.music_note,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created by $ownerName',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 4),

                          FutureBuilder<int>(
                            future: viewCountFuture,
                            builder: (context, viewSnapshot) {
                              final views = viewSnapshot.data ?? 0;

                              return Text(
                                '$views views',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleJamLike(jamUrl),
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.white,
                        ),
                        label: Text(
                          _isLiked ? 'Liked' : 'Like',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleFan(musicianEmail),
                        icon: Icon(
                          _isFan ? Icons.person : Icons.person_add,
                          color: _isFan ? Colors.red : Colors.white,
                        ),
                        label: const Text(
                          'Fan',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await SharePlus.instance.share(
                            ShareParams(
                              text:
                              'https://www.fuzikapp.com/webapp/jam_watch/$jamUrl',
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.share,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Share',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Divider(
                  color: Colors.white24,
                  thickness: 1,
                ),

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
                Text(
                  'This collaboration consists of:',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 8),


                Text(
                  description.replaceAll(r'\n', '\n').trim(),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),


                const SizedBox(height: 24),

              ],
            ),
          );
        },
      ),
    );
  }
}