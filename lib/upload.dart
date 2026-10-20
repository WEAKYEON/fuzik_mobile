import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

class UploadContent extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onUploadSuccess;

  const UploadContent({
    super.key,
    required this.isActive,
    this.onUploadSuccess,
  });

  @override
  State<UploadContent> createState() => _UploadContentState();
}

class _UploadContentState extends State<UploadContent> {
  bool _isFileSelected = false;
  bool _acceptTerms = false;
  bool _isPublicDomain = false;

  File? _selectedVideo;
  VideoPlayerController? _videoPlayerController;

  final _videoTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _musicTitleController = TextEditingController();
  final _originalWriterController = TextEditingController();
  final _instrumentController = TextEditingController();

  @override
  void didUpdateWidget(covariant UploadContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && !_acceptTerms) {
      Future.delayed(Duration.zero, () {
        _showAgreementDialog();
      });
    }
  }

  @override
  void dispose() {
    _videoTitleController.dispose();
    _descriptionController.dispose();
    _musicTitleController.dispose();
    _originalWriterController.dispose();
    _instrumentController.dispose();

    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        setState(() {
          _selectedVideo = File(video.path);
          _isFileSelected = true;
        });

        _videoPlayerController = VideoPlayerController.file(_selectedVideo!)
          ..initialize().then((_) {
            setState(() {});
            _videoPlayerController!.play(); // สั่งให้เล่นอัตโนมัติ
          });

      }
    } catch (e) {
      print('เกิดข้อผิดพลาดในการเลือกไฟล์: $e');
    }
  }

  void _resetUploadForm() {
    setState(() {
      _isFileSelected = false;
      _acceptTerms = false;
      _isPublicDomain = false;

      _selectedVideo = null;

      _videoTitleController.clear();
      _descriptionController.clear();
      _musicTitleController.clear();
      _originalWriterController.clear();
      _instrumentController.clear();

      _videoPlayerController?.dispose();
      _videoPlayerController = null;
    });
  }

  Future<void> _uploadVideo() async {
    if (_selectedVideo == null) {
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://media05.fuzikapp.com/ajax_video.php'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _selectedVideo!.path,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final videoLocation = responseBody.trim();

      print('UPLOAD STATUS: ${response.statusCode}');
      print('UPLOAD RESPONSE: $videoLocation');

      if (!mounted) return;

      if (response.statusCode != 200 || videoLocation.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video upload failed.'),
          ),
        );
        return;
      }

      // Get logged-in user's email
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null || user.email == null) {
        print('MUSICIAN EMAIL: NOT FOUND');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User email not found.'),
          ),
        );
        return;
      }

      // vd dimensions
      final videoSize = _videoPlayerController?.value.size;

      final double width = videoSize?.width ?? 0;
      final double height = videoSize?.height ?? 0;

      final String dimension = width >= height ? 'L' : 'P';

      print('VIDEO WIDTH: $width');
      print('VIDEO HEIGHT: $height');
      print('VIDEO DIMENSION: $dimension');
      print('MUSICIAN EMAIL: ${user.email}');

      //save vd info to PlayVideo2
      final saveUri = Uri.https(
        'engine01.fuzikapp.com',
        '/upload_playvideo2',
        {
          'video_title': _videoTitleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'music_title': _musicTitleController.text.trim(),
          'video_location': videoLocation,
          'original': _originalWriterController.text.trim(),
          'instrument': _instrumentController.text.trim(),
          'musician2_email': user.email!,
          'dimension': dimension,
          'width': width.toInt().toString(),
          'height': height.toInt().toString(),
          'accept': _acceptTerms ? '1' : '0',
          'public_domain': _isPublicDomain ? '1' : '0',
        },
      );

      print('SAVE VIDEO URL: $saveUri');

      final saveResponse = await http.get(saveUri);

      print('SAVE VIDEO STATUS: ${saveResponse.statusCode}');
      print('SAVE VIDEO RESPONSE: ${saveResponse.body}');

      if (!mounted) return;

      if (saveResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded successfully!'),
          ),
        );

        _resetUploadForm();
        widget.onUploadSuccess?.call();
      } else {
        print('Video information save failed: ${saveResponse.statusCode}');
      }
    } catch (e) {
      print('Upload error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload error: $e'),
        ),
      );
    }
  }

  void _showAgreementDialog() {
    double dialogWidth = MediaQuery.of(context).size.width * 0.9;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2B3240),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Service agreement', style: TextStyle(color: Colors.white, fontSize: 16)),
              IconButton(icon: const Icon(Icons.close, color: Colors.white54, size: 20), onPressed: () => Navigator.pop(context)),
            ],
          ),
          content: SizedBox(
            width: dialogWidth,
            child: const SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Content: Upload only music-playing video clips.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  SizedBox(height: 8),
                  Text('2. Ownership: Ensure rights/consent.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  SizedBox(height: 8),
                  Text('3. Music Type: Classical/Public Domain only.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD600), foregroundColor: Colors.black),
              child: const Text('I agree'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return _isFileSelected ? _buildFormStep(isMobile) : _buildSelectFileStep();
  }

  Widget _buildSelectFileStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          width: double.infinity, height: 200,
          decoration: BoxDecoration(color: Colors.black, border: Border.all(color: const Color(0xFFFFD600), width: 1.5)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.download_for_offline_outlined, color: Colors.white, size: 40),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickVideo,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD600), foregroundColor: Colors.black),
                child: const Text('Select Video files', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormStep(bool isMobile) {
    Widget layout = isMobile
        ? Column(children: [_buildVideoPreview(), const SizedBox(height: 20), _buildFormFields()])
        : Row(children: [Expanded(flex: 5, child: _buildVideoPreview()), const SizedBox(width: 40), Expanded(flex: 4, child: _buildFormFields())]);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: _resetUploadForm,
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              label: const Text('Back to select', style: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 16),
            // --- จบปุ่ม Back ---

            layout,
          ],
        ),
      ),
    );
  }

  // <--- 5. เปลี่ยนกล่องดำ เป็น Video Player ของจริง
  Widget _buildVideoPreview() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 1)
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _videoPlayerController != null && _videoPlayerController!.value.isInitialized
            ? Stack(
          alignment: Alignment.center,
          children: [
            // ตัวเล่นวิดีโอ
            AspectRatio(
              aspectRatio: _videoPlayerController!.value.aspectRatio,
              child: VideoPlayer(_videoPlayerController!),
            ),
            // ปุ่ม Play/Pause กลางจอ
            GestureDetector(
              onTap: () {
                setState(() {
                  _videoPlayerController!.value.isPlaying
                      ? _videoPlayerController!.pause()
                      : _videoPlayerController!.play();
                });
              },
              child: Icon(
                _videoPlayerController!.value.isPlaying
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_fill,
                color: Colors.white.withOpacity(0.7),
                size: 64,
              ),
            ),
          ],
        )
            : const Center(
          // หมุนๆ ตอนกำลังโหลดวิดีโอ
          child: CircularProgressIndicator(color: Color(0xFFFFD600)),
        ),
      ),
    );
  }

  Widget _buildFormFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Video Information
      const Text(
        'Video Information',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),

      _buildWhiteTextField(
        'Video Title',
        controller: _videoTitleController,
      ),

      const SizedBox(height: 12),

      _buildWhiteTextField(
        'Description',
        controller: _descriptionController,
        maxLines: 3,
      ),

      const SizedBox(height: 24),

      // Music Information
      const Text(
        'Music Information',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 12),

      _buildWhiteTextField(
        'Music Title',
        controller: _musicTitleController,
      ),

      const SizedBox(height: 12),

      _buildWhiteTextField(
        'Original Artist',
        controller: _originalWriterController,
      ),

      const SizedBox(height: 12),

      _buildWhiteTextField(
        'Instrument',
        controller: _instrumentController,
      ),

      const SizedBox(height: 20),

      _buildCheckbox(
        'I accept the terms.',
        _acceptTerms,
            (val) => setState(() => _acceptTerms = val!),
      ),

      _buildCheckbox(
        'Public domain declaration.',
        _isPublicDomain,
            (val) => setState(() => _isPublicDomain = val!),
      ),

      const SizedBox(height: 20),

      ElevatedButton(
        onPressed: (_acceptTerms && _isPublicDomain)
            ? _uploadVideo
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD600),
          disabledBackgroundColor: Colors.grey,
        ),
        child: const Text(
          'Save information',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ],
  );

  Widget _buildWhiteTextField(String hint, {required TextEditingController controller, int maxLines = 1}) => TextField(controller: controller, maxLines: maxLines, style: const TextStyle(color: Colors.black), decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)));

  Widget _buildCheckbox(String text, bool value, Function(bool?) onChanged) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 24, height: 24, child: Checkbox(value: value, onChanged: onChanged, fillColor: WidgetStateProperty.resolveWith((states) => Colors.white), checkColor: Colors.black)), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)))]);
}
