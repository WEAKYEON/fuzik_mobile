import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YouTubeScreen extends StatefulWidget{
  final String youTubeurl;
  const YouTubeScreen({super.key, required this.youTubeurl});
  @override
  State<YouTubeScreen> createState()=> _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen>{
  YoutubePlayerController? controller;
  
  bool _startvideo=false;
  bool _isValidVideo = false;
  
  @override
  void initState(){
    super.initState();
    final videoId=YoutubePlayerController.convertUrlToId(widget.youTubeurl);
    if (videoId == null || videoId.isEmpty) {
      _isValidVideo = false;
      return;
    }
    _isValidVideo = true;

    controller=YoutubePlayerController.fromVideoId(
      videoId:videoId,
      autoPlay: true, 
      params: const YoutubePlayerParams(
        showControls:true,showFullscreenButton: true,playsInline: true,showVideoAnnotations: false,enableCaption: false
        )
        );  
  }

  @override
  void dispose(){
    controller?.close();
    super.dispose();}


  @override
  Widget build(BuildContext context) {
    if (!_isValidVideo || controller == null) {
      return const AspectRatio(
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
      );
    }

    return _startvideo
        ? YoutubePlayer(
      controller: controller!,
      aspectRatio: 16 / 9,
      autoFullScreen: false,
    )
        : YoutubePlayerThumbnail(
      controller: controller!,
      playIcon: IconButton(
        icon: const Icon(
          Icons.play_circle_fill_rounded,
          color: Colors.yellow,
          size: 70,
        ),
        onPressed: () {
          setState(() {
            _startvideo = true;
          });
        },
      ),
      aspectRatio: 16 / 9,
      thumbnailQuality:
      ThumbnailQuality.high,
      thumbnailFormat:
      ThumbnailFormat.webp,
    );
  }
}
