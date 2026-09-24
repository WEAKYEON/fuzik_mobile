import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'dart:io';
import 'package:just_waveform/just_waveform.dart'; 

class AdjustTimelineScreen extends StatefulWidget {
  final String layoutName;
  final List<Map<String,dynamic>> selectedVideos;

  const AdjustTimelineScreen({
    super.key,
    required this.layoutName,
    required this.selectedVideos,
  });

  @override
  State<AdjustTimelineScreen> createState() => _AdjustTimelineScreenState();
}

class _AdjustTimelineScreenState extends State<AdjustTimelineScreen> {
  late List<double> offsets ;
  final List<Color> trackColors = [Colors.redAccent, Colors.blueAccent, Colors.greenAccent, Colors.orangeAccent];
  late List<AudioPlayer> players;
  late List<Waveform?> waveforms;
  bool isMasterPlaying=false;

Future<File> getCachedAudio(String videoCode, String videoUrl) async{
    final cacheDir= await getTemporaryDirectory();
    final audioFile=File('${cacheDir.path}/$videoCode.mp3');
    if(await audioFile.exists()){
      print('Using cached audio: ${audioFile.path}');
      return audioFile;
    }

    final videoFile = File('${cacheDir.path}/$videoCode.mp4',);
    if(!await videoFile.exists()){
      final response=await http.get(
        Uri.parse(videoUrl),
        headers: {
          'Referer':"https://fuzikapp.com",
        },
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download video: ${response.statusCode}',
        );
      }
      await videoFile.writeAsBytes(response.bodyBytes);
    }
    final session = await FFmpegKit.execute(
      '-i "${videoFile.path}" -vn -c:a copy "${audioFile.path}"',
    );
    final returnCode = await session.getReturnCode();

    if (returnCode?.isValueSuccess() ?? false) {
      print('getCachedAudio: Audio extracted: ${audioFile.path}');

      // Delete the video and will keep the audio only
      if (await videoFile.exists()) {
        await videoFile.delete();
        print('getCachedAudio: Temporary video deleted.');
      }
      return audioFile;
      }
    throw Exception('getCachedAudio: FFmpeg failed to extract audio');
}

//Play a single track
Future<void> playTrack(int index) async {
  final player = players[index];
  final delay = offsets[index] / 50.0;

  if (delay > 0) {
    await Future.delayed(
      Duration(
        milliseconds: (delay * 1000).round(),
      ),
    );
    await player.seek(Duration.zero);
  } else if (delay < 0) {
    await player.seek(
      Duration(
        milliseconds: (-delay * 1000).round(),
      ),
    );
  } else {
    await player.seek(Duration.zero);
  }
  await player.play();
}

Future<void> _initializeAudio() async{
    for(int i=0; i<widget.selectedVideos.length;i++){
      final videoCode=widget.selectedVideos[i]['url'];
      final videoPlay2WatchUrl=Uri.parse('https://engine01.fuzikapp.com/play2_watch?p=$videoCode');
      try{
        final response= await http.get(videoPlay2WatchUrl);
        final data= jsonDecode(response.body);
        
        final videoLocation=data[0]['video_location_120'];

        //Get Audio File (Extracted audio)
        final audioFile = await getCachedAudio(
        videoCode,
        videoLocation,
      );
      print('_initializeAudio: VIDEO $i AUDIO: ${audioFile.path}');
        try{
          await players[i].setFilePath(audioFile.path,);
          await generateWaveform(i, audioFile);
        }catch(e){
          debugPrint('_initializeAudio: Failed to load audio $i : $e');
        }
      }catch (e, stackTrace) {
        
        print('_initializeAudioFunction: INITIALIZATION ERROR PLAYER $i');
        print(e);
        print(stackTrace);
      }
    }
  }

  Future<void> togglePlay(int index)async{
    final player=players[index];
    await player.setLoopMode(LoopMode.off);
    if(player.processingState==ProcessingState.completed){
      await player.seek(Duration.zero);
    }
    if(player.playing){
      await player.pause();
      return;
    }
    await playTrack(index);
  }

Future<void> playAllTracks() async {
  setState(() {
    isMasterPlaying=true;
  });
  await Future.wait(
    List.generate(
      players.length,
      (i) => playTrack(i),
    ),
  );
}

Future<void> pauseAllTracks() async {
  for (final player in players) {
    await player.pause();
  }
  setState(() {
    isMasterPlaying = false;
  });
}

  Future<void> startOver(int index) async {
  final player = players[index];

  await player.seek(Duration.zero);
  await player.play();
}
  @override
  void initState(){
    super.initState();
    offsets = List<double>.filled(widget.selectedVideos.length, 0.0);
    players = List.generate(widget.selectedVideos.length, 
    (_)=>AudioPlayer());
    waveforms = List<Waveform?>.filled(
      widget.selectedVideos.length,
      null,
    );
    _initializeAudio();
  }

