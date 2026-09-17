import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'youtube_player.dart';

class InventoryVideoScreen extends StatefulWidget {
  final String videoUrl;
  final bool autoEdit;

  const InventoryVideoScreen({
    super.key,
    required this.videoUrl,
    this.autoEdit = false,
  });

  @override
  State<InventoryVideoScreen> createState() =>
      _InventoryVideoScreenState();
}

class _InventoryVideoScreenState extends State<InventoryVideoScreen> {
  static const String baseUrl =
      'https://engine01.fuzikapp.com';

  static const String mediaBaseUrl =
      'https://media05.fuzikapp.com';

  static const Map<String, String> _mediaHeaders = {
    'Referer': 'https://fuzikapp.com',
  };

  Map<String, dynamic>? video;

  bool isLoading = true;

  String? _profilePicturePath;

  @override
  void initState() {
    super.initState();
    _loadVideo();
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

  String _getYoutubeUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }

    final youtubeValue = value.trim();

    if (youtubeValue.startsWith('http://') ||
        youtubeValue.startsWith('https://')) {
      return youtubeValue;
    }

    return 'https://www.youtube.com/watch?v=$youtubeValue';
  }

  Future<void> _loadVideo() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/play2_watch'
              '?p=${Uri.encodeComponent(widget.videoUrl)}',
        ),
      );

      debugPrint(
        'INVENTORY VIDEO STATUS: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load video',
        );
      }

      final data = jsonDecode(response.body);

      if (data is List && data.isNotEmpty) {
        final loadedVideo =
        Map<String, dynamic>.from(
          data[0],
        );

        if (!mounted) return;

        setState(() {
          video = loadedVideo;
          isLoading = false;
        });

        final musicianEmail =
            loadedVideo['musician_email']
                ?.toString() ??
                '';

        if (musicianEmail.isNotEmpty) {
          await _loadMusicianProfile(
            musicianEmail,
          );
        }

        final youtubeValue =
            loadedVideo['youtube_url']
                ?.toString() ??
                '';

        debugPrint(
          'YOUTUBE URL: $youtubeValue',
        );

        await _addViewCount();

        if (widget.autoEdit && mounted) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            if (mounted) {
              _showEditDialog();
            }
          });
        }
      } else {
        throw Exception(
          'Video not found',
        );
      }
    } catch (e) {
      debugPrint(
        'INVENTORY VIDEO ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load video: $e',
          ),
        ),
      );
    }
  }

  Future<void> _loadMusicianProfile(
      String email,
      ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/musician2_detail'
              '?email=${Uri.encodeComponent(email)}',
        ),
      );

      if (response.statusCode != 200) {
        return;
      }

      final data =
      jsonDecode(response.body);

      if (data is List && data.isNotEmpty) {
        final profilePic =
        data[0]['profile_pic']?.toString();

        if (!mounted) return;

        setState(() {
          _profilePicturePath =
              profilePic;
        });
      }
    } catch (e) {
      debugPrint(
        'PROFILE LOAD ERROR: $e',
      );
    }
  }

  Future<void> _addViewCount() async {
    try {
      final email =
          video?['musician_email']
              ?.toString() ??
              '';

      if (email.isEmpty) {
        return;
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl/add_play2_count'
              '?p=${Uri.encodeComponent(widget.videoUrl)}'
              '&email=${Uri.encodeComponent(email)}',
        ),
      );

      debugPrint(
        'VIEW STATUS: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint(
        'VIEW ERROR: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const BackButton(
          color: Colors.white,
        ),
        title: const Text(
          'Video Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFFD600),
        ),
      )
          : video == null
          ? const Center(
        child: Text(
          'Video not found',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      )
          : _buildVideoContent(),
    );
  }

  Widget _buildVideoContent() {
    final title =
        video!['video_title']?.toString() ?? '';

    final artist =
        video!['musician_name']?.toString() ?? '';

    final description =
        video!['description']?.toString() ?? '';

    final musicTitle =
        video!['music_title']?.toString() ?? '';

    final originalPerformer =
        video!['original_performer']
            ?.toString() ??
            '';

    final instrument =
        video!['instrument']?.toString() ?? '';

    final views =
        video!['view_count']?.toString() ?? '0';

    final createdTime =
        video!['created_time']?.toString() ?? '';

    final profileUrl =
    _getMediaUrl(
      _profilePicturePath,
    );

    final youtubeUrl =
    _getYoutubeUrl(
      video!['youtube_url']?.toString(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        40,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // YOUTUBE PLAYER

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius:
              BorderRadius.circular(10),
              border: Border.all(
                //color:
                //const Color(0xFFFFD600),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: youtubeUrl.isNotEmpty
                ? YouTubeScreen(
              videourl: youtubeUrl,
            )
                : const AspectRatio(
              aspectRatio: 16 / 9,
              child: Center(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_library_outlined,
                      color: Colors.white54,
                      size: 44,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Video unavailable',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // PROFILE and CREATOR

          Row(
            children: [
              Container(
                width: 36,
                height: 36,
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
                  width: 36,
                  height: 36,
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
                      size: 20,
                    );
                  },
                )
                    : const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created by $artist',
                      style:
                      const TextStyle(
                        color: Colors.white,
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '$views views • $createdTime',
                      style: TextStyle(
                        color:
                        Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // EDIT + DELETE

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                  _showEditDialog,
                  icon: const Icon(
                    Icons.edit,
                    size: 18,
                  ),
                  label: const Text(
                    'Edit Video',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xFFFFD600,
                    ),
                    foregroundColor:
                    Colors.black,
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                  _showDeleteDialog,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    Colors.redAccent,
                    side:
                    const BorderSide(
                      color: Colors.redAccent,
                    ),
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
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
            description.isEmpty
                ? 'No description'
                : description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Music Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          if (musicTitle.isNotEmpty)
            _buildInfoRow(
              'Music',
              musicTitle,
            ),

          if (originalPerformer.isNotEmpty)
            _buildInfoRow(
              'Original Performer',
              originalPerformer,
            ),

          if (instrument.isNotEmpty)
            _buildInfoRow(
              'Instrument',
              instrument,
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEditDialog() {
    final titleController =
    TextEditingController(
      text:
      video!['video_title']
          ?.toString() ??
          '',
    );

    final descriptionController =
    TextEditingController(
      text:
      video!['description']
          ?.toString() ??
          '',
    );

    final musicController =
    TextEditingController(
      text:
      video!['music_title']
          ?.toString() ??
          '',
    );

    final performerController =
    TextEditingController(
      text:
      video!['original_performer']
          ?.toString() ??
          '',
    );

    final instrumentController =
    TextEditingController(
      text:
      video!['instrument']
          ?.toString() ??
          '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
          const Color(0xFF1C1C1C),

          title: const Text(
            'Edit Video',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                _buildEditField(
                  controller:
                  titleController,
                  label: 'Video Title',
                ),

                const SizedBox(height: 14),

                _buildEditField(
                  controller:
                  descriptionController,
                  label: 'Description',
                  maxLines: 4,
                ),

                const SizedBox(height: 14),

                _buildEditField(
                  controller:
                  musicController,
                  label: 'Music Title',
                ),

                const SizedBox(height: 14),

                _buildEditField(
                  controller:
                  performerController,
                  label:
                  'Original Performer',
                ),

                const SizedBox(height: 14),

                _buildEditField(
                  controller:
                  instrumentController,
                  label: 'Instrument',
                ),
              ],
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
                setState(() {
                  video!['video_title'] =
                      titleController.text;

                  video!['description'] =
                      descriptionController.text;

                  video!['music_title'] =
                      musicController.text;

                  video!['original_performer'] =
                      performerController.text;

                  video!['instrument'] =
                      instrumentController.text;
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Video updated (mockup only)',
                    ),
                  ),
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFFFFD600,
                ),
                foregroundColor:
                Colors.black,
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        const TextStyle(
          color: Colors.white60,
        ),
        enabledBorder:
        OutlineInputBorder(
          borderSide:
          const BorderSide(
            color: Colors.white24,
          ),
          borderRadius:
          BorderRadius.circular(8),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderSide:
          const BorderSide(
            color:
            Color(0xFFFFD600),
          ),
          borderRadius:
          BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
          const Color(0xFF1C1C1C),

          title: const Text(
            'Delete Video?',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          content: const Text(
            'Are you sure you want to delete this video?',
            style: TextStyle(
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

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Delete is not connected yet',
                    ),
                  ),
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.redAccent,
                foregroundColor:
                Colors.white,
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}