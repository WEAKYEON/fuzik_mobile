import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class YouTubeScreen extends StatefulWidget{
  final String videourl;
  const YouTubeScreen({super.key, required this.videourl});
  @override
  State<YouTubeScreen> createState()=> _YouTubeScreenState();
}

class _YouTubeScreenState extends State<YouTubeScreen>{
  late final YoutubePlayerController controller;
  bool _startvideo=false;
  
  @override
  void initState(){
    super.initState();
    final videoId=YoutubePlayerController.convertUrlToId(widget.videourl);
    controller=YoutubePlayerController.fromVideoId(
      videoId:videoId!, 
      autoPlay: true, 
      params: const YoutubePlayerParams(
        showControls:true,showFullscreenButton: false,playsInline: true,showVideoAnnotations: false,enableCaption: false
        )
        );  
  }

  @override
  void dispose(){
    controller.close();
    super.dispose();}

  @override
  Widget build(BuildContext context){
    bool youtubestyle=false;
    return Container(
      child:
    _startvideo? YoutubePlayer(
      controller:controller,
      aspectRatio: 16/9,
    ):
    YoutubePlayerThumbnail(
    controller: controller,
    playIcon:IconButton(
      icon: const Icon(Icons.play_circle_fill_rounded,color: Colors.yellow,size: 100,),
      onPressed: (){
        setState(() {
          _startvideo=true;
        });
      },
    ),
  
  aspectRatio: 16 / 9,
  thumbnailQuality: ThumbnailQuality.high,
  thumbnailFormat: ThumbnailFormat.webp,
  ),
  
    );
    
  }
}
