import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'inventory_video.dart';

class InventoryContent extends StatefulWidget {
  final bool isActive;

  const InventoryContent({
    super.key,
    required this.isActive,
  });

  @override
  State<InventoryContent> createState() => _InventoryContentState();
}

class _InventoryContentState extends State<InventoryContent> {
  static const String baseUrl =
      'https://engine01.fuzikapp.com';

  static const String mediaBaseUrl =
      'https://media05.fuzikapp.com';

  static const Map<String, String> _mediaHeaders = {
    'Referer': 'https://fuzikapp.com',
  };

  List<Map<String, dynamic>> _myVideos = [];
  bool _isLoading = true;
  bool _isLoadingInventory = false;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  void didUpdateWidget(covariant InventoryContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive && !oldWidget.isActive) {
      _loadInventory();
    }
  }

  String? _getMediaUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    final cleanPath = path.trim();

    if (cleanPath == 'None' ||
        cleanPath.toLowerCase() == 'null' ||
        cleanPath.toLowerCase() == 'false') {
      return null;
    }

    if (cleanPath.startsWith('http://') ||
        cleanPath.startsWith('https://')) {
      return cleanPath;
    }

    final normalizedPath = cleanPath.startsWith('/')
        ? cleanPath.substring(1)
        : cleanPath;

    return '$mediaBaseUrl/$normalizedPath';
  }

  Future<void> _loadInventory() async {
    if (_isLoadingInventory) {
      return;
    }

    _isLoadingInventory = true;

    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null || user.email == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final email = user.email!;


      // GET PROFILE + LANDSCAPE + PORTRAIT
      final responses = await Future.wait([
        http.get(
          Uri.parse(
            '$baseUrl/musician2_detail'
                '?email=${Uri.encodeComponent(email)}',
          ),
        ),
        http.get(
          Uri.parse(
            '$baseUrl/my_play2s_l/'
                '?musician2_email=${Uri.encodeComponent(email)}',
          ),
        ),
        http.get(
          Uri.parse(
            '$baseUrl/my_play2s_p/'
                '?musician2_email=${Uri.encodeComponent(email)}',
          ),
        ),
      ]);

      final profileResponse = responses[0];
      final landscapeResponse = responses[1];
      final portraitResponse = responses[2];

      debugPrint(
        'PROFILE STATUS: ${profileResponse.statusCode}',
      );

      debugPrint(
        'LANDSCAPE STATUS: ${landscapeResponse.statusCode}',
      );

      debugPrint(
        'PORTRAIT STATUS: ${portraitResponse.statusCode}',
      );

      if (profileResponse.statusCode != 200) {
        throw Exception(
          'Failed to load musician profile',
        );
      }

      if (landscapeResponse.statusCode != 200) {
        throw Exception(
          'Failed to load landscape videos',
        );
      }

      if (portraitResponse.statusCode != 200) {
        throw Exception(
          'Failed to load portrait videos',
        );
      }

      // PROFILE
      final profileData =
      jsonDecode(profileResponse.body);

      if (profileData is! List ||
          profileData.isEmpty) {
        throw Exception(
          'Musician profile not found',
        );
      }

      final displayName =
          profileData[0]['display_name']
              ?.toString() ??
              '';

      if (displayName.isEmpty) {
        throw Exception(
          'Display name not found',
        );
      }

      // VIDEO DATA
      final landscapeData =
      jsonDecode(landscapeResponse.body);

      final portraitData =
      jsonDecode(portraitResponse.body);

      // COMBINE VIDEOS
      final List<Map<String, dynamic>> allVideos = [];

      if (landscapeData is List) {
        allVideos.addAll(
          List<Map<String, dynamic>>.from(
            landscapeData,
          ),
        );
      }

      if (portraitData is List) {
        allVideos.addAll(
          List<Map<String, dynamic>>.from(
            portraitData,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _displayName = displayName;
        _myVideos = allVideos;
        _isLoading = false;
      });


      _loadViewCounts(allVideos);
    } catch (e) {
      debugPrint(
        'INVENTORY ERROR: $e',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load inventory: $e',
            ),
          ),
        );
      }
    } finally {
      _isLoadingInventory = false;
    }
  }

  Future<void> _loadViewCounts(
      List<Map<String, dynamic>> videos) async {
    try {
      await Future.wait(
        videos.map((video) async {
          final videoUrl =
              video['url']?.toString() ?? '';

          if (videoUrl.isEmpty) {
            return;
          }

          final viewCount =
          await _getViewCount(videoUrl);

          video['view_count'] = viewCount;
        }),
      );

      if (!mounted) return;

      setState(() {
        _myVideos = List<Map<String, dynamic>>.from(
          videos,
        );
      });

    } catch (e) {
      debugPrint(
        'INVENTORY VIEW COUNTS ERROR: $e',
      );
    }
  }

  Future<int> _getViewCount(String videoUrl) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/get_play2_count'
              '?p=${Uri.encodeComponent(videoUrl)}',
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          return data[0]['view_count'] ?? 0;
        }
      }
    } catch (e) {
      debugPrint(
        'GET INVENTORY VIEW ERROR: $e',
      );
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final paddingHorizontal =
    screenWidth < 600 ? 16.0 : 40.0;

    final columns =
    screenWidth < 400
        ? 1
        : (screenWidth < 600 ? 2 : 4);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFFD600),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            _displayName.isNotEmpty
                ? "$_displayName's Inventory"
                : 'Your Inventory',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Manage your uploaded videos and collaborations.',
            style: TextStyle(
              color:
              Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 32),

          if (_myVideos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No uploaded videos yet.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

          if (_myVideos.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio:
                columns == 1 ? 1.4 : 1.05,
              ),
              itemCount: _myVideos.length,
              itemBuilder: (context, index) {
                final video =
                _myVideos[index];

                return _buildInventoryCard(
                  video,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(
      Map<String, dynamic> video,
      ) {
    final isPublished =
        video['void']?.toString() == '0';

    final title =
        video['video_title']?.toString() ??
            'Untitled';

    final musicianName =
        video['musician_name']
            ?.toString()
            .trim() ??
            '';

    final artist =
    musicianName.isNotEmpty
        ? musicianName
        : _displayName;

    final views =
        video['view_count']?.toString() ?? '0';

    final date =
        video['created_time']?.toString() ??
            '';

    final preview = _getMediaUrl(
      video['preview']?.toString(),
    );

    final profileUrl = _getMediaUrl(
      video['musician_profile_pic']
          ?.toString(),
    );

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              debugPrint(
                'OPEN VIDEO: '
                    '$title | '
                    'id=${video['url']} | '
                    'youtube=${video['youtube_url']}',
              );

              final changed =
              await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      InventoryVideoScreen(
                        videoUrl:
                        video['url']
                            ?.toString() ??
                            '',
                        isPublished:
                        video['void']
                            ?.toString() ==
                            '0',
                        inventoryVideo: video,
                      ),
                ),
              );

              if (changed == true) {
                _loadInventory();
              }
            },
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color:
                Colors.white.withOpacity(0.08),
                borderRadius:
                BorderRadius.circular(8),
                border: Border.all(
                  color:
                  const Color(0xFFFFD600)
                      .withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // VIDEO PREVIEW IMAGE
                  Positioned.fill(
                    child: preview != null
                        ? Image.network(
                      preview,
                      fit: BoxFit.cover,
                      width:
                      double.infinity,
                      height:
                      double.infinity,
                      headers:
                      _mediaHeaders,
                      loadingBuilder: (
                          context,
                          child,
                          loadingProgress,
                          ) {
                        if (loadingProgress ==
                            null) {
                          return child;
                        }

                        return const Center(
                          child:
                          CircularProgressIndicator(
                            color: Color(
                              0xFFFFD600,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (
                          context,
                          error,
                          stackTrace,
                          ) {
                        debugPrint(
                          'PREVIEW ERROR: '
                              '$preview | $error',
                        );

                        return const Center(
                          child: Icon(
                            Icons
                                .broken_image,
                            color:
                            Colors.white54,
                            size: 48,
                          ),
                        );
                      },
                    )
                        : const Center(
                      child: Icon(
                        Icons
                            .play_circle_fill,
                        color:
                        Colors.white30,
                        size: 48,
                      ),
                    ),
                  ),

                  // DIM UNPUBLISHED VIDEOS
                  if (!isPublished)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black
                            .withOpacity(0.55),
                      ),
                    ),

                  if (!isPublished)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                        BoxDecoration(
                          color: Colors.black
                              .withOpacity(0.75),
                          borderRadius:
                          BorderRadius.circular(
                            6,
                          ),
                        ),
                        child: const Text(
                          'Unpublished',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // EDIT, PUBLISH/UNPUBLISH
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration:
                      BoxDecoration(
                        color: Colors.black87,
                        borderRadius:
                        BorderRadius.circular(
                          4,
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                            constraints:
                            const BoxConstraints(),
                            padding:
                            const EdgeInsets.all(
                              6,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                      InventoryVideoScreen(
                                        videoUrl:
                                        video['url']
                                            ?.toString() ??
                                            '',
                                        isPublished:
                                        video['void']
                                            ?.toString() ==
                                            '0',
                                        inventoryVideo:
                                        video,
                                        autoEdit: true,
                                      ),
                                ),
                              );
                            },
                          ),

                          IconButton(
                            icon: Icon(
                              isPublished
                                  ? Icons.public
                                  : Icons.lock,
                              color: Colors.white,
                              size: 16,
                            ),
                            constraints:
                            const BoxConstraints(),
                            padding:
                            const EdgeInsets.all(
                              6,
                            ),
                            tooltip: isPublished
                                ? 'Unpublish'
                                : 'Publish',
                            onPressed: () {
                              _showPublishDialog(
                                video,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // PROFILE ICON, TITLE
        Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration:
              const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
              ),
              clipBehavior:
              Clip.antiAlias,
              child: profileUrl != null
                  ? Image.network(
                profileUrl,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                headers:
                _mediaHeaders,
                errorBuilder: (
                    context,
                    error,
                    stackTrace,
                    ) {
                  return const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  );
                },
              )
                  : const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),

            const SizedBox(width: 6),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    artist,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        Padding(
          padding:
          const EdgeInsets.only(
            left: 36.0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$views views',
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Flexible(
                child: Text(
                  date,
                  overflow:
                  TextOverflow.ellipsis,
                  textAlign:
                  TextAlign.right,
                  style:
                  const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPublishDialog(
      Map<String, dynamic> video,
      ) {
    final isPublished =
        video['void']?.toString() == '0';

    final action =
    isPublished ? 'Unpublish' : 'Publish';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
          const Color(0xFF1C1C1C),
          title: Text(
            'Do you want to $action this video?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            isPublished
                ? 'This video will no longer be visible to the public.'
                : 'This video will become visible to the public.',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _togglePublish(video);
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFFFD600),
                foregroundColor: Colors.black,
              ),
              child: Text(
                action,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _togglePublish(
      Map<String, dynamic> video,
      ) async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null || user.email == null) {
      return;
    }

    final isPublished =
        video['void']?.toString() == '0';

    final endpoint = isPublished
        ? 'unpublish_playvideo2'
        : 'publish_playvideo2';

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/$endpoint'
              '?p=${Uri.encodeComponent(
            video['url']?.toString() ?? '',
          )}'
              '&musician2_email=${Uri.encodeComponent(
            user.email!,
          )}',
        ),
      );

      debugPrint(
        'PUBLISH STATUS: ${response.statusCode}',
      );

      debugPrint(
        'PUBLISH RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update video status',
        );
      }

      final data =
      jsonDecode(response.body);

      final result =
      data is List && data.isNotEmpty
          ? data[0]['result']
          ?.toString()
          : null;

      if (result == 'Success' ||
          result == 'Already Published' ||
          result == 'Already Unpublished') {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              isPublished
                  ? 'Video unpublished'
                  : 'Video published',
            ),
          ),
        );

        await _loadInventory();
      } else {
        throw Exception(
          data is List && data.isNotEmpty
              ? data[0]['description']
              ?.toString()
              : 'Unknown error',
        );
      }
    } catch (e) {
      debugPrint(
        'PUBLISH ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update video: $e',
          ),
        ),
      );
    }
  }
}