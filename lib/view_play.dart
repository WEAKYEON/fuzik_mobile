import 'package:flutter/material.dart';
import 'youtube_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ViewPlayScreen extends StatefulWidget {
  final String title;
  final String artist;
  final String views;
  final String url;
  final String profileUrl;
  final String description;
  final String musicianEmail;

  const ViewPlayScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.views,
    required this.url,
    required this.profileUrl,
    required this.description,
    required this.musicianEmail,
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
    '?play2_url=${Uri.encodeComponent(widget.url)}'
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
    '?play2_url=${Uri.encodeComponent(widget.url)}'
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

    if (widget.url.isEmpty) return;

    final email =
        Supabase.instance.client.auth.currentUser?.email ?? '';

    final uri = Uri.parse(
      '$baseUrl/add_play2_count'
          '?p=${Uri.encodeComponent(widget.url)}'
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
    if (widget.url.isEmpty) return;

    final uri = Uri.parse(
      '$baseUrl/get_play2_count'
          '?p=${Uri.encodeComponent(widget.url)}',
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
            Icons.arrow_back,
            color: Colors.white,
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
           YouTubeScreen(videourl: widget.url),

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
                widget.profileUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: 'https://media05.fuzikapp.com/$widget.profileUrl',
                    httpHeaders: {
                      'Referer': 'https://fuzikapp.com',
                    },
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) {
                      return const Icon(Icons.person);
                    },
                  )
                : const Icon(Icons.person),
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

            const SizedBox(height: 24),

            // Divider
            Container(
              height: 1,
              color: Colors.white12,
            ),

            const SizedBox(height: 20),

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

            const SizedBox(height: 30),

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
                          text: '${widget.title}\nby ${widget.artist}\n${widget.url}',
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
          ],
        ),
      ),
    );
  }
}





//  AspectRatio(
//               aspectRatio: 16 / 9,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF151515),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: const Color(0xFFFFD600).withValues(
//                       alpha: 0.5,
//                     ),
//                   ),
//                 ),
//                 child: Stack(
//                   children: [

//                     // Play button
//                     Center(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.white54,
//                         ),
//                         child: IconButton(
//                           iconSize: 42,
//                           icon: const Icon(
//                             Icons.play_arrow,
//                             color: Colors.black,
//                           ),
//                           onPressed: () {
//                             // to Connect real video player here.
//                           },
//                         ),
//                       ),
//                     ),

//                     // JAM label
//                     Positioned(
//                       left: 12,
//                       top: 12,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 5,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.black87,
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: const Text(
//                           'JAM',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 11,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),

//                     // Mock progress bar
//                     Positioned(
//                       left: 12,
//                       right: 12,
//                       bottom: 12,
//                       child: Column(
//                         children: [
//                           Container(
//                             height: 4,
//                             decoration: BoxDecoration(
//                               color: Colors.white24,
//                               borderRadius:
//                               BorderRadius.circular(4),
//                             ),
//                             child: FractionallySizedBox(
//                               alignment: Alignment.centerLeft,
//                               widthFactor: 0.55,
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: Colors.white54,
//                                   borderRadius:
//                                   BorderRadius.circular(4),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           const Row(
//                             mainAxisAlignment:
//                             MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 '0:00',
//                                 style: TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 11,
//                                 ),
//                               ),
//                               Text(
//                                 '0:00',
//                                 style: TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 11,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),