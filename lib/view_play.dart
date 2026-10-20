import 'package:flutter/material.dart';
import 'youtube_player.dart';
import 'httpsVideoPlayer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ViewPlayScreen extends StatefulWidget {
  final String musicianEmail;
  final String title;
  final String artist;
  final String views;
  final String youTubeCode;
  final String profileUrl;
  final String description;
  final String videoUrl;
  const ViewPlayScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.views,
    required this.youTubeCode,
    required this.profileUrl,
    required this.description,
    required this.videoUrl,
    required this.musicianEmail
  });
  @override
  State<ViewPlayScreen> createState() => _ViewPlayScreenState();
}

class _ViewPlayScreenState extends State<ViewPlayScreen> {
  final String baseUrl = 'https://engine01.fuzikapp.com';
  bool isLiked = false;
  bool isFan = false;
  bool isLoadingLike = false;
  bool isLoadingFan = false;
  int viewCount = 0;

  @override
  void initState() {
    super.initState();
    _getLike();
    _getFan();
    _addPlay2Count().then((_) {
      _getPlay2Count();
    });
  }

  Future<void> _getLike() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? '';

    if (userEmail.isEmpty) return;

    final uri = Uri.parse(
    '$baseUrl/get_like'
    '?play2_url=${Uri.encodeComponent(widget.videoUrl)}'
    '&user_email=${Uri.encodeComponent(userEmail)}',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          setState(() {
            isLiked = data[0]['result'] == 'Yes';
          });
        }
      }
    } catch (e) {
      print('Get Like Error: $e');
    }
  }

  Future<void> _toggleLike() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? '';

    if (userEmail.isEmpty || isLoadingLike) return;

    final newLikeStatus = isLiked ? 'No' : 'Yes';

    setState(() {
      isLoadingLike = true;
    });

    final uri = Uri.parse(
    '$baseUrl/add_like'
    '?play2_url=${Uri.encodeComponent(widget.videoUrl)}'
    '&user_email=${Uri.encodeComponent(userEmail)}'
    '&like=$newLikeStatus',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          isLiked = newLikeStatus == 'Yes';
        });
      }
    } catch (e) {
      print('Like Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingLike = false;
        });
      }
    }
  }

  Future<void> _getFan() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? '';

    if (userEmail.isEmpty || widget.musicianEmail.isEmpty) return;

    final uri = Uri.parse(
      '$baseUrl/get_fan'
          '?musician_email=${Uri.encodeComponent(widget.musicianEmail)}'
          '&user_email=${Uri.encodeComponent(userEmail)}',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          setState(() {
            isFan = data[0]['result'] == 'Yes';
          });
        }
      }
    } catch (e) {
      print('Get Fan Error: $e');
    }
  }

  Future<void> _toggleFan() async {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? '';

    if (userEmail.isEmpty || widget.musicianEmail.isEmpty || isLoadingFan) {
      return;
    }

    final newFanStatus = isFan ? 'No' : 'Yes';

    setState(() {
      isLoadingFan = true;
    });

    final uri = Uri.parse(
      '$baseUrl/add_fan'
          '?musician_email=${Uri.encodeComponent(widget.musicianEmail)}'
          '&user_email=${Uri.encodeComponent(userEmail)}'
          '&fan=$newFanStatus',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          isFan = newFanStatus == 'Yes';
        });
      }
    } catch (e) {
      print('Fan Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingFan = false;
        });
      }
    }
  }

  Future<void> _addPlay2Count() async {

    if (widget.videoUrl.isEmpty) return;

    final email =
        Supabase.instance.client.auth.currentUser?.email ?? '';

    final uri = Uri.parse(
      '$baseUrl/add_play2_count'
          '?p=${Uri.encodeComponent(widget.videoUrl)}'
          '&email=${Uri.encodeComponent(email)}',
    );

    try {
      final response = await http.get(uri);

      debugPrint('View Status: ${response.statusCode}');
      debugPrint('View Response: ${response.body}');

      if (response.statusCode == 200) {
        print('View Count Added');
      }

    } catch (e) {
      print('Add View Count Error: $e');
    }
  }

  Future<void> _getPlay2Count() async {
    if (widget.videoUrl.isEmpty) return;

    final uri = Uri.parse(
      '$baseUrl/get_play2_count'
          '?p=${Uri.encodeComponent(widget.videoUrl)}',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        if (data.isNotEmpty) {
          setState(() {
            viewCount = data[0]['view_count'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('Get View Count Error: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.yellow,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            widget.youTubeCode.isEmpty? HttpsVideoPlayer(videoUrl: widget.videoUrl):
            // Video player mockup
           YouTubeScreen(youTubeurl: 'https://www.youtube.com/watch?v=$widget.youTubeCode'),

          const SizedBox(height: 20),

            // Video title
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // user
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(25),
                child: widget.profileUrl.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: 'https://media05.fuzikapp.com/${widget.profileUrl}',
                    httpHeaders: {
                      'Referer': 'https://fuzikapp.com',
                    },
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) {
                      return const Icon(Icons.person);
                    },
                  )
                : const Icon(Icons.person), ),
                const SizedBox(width: 6),
                Text(
                  widget.artist,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Views
            Row(
              children: [
                const Icon(
                  Icons.visibility,
                  color: Colors.white38,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  '$viewCount views',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Divider
            Container(
              height: 1,
              color: Colors.white12,
            ),

            const SizedBox(height: 15),

            // action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoadingLike ? null : _toggleLike,
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.white,
                    ),
                    label: Text(
                      isLiked ? 'Liked' : 'Like',
                      style: const TextStyle(color: Colors.white),
                    ),

                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.white24,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoadingFan ? null : _toggleFan,
                    icon: Icon(
                      isFan ? Icons.person : Icons.person_add,
                      color: isFan ? Colors.red : Colors.white,
                    ),
                    label: Text(
                      isFan ? 'Fan' : 'Fan',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.white24,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text: '${widget.title}\nby ${widget.artist}\n${widget.youTubeCode}',
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.white24,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Description',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              widget.description,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
