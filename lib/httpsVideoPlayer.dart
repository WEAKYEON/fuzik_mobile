import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fuzik_mobile/services/fetch_videos.dart'; 

class HttpsVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const HttpsVideoPlayer({super.key,required this.videoUrl});

  @override
  State<HttpsVideoPlayer> createState()=>_HttpsVideoPlayer();
}

class _HttpsVideoPlayer extends State<HttpsVideoPlayer>{
  late VideoPlayerController _controller;
  late Future<Video> videoDetail;
  String videoError = '';
  bool isLoading = true;
  Future<Video> getVideoDetail() async{
    if(!await hasNetwork()){
      return Video(error: 'No connection. Please connect to network');
    }
    try{
      final url=Uri.parse('https://engine01.fuzikapp.com/play2_watch?p=${widget.videoUrl}');
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
  
  Future<void> initializeVideo() async {
  final result = await getVideoDetail();

  if (!mounted) return;

  if (result.hasError) {
    setState(() {
      videoError = result.error;
      isLoading = false;
    });
    return;
  }

  // Extract the video URL from the API response.
  final url = result.videoDetail[0]['video_location'].toString();
  _controller = VideoPlayerController.networkUrl(
    Uri.parse(url), httpHeaders: {'Referer':'https://fuzikapp.com'}
  );

  try {
    await _controller.initialize();

    if (!mounted) {
      _controller.dispose();
      return;
    }

    setState(() {
      isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      videoError = 'Failed to initialize video: $e';
      isLoading = false;
    });
  }
}

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }
  @override
  void dispose(){
    _controller.dispose();
    super.dispose();
  }
 @override
Widget build(BuildContext context) {
  if (isLoading) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  if (videoError.isNotEmpty) {
    return Center(
      child: Text(videoError),
    );
  }

  if (_controller == null || !_controller.value.isInitialized) {
    return const SizedBox.shrink();
  }
  
    return Column(
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                children: [
                  VideoPlayer(_controller),
                    Center(
                      child: ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: _controller,
                      builder: (context, value, child) {
                      return IconButton(
                        iconSize: 100,
                        color:Colors.yellow,
                        icon: Icon(value.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
                        onPressed: () {
                        value.isPlaying ? _controller.pause() : _controller.play();
                      },
                      );
                      },
                      ),
                    )
                ],
              ),
            ),
              VideoProgressIndicator(_controller, allowScrubbing: true),
            ],
          );
}
}


class Video{
  final String error;
  final List<dynamic> videoDetail;
  const Video({this.error='',this.videoDetail=const[]});

  bool get hasError=>error.isNotEmpty;
}