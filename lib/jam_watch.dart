import 'dart:async';
import 'package:flutter/material.dart';
import 'collaboration.dart'; 
import 'httpsVideoPlayer.dart';
import 'youtube_player.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fuzik_mobile/services/fetch_videos.dart';

class JamWatchScreen extends StatefulWidget {
  final String title;
  final String youTubeCode;
  final String profileUrl;
  final String description;
  final String videoUrl;
  final bool isSolo;
  final String previewUrl;
  const JamWatchScreen({
    super.key,
    required this.title,
    required this.youTubeCode,
    required this.profileUrl,
    required this.description,
    required this.videoUrl,
    this.isSolo=false,
    required this.previewUrl
  });

  @override
  State<JamWatchScreen> createState()=>_JamWatchScreenState();
}

class _JamWatchScreenState extends State<JamWatchScreen>{
  Video videoDetail=Video();
  String videoInitializationError='';
  String video01_instrument='';
  String video02_instrument='';
  String video03_instrument='';
  String video04_instrument=''; 
  String owner_display_name='';
  String owner_display_pic='';
  bool isLoading=true;

  Future<void> initializeVideoDetails() async{
    final result =  await getVideoDetail(isSolo: widget.isSolo,videoUrl: widget.videoUrl);
    if(!mounted){
      return;
    }
    
     if (result.hasError || result.videoDetail.isEmpty) {
    setState(() {
      videoInitializationError =
          result.hasError ? result.error : 'Video not found.';
      isLoading = false;
    });
    return;
  }

    setState(() {
      videoDetail=result;
    });
    final data=videoDetail.videoDetail[0];
    setState((){
    video01_instrument=data['video01_instrunment']?.toString()??"";
    video02_instrument=data['video02_instrunment']?.toString()??"";
    video03_instrument=data['video03_instrunment']?.toString()??"";
    video04_instrument=data['video04_instrunment']?.toString()??"";
    owner_display_name=data['owner_display_name']?.toString()??"";
    isLoading=false;
    });

  }

  String cleanText(String? raw) {
  if (raw == null) return '';
  return raw
      .replaceAll(RegExp(r'\\+n'), '\n') // one or more backslashes + n -> real newline
      .trim();
}

  @override
  void initState() {
    super.initState();
    initializeVideoDetails();
  }
  @override
  Widget build(BuildContext context) {
    print('Owner: $owner_display_name');
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

             Text(
              cleanText(widget.description),
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: Icon(Icons.music_note, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created by $owner_display_name',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '33 views • 11 months ago',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CollaborationContent(showBackButton: true),
                          ),
                        );
                        print("Go to Collaboration Screen");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD600), // สีเหลือง
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Join Jam',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Wrap(
                  spacing: 12, 
                  runSpacing: 12, 
                  children: [
                    _buildPillButton(Icons.remove, 'Fans', const Color(0xFFFFB300)),
                    _buildPillButton(Icons.remove, 'Like', const Color(0xFFFFB300)),
                    _buildPillButton(Icons.share, 'Share', const Color(0xFFFFB300)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            
            const Divider(color: Colors.white24, thickness: 1),
            
            const SizedBox(height: 16),

            // 4. Description section
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
              'This collaboration consists of:\n'
              'Pop Rock Backing Track | Guitar Solo | E Major | 81 BPM\n'
              'Guitar Pop Rock Backing Track | Guitar | E Major | 81 BPM\n'
              'Bass Pop Rock Backing Track | Bass | F Major | 81 BPM\n'
              'Drums Pop Rock Backing Track | Drums | E Major | 81 BPM',
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

  Widget _buildPillButton(IconData icon, String label, Color iconColor) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: iconColor, size: 18),
      label: Text(
        label,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
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
    return YouTubeScreen(youTubeurl: 'https://www.youtube.com/watch?v=${widget.youTubeCode}'); // your existing widget
  }
  if (isLoading) {
    return const AspectRatio(
      aspectRatio: 16 / 9,
      child: Center(child: CircularProgressIndicator()),
    );
  }
  if (videoInitializationError.isNotEmpty) {
    return Center(child: Text(videoInitializationError));
  }
  return HttpsVideoPlayer(
    videoUrl: widget.videoUrl,
    isSolo: widget.isSolo,
    previewUrl: widget.previewUrl,
    videoDetail: videoDetail,
  );
}
}

class Video{
  final String error;
  final List<dynamic> videoDetail;
  const Video({this.error='',this.videoDetail=const[]});

  bool get hasError=>error.isNotEmpty;
}

Future<Video> getVideoDetail({bool isSolo=false, String videoUrl=''}) async{
    if(!await hasNetwork()){
      return Video(error: 'No connection. Please connect to network');
    }
    try{
      final url=isSolo? Uri.parse('https://engine01.fuzikapp.com/play2_watch?p=${videoUrl}'):Uri.parse('https://engine01.fuzikapp.com/jam2_watch?j=${videoUrl}');
      print(url);
      final response = await http.get(url).timeout(Duration(seconds: 30));
      if(response.statusCode==500){
        return Video(error:'Sorry. Internal Server error. Please try again later.');
      }
      if(response.statusCode==200){
        final videoDetail=List<dynamic>.from(jsonDecode(response.body));
        return Video(videoDetail: videoDetail);
      }
      return Video(error: 'Sorry. Cannot get the video. Please try again.');
    }on TimeoutException{
      return Video(error: 'Sorry. Your connection is too slow.');
    }on SocketException {
    return const Video(error: 'Could not reach the server. Check your connection.');
    } on FormatException {
    return const Video(error: 'Received an unexpected response from the server.');
    } 
    catch(e){
      return Video(error: 'Cannot get the video. Error: $e');
    }
  }