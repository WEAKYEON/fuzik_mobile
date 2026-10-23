import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'jam_watch.dart';

import 'package:cached_network_image/cached_network_image.dart';

class HttpsVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isSolo;
  final String previewUrl;
  final Video videoDetail;
  const HttpsVideoPlayer({super.key,required this.videoUrl, this.isSolo=true, this.previewUrl='',  this.videoDetail=const Video()});

  @override
  State<HttpsVideoPlayer> createState()=>_HttpsVideoPlayer();
}

class _HttpsVideoPlayer extends State<HttpsVideoPlayer>{
  late VideoPlayerController _controller;
  bool hasController=false;
  String videoError = '';
  bool isLoading = true;
  
  Future<void> initializeVideo() async {
  final result = widget.isSolo? await getVideoDetail(isSolo: widget.isSolo,videoUrl: widget.videoUrl): widget.videoDetail;

  if (!mounted) return;

  if (result.hasError) {
    setState(() {
      videoError = result.error;
      isLoading = false;
    });
    return;
  }

  // Extract the video URL from the API response.
  final jamFileLocation=widget.isSolo?'':'https://media05.fuzikapp.com/${result.videoDetail[0]['file_location'].toString()}';
  final url =widget.isSolo? result.videoDetail[0]['video_location'].toString(): jamFileLocation;
  _controller = VideoPlayerController.networkUrl(
    Uri.parse(url), httpHeaders: {'Referer':'https://fuzikapp.com'}
  );

  try {
    hasController=true;
    await _controller.initialize();
    
    if (!mounted) {
      hasController=false;
      _controller.dispose();
      return;
    }

    setState(() {
      isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;
    _controller.dispose();
    setState(() {
      videoError = 'Failed to initialize video: $e';
      isLoading = false;
      hasController=false;
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
    if(hasController){
     _controller.dispose();
    }
    super.dispose();
  }
 @override
Widget build(BuildContext context) {
  if (isLoading) {
    return const Center(
      child: SizedBox(width: 50, height: 50, child: CircularProgressIndicator(color:Colors.yellow)),
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
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _controller,
                builder: (context, value, child) {
                  // Show the poster until the video position moves past zero
                  final showPoster = value.position == Duration.zero && !widget.isSolo;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      VideoPlayer(_controller),
                      if (showPoster)
                        CachedNetworkImage(
                          imageUrl: widget.previewUrl,
                          fit:BoxFit.cover,
                          placeholder: (context, url) => SizedBox(width:50, height: 50, child: CircularProgressIndicator(color: Colors.yellow,)),
                          ),
                      Center(
                        child: IconButton(
                          iconSize: 100,
                          color: Colors.yellow,
                          icon: Icon(value.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded),
                          onPressed: () {
                            value.isPlaying ? _controller.pause() : _controller.play();
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
              VideoProgressIndicator(_controller, allowScrubbing: true),
            ],
          );
}
}