Future<void> generateWaveform(
  int index,
  File audioFile,
) async {
  try {
    final cacheDir = await getTemporaryDirectory();

    final waveformFile = File(
      '${cacheDir.path}/${widget.selectedVideos[index]['url']}.wave',
    );

    print('Generating waveform for track $index...');

    final progressStream = JustWaveform.extract(
      audioInFile: audioFile,
      waveOutFile: waveformFile,
      zoom: const WaveformZoom.pixelsPerSecond(50),
    );

    await for (final progress in progressStream) {

      if (progress.waveform != null) {
        if (!mounted) return;

        setState(() {
          waveforms[index] = progress.waveform;
        });

        print('Waveform ready for track ${index+1}');
      }
    }
  } catch (e, stackTrace) {
    print('WAVEFORM ERROR $index');
    print(e);
    print(stackTrace);
  }
}
@override
void dispose(){
  for (final player in players){
    player.dispose();
  }
  super.dispose();
}
  @override
  Widget build(BuildContext context) {
  final isTablet= MediaQuery.of(context).size.shortestSide >= 600;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text('Adjust Timeline', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [   
            const Divider(color: Colors.white24, thickness: 1),
             
              SizedBox(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.selectedVideos.length, // จำนวนวิดีโอ
                  padding: const EdgeInsets.all(16.0),
                  itemBuilder: (context, index) {
                    return _buildTrackTimeline(index, isTablet: isTablet);
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      isMasterPlaying?
                      Icons.pause
                      :Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: isMasterPlaying? pauseAllTracks:playAllTracks,
                  ),

                  const SizedBox(width: 16),

                  IconButton(
                    icon: const Icon(
                      Icons.replay,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: (){},
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // ปุ่ม Generate Preview
                    
                    const SizedBox(height: 8),
                    
                    Container(
                      height: isTablet?200:120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFFFD600)),
                        color: Colors.black,
                      ),
                      alignment: Alignment.center,
                      child: const Text('Not available', style: TextStyle(color: Colors.white54)),
                    ),
                    const SizedBox(height: 10),
          
                    SizedBox(
                      width: isTablet?350:200,
                      child: Container(
                        
                        decoration: BoxDecoration(
                          
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: [BoxShadow(
                            color: Colors.yellow.withValues(alpha: 0.6),
                            blurRadius: 20,
                            spreadRadius: 2
                          )],
                        ),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD600),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          child: Text('Generate 20s Preview',style: TextStyle(fontSize: isTablet?17:9),),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40,),
                    SizedBox(
                      width: isTablet?350:200,
                      child: Container(       
                        decoration: BoxDecoration(                 
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: [BoxShadow(
                            color: Colors.yellow.withValues(alpha: 0.6),
                            blurRadius: 20,
                            spreadRadius: 2
                          )],
                        ),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD600),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)
                            ),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          child: Text('Send To Queue',style: TextStyle(fontSize: isTablet?17:9),),
                        ),
                      ),
                    ),
                    
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

//Tracks
Widget _buildTrackTimeline(int index, {required bool isTablet}) {
    double secondsDelay = offsets[index] / 50.0;
    final video = widget.selectedVideos[index];
    final preview = video['preview']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(             
                width: isTablet?200:100,
                height: isTablet?130:100,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: CachedNetworkImage(
                  imageUrl: preview,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                ),
              ),
              const SizedBox(width: 12),
              // ปุ่มปรับจังหวะละเอียด (< >)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    Container(
                            height: 130,
                            width: double.infinity,
                            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {                   
                      offsets[index] += details.delta.dx;
                      if (offsets[index] < 0) {
                        offsets[index] = 0;
                      }
                  });
                },
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: RulerPainter(),
                      ),
                    ),                   
                    Positioned(
                      left: offsets[index],
                      top: 20,
                      child: _buildWaveform(index),
                    ),
                  ],
                ),
                            ),
                          ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  //Waves
  Widget _buildWaveform(int index) {
  final waveform = waveforms[index];

  if (waveform == null) {
    return const SizedBox(
      width: 300,
      height: 80,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  final samples = waveform.data;

  return SizedBox(
    height: 80,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final sample in samples)
          Container(
  width: 2,
  height: sample.abs().toDouble().clamp(2, 70),
  margin: const EdgeInsets.symmetric(horizontal: 1),
  decoration: BoxDecoration(
    color: trackColors[index],
    borderRadius: BorderRadius.circular(10),
  ),
)
      ],
    ),
  );
}
}

class RulerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, 10), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}