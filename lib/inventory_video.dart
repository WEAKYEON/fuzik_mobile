
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

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
  static const String baseUrl = 'https://engine01.fuzikapp.com';

  Map<String, dynamic>? video;

  bool isLoading = true;
  VideoPlayerController? _videoController;
  bool _playerError = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }


  Future<void> _loadVideo() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/play2_watch?p=${Uri.encodeComponent(widget.videoUrl)}',
        ),
      );

      print('INVENTORY VIDEO STATUS: ${response.statusCode}');
      print('INVENTORY VIDEO RESPONSE: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load video');
      }

      final data = jsonDecode(response.body);

      if (data is List && data.isNotEmpty) {
        final loadedVideo = Map<String, dynamic>.from(data[0]);

        if (!mounted) return;

        setState(() {
          video = loadedVideo;
          isLoading = false;
        });

        final videoLocation =
            loadedVideo['video_location']?.toString() ?? '';

        print('VIDEO LOCATION: $videoLocation');

        if (videoLocation.isNotEmpty) {
          await _initializeVideo(videoLocation);
        }

        if (widget.autoEdit && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showEditDialog();
            }
          });
        }

      } else {
        throw Exception('Video not found');
      }
    } catch (e) {
      print('INVENTORY VIDEO ERROR: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load video: $e'),
        ),
      );
    }
  }

  Future<void> _addViewCount() async {
    try {
      final email = video?['musician_email']?.toString() ?? '';

      if (email.isEmpty) {
        print('VIEW ERROR: musician email is empty');
        return;
      }

      final response = await http.get(
        Uri.parse(
          '$baseUrl/add_play2_count'
              '?p=${Uri.encodeComponent(widget.videoUrl)}'
              '&email=${Uri.encodeComponent(email)}',
        ),
      );

      print('VIEW STATUS: ${response.statusCode}');
      print('VIEW RESPONSE: ${response.body}');
    } catch (e) {
      print('VIEW ERROR: $e');
    }
  }


  Future<void> _initializeVideo(String url) async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
      );

      _videoController = controller;

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _playerError = false;
      });


      await _addViewCount();

    } catch (e) {
      print('VIDEO PLAYER ERROR: $e');

      if (!mounted) return;

      setState(() {
        _playerError = true;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
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
        video!['original_performer']?.toString() ?? '';

    final instrument =
        video!['instrument']?.toString() ?? '';

    final views =
        video!['view_count']?.toString() ?? '';

    final createdTime =
        video!['created_time']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFD600),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildPlayer(),
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

          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: Icon(
                  Icons.music_note,
                  color: Colors.black,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      '$views views • $createdTime',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFFFFD600),
                    foregroundColor: Colors.black,
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showDeleteDialog,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(
                      color: Colors.redAccent,
                    ),
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    shape:
                    RoundedRectangleBorder(
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

  Widget _buildPlayer() {
    if (_playerError) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                color: Colors.white54,
                size: 42,
              ),
              SizedBox(height: 8),
              Text(
                'Video preview unavailable',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _videoController;

    if (controller == null ||
        !controller.value.isInitialized) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(
            Icons.play_circle_fill,
            color: Colors.white70,
            size: 60,
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [

        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),

        GestureDetector(
          onTap: () {
            setState(() {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
            });
          },
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white70,
            ),
            padding: const EdgeInsets.all(5),
            child: Icon(
              controller.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.black,
              size: 40,
            ),
          ),
        ),
      ],
    );
  }


  void _showEditDialog() {
    final titleController = TextEditingController(
      text: video!['video_title']?.toString() ?? '',
    );

    final descriptionController =
    TextEditingController(
      text: video!['description']?.toString() ?? '',
    );

    final musicController = TextEditingController(
      text: video!['music_title']?.toString() ?? '',
    );

    final performerController =
    TextEditingController(
      text:
      video!['original_performer']?.toString() ??
          '',
    );

    final instrumentController =
    TextEditingController(
      text: video!['instrument']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),

          title: const Text(
            'Edit Video',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                _buildEditField(
                  controller: titleController,
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
                  controller: musicController,
                  label: 'Music Title',
                ),

                const SizedBox(height: 14),

                _buildEditField(
                  controller:
                  performerController,
                  label: 'Original Performer',
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

                // MOCKUP ONLY

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
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFFFD600),
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
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
        labelStyle: const TextStyle(
          color: Colors.white60,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.white24,
          ),
          borderRadius:
          BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Color(0xFFFFD600),
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
              fontWeight: FontWeight.bold,
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

                // MOCKUP ONLY


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
              style: ElevatedButton.styleFrom(
                backgroundColor:
                Colors.redAccent,
                foregroundColor: Colors.white,
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
      const EdgeInsets.only(bottom: 12),
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
