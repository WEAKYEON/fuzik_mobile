import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'youtube_player.dart';

class InventoryVideoScreen extends StatefulWidget {
  final String videoUrl;
  final bool autoEdit;
  final bool isPublished;
  final Map<String, dynamic>? inventoryVideo;

  const InventoryVideoScreen({
    super.key,
    required this.videoUrl,
    required this.isPublished,
    this.autoEdit = false,
    this.inventoryVideo,
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
  bool _isPublished = false;

  String? _profilePicturePath;
  int viewCount = 0;

  @override
  void initState() {
    super.initState();
    _isPublished = widget.isPublished;
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

      debugPrint(
        'INVENTORY VIDEO RESPONSE: ${response.body}',
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
        await _getViewCount();

        if (widget.autoEdit && mounted) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            if (mounted) {
              _showEditDialog();
            }
          });
        }
      } else if (widget.inventoryVideo != null) {
        if (!mounted) return;

        setState(() {
          video = Map<String, dynamic>.from(
            widget.inventoryVideo!,
          );
          isLoading = false;
        });

        if (widget.autoEdit && mounted) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            if (mounted) {
              _showEditDialog();
            }
          });
        }
      } else if (widget.inventoryVideo != null) {
        if (!mounted) return;

        setState(() {
          video = Map<String, dynamic>.from(
            widget.inventoryVideo!,
          );
          isLoading = false;
        });

        if (widget.autoEdit && mounted) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            if (mounted) {
              _showEditDialog();
            }
          });
        }

      } else if (widget.inventoryVideo != null) {
        if (!mounted) return;

        setState(() {
          video = Map<String, dynamic>.from(
            widget.inventoryVideo!,
          );
          isLoading = false;
        });

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
          Supabase.instance.client.auth.currentUser?.email ?? '';

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

  Future<void> _getViewCount() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/get_play2_count'
              '?p=${Uri.encodeComponent(widget.videoUrl)}',
        ),
      );

      debugPrint(
        'GET VIEW STATUS: ${response.statusCode}',
      );

      debugPrint(
        'GET VIEW RESPONSE: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          setState(() {
            viewCount = data[0]['view_count'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint(
        'GET VIEW ERROR: $e',
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context, true);
          },
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

    final isPublished = _isPublished;

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

    final views = viewCount.toString();

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

          // EDIT, publish/unpublish

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showEditDialog,
                  icon: const Icon(
                    Icons.edit,
                    size: 18,
                  ),
                  label: const Text(
                    'Edit Video',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white24,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showPublishDialog();
                  },
                  icon: Icon(
                    isPublished
                        ? Icons.lock
                        : Icons.public,
                    size: 18,
                  ),
                  label: Text(
                    isPublished
                        ? 'Set Private'
                        : 'Set Public',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.white24,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
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

  Future<void> _updateVideo({
    required String title,
    required String description,
    required String musicTitle,
    required String originalPerformer,
    required String instrument,
  }) async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null || user.email == null) {
      throw Exception(
        'User is not logged in',
      );
    }

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/modify_playvideo2'
              '?p=${Uri.encodeComponent(
            widget.videoUrl,
          )}'
              '&musician2_email=${Uri.encodeComponent(
            user.email!,
          )}'
              '&video_title=${Uri.encodeComponent(
            title,
          )}'
              '&description=${Uri.encodeComponent(
            description,
          )}'
              '&music_title=${Uri.encodeComponent(
            musicTitle,
          )}'
              '&original=${Uri.encodeComponent(
            originalPerformer,
          )}'
              '&instrument=${Uri.encodeComponent(
            instrument,
          )}',
        ),
      );

      debugPrint(
        'UPDATE VIDEO STATUS: ${response.statusCode}',
      );

      debugPrint(
        'UPDATE VIDEO RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update video',
        );
      }

      final data = jsonDecode(response.body);

      final result =
      data is List && data.isNotEmpty
          ? data[0]['result']?.toString()
          : null;

      if (result != 'Success') {
        throw Exception(
          data is List && data.isNotEmpty
              ? data[0]['description']?.toString()
              : 'Unknown error',
        );
      }

      if (!mounted) return;

      setState(() {
        video!['video_title'] = title;
        video!['description'] = description;
        video!['music_title'] = musicTitle;
        video!['original_performer'] =
            originalPerformer;
        video!['instrument'] = instrument;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Video updated',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'UPDATE VIDEO ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update video: $e',
          ),
        ),
      );
    }
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
              onPressed: () async {
                await _updateVideo(
                  title: titleController.text,
                  description:
                  descriptionController.text,
                  musicTitle:
                  musicController.text,
                  originalPerformer:
                  performerController.text,
                  instrument:
                  instrumentController.text,
                );

                if (!mounted) return;

                Navigator.pop(context);
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

  void _showPublishDialog() {
    final isPublished = _isPublished;

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
                _togglePublish();
              },
              style: ElevatedButton.styleFrom(
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

  Future<void> _togglePublish() async {
    final user =
        Supabase.instance.client.auth.currentUser;

    if (user == null || user.email == null) {
      return;
    }

    final isPublished = _isPublished;

    final endpoint = isPublished
        ? 'unpublish_playvideo2'
        : 'publish_playvideo2';

    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/$endpoint'
              '?p=${Uri.encodeComponent(
            widget.videoUrl,
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

      final data = jsonDecode(response.body);

      final result =
      data is List && data.isNotEmpty
          ? data[0]['result']?.toString()
          : null;

      if (result == 'Success' ||
          result == 'Already Published' ||
          result == 'Already Unpublished') {
        if (!mounted) return;

        setState(() {
          _isPublished = !_isPublished;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPublished
                  ? 'Video unpublished'
                  : 'Video published',
            ),
          ),
        );


      } else {
        throw Exception(
          data is List && data.isNotEmpty
              ? data[0]['description']?.toString()
              : 'Unknown error',
        );
      }
    } catch (e) {
      debugPrint(
        'PUBLISH ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update video: $e',
          ),
        ),
      );
    }
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