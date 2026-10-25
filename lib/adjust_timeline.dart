import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'dart:io';
import 'dart:math' as math;
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
  final List<Color> trackColors = [const Color(0xFFFFFF12), Colors.yellow, Colors.yellow, Colors.yellow];
  late List<AudioPlayer> players;
  late List<Waveform?> waveforms;
  bool isMasterPlaying=false;
  double zoom = 1.0;
  double get pixelsPerSecond => 120.0 * zoom;
  late List<double> audioDelays;
  late List<double> volumes;
  late List<int> _playTokens;   // bump a track's token to cancel its pending start
  late List<bool> _waiting; 
  double timelineScroll=0.0;
  double _viewportWidth=300;
  late List<int> wavePeaks;
  static const double _badgeColumnWidth = 44;
  static const double _listPadding = 16; // the ListView's padding
  static const double _gapAfterBadge = 20;
  static const double _gapAfterThumb = 12;
  late List<bool> _volumeOpen;
  double guideSeconds=1.0;
  double get _guideX=> guideSeconds*pixelsPerSecond;
  bool get _anythingActive =>players.any((p) => p.playing) || _waiting.any((w) => w);
  double _thumbWidth(bool isTablet) => isTablet ? 200 : 100;

  double _scrollbarLeft(bool isTablet) =>
      _listPadding + _badgeColumnWidth + _gapAfterBadge +
      _thumbWidth(isTablet) + _gapAfterThumb;

int computePeak(Waveform w) {
  int peak = 1;
  for (int i = 0; i < w.length; i++) {
    peak = math.max(
      peak,
      math.max(w.getPixelMax(i).abs(), w.getPixelMin(i).abs()),
    );
  }
  return peak;
}

double get maxScroll =>(maxTimelineWidth - _viewportWidth).clamp(0.0, double.infinity);
  double get maxTimelineWidth {
    double maxWidth = 0.0;

  for (int i = 0; i < players.length; i++) {
    final duration = players[i].duration;

    if (duration != null) {
      final durationSeconds =
          duration.inMilliseconds / 1000.0;

      final endTime =
          audioDelays[i] + durationSeconds;

      final width =
          endTime * pixelsPerSecond + 100.0;

      if (width > maxWidth) {
        maxWidth = width;
      }
    }
  }

  return maxWidth;
}

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
    if (await audioFile.exists()) await audioFile.delete();
    throw Exception('getCachedAudio: FFmpeg failed to extract audio');
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

void _cancelPending(int i) {
  _playTokens[i]++;
  _waiting[i] = false;
}

// Master icon = "is anything playing or about to play"
void _syncMasterIcon() {
  if (!mounted) return;
  setState(() {
    isMasterPlaying =
        players.any((p) => p.playing) || _waiting.any((w) => w);
  });
}

Future<void> playTrack(int index, {double secondsDelay = 0.0}) async {
  final player = players[index];
  if (player.duration == null) return;        // audio failed to load / not ready

  final token = ++_playTokens[index];         // also cancels any older pending start

  if (secondsDelay > 0) {
    _waiting[index] = true;
    await Future.delayed(Duration(milliseconds: (secondsDelay * 1000).round()));
    if (!mounted || token != _playTokens[index]) return;  // cancelled
    _waiting[index] = false;
  }

  await player.seek(Duration.zero);
  if (!mounted || token != _playTokens[index]) return;
  await player.play();
}

Future<void> togglePlay(int index, double secondsDelay) async {
  final player = players[index];
  if (player.playing || _waiting[index]) {
    _cancelPending(index);
    await player.pause();
    _syncMasterIcon();
    return;
  }
  await playTrack(index, secondsDelay: secondsDelay);
}

Future<void> playAllTracks() async {
  setState(() {
    isMasterPlaying = true;
  });
  await Future.wait(List.generate(
    players.length,
    (i) => playTrack(i, secondsDelay: audioDelays[i]),
  ));
  _syncMasterIcon(); // all finished, paused or cancelled
}

Future<void> pauseAllTracks() async {
  for (int i = 0; i < players.length; i++) {
    _cancelPending(i);
  }
  await Future.wait(players.map((p) => p.pause()));
  _syncMasterIcon();
}

Future<void> startOver(int index) async {
  _cancelPending(index);
  final player = players[index];
  if (player.duration == null) return;
  await player.seek(Duration.zero);
  await player.play();
}

// Rewind only, no autoplay
Future<void> startOverAllTracks() async {
  for (int i = 0; i < players.length; i++) {
    _cancelPending(i);
  }
  await Future.wait(players.map((p) => p.pause()));
  await Future.wait(players.map((p) => p.seek(Duration.zero)));
  _syncMasterIcon(); // now false, since nothing is playing
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

    debugPrint('Generating waveform for track $index...');

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
          wavePeaks[index]=computePeak(progress.waveform!);
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
  void initState(){
    super.initState();
    audioDelays = List<double>.filled(widget.selectedVideos.length, 0.0);
    players = List.generate(widget.selectedVideos.length, 
    (_)=>AudioPlayer());
    waveforms = List<Waveform?>.filled(
      widget.selectedVideos.length,
      null,
    );
    _playTokens = List<int>.filled(widget.selectedVideos.length, 0);
    _waiting = List<bool>.filled(widget.selectedVideos.length, false);
    wavePeaks = List<int>.filled(widget.selectedVideos.length, 1);
    volumes = List<double>.filled(widget.selectedVideos.length, 1.0);
    _initializeAudio();

    for (final p in players) {
      p.processingStateStream.listen((state) async {
        if (state != ProcessingState.completed) return;
        await p.pause();
        _syncMasterIcon();
      });
    }
    _volumeOpen=List.filled(widget.selectedVideos.length, false);
  }
@override
void dispose() {
  for (int i = 0; i < _playTokens.length; i++) {
    _playTokens[i]++;
  }
  for (final player in players) {
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
        leading: const BackButton(color: Colors.yellow),
        title: const Text('Adjust Timeline', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [   
            const Divider(color: Colors.white24, thickness: 1),
             Center(
              child: const Text('Fine-tune your audio clips',style: TextStyle(fontSize: 15, color:Colors.white),),
             ),
             const SizedBox(height: 20,),
             SizedBox(
              width: double.infinity,
              height: 70,
               child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   SizedBox(
                    width:170,
                     child: Slider(
                      activeColor: Colors.yellow,
                      inactiveColor: Colors.yellowAccent.withValues(alpha: 0.2),
                      thumbColor: Colors.yellow,
                      overlayColor: WidgetStateProperty.all(Colors.yellow.withValues(alpha: 0.2)),
                      min: 1.0,
                      max: 4.0, 
                      divisions:7,
                      label:'${zoom.toStringAsFixed(1)}x',             
                      value: zoom,
                      onChanged: (value) {
                        setState(() {
                          zoom = value;
                          timelineScroll=timelineScroll.clamp(0.0, maxScroll);
                        });
                      },
                    ),
                   ),
                 ],
               ),
             ),
             Container(
              width:120,
              decoration: BoxDecoration(
                color:Colors.grey[850],
                borderRadius: BorderRadius.circular(20)
              ),
              
               child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        isMasterPlaying?
                        Icons.pause
                        :Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: isMasterPlaying? pauseAllTracks:playAllTracks,
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: ()async{
                        startOverAllTracks();
                      },
                    ),
                  ],
                ),
             ),
                Column(
                  children: [
                       Stack(
                         children: [ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.selectedVideos.length, // จำนวนวิดีโอ
                          padding: const EdgeInsets.all(16.0),
                          itemBuilder: (context, index) {
                            return _buildTrackTimeline(index, isTablet: isTablet);
                          },
                          ),
                           _alignmentBar(isTablet),
                         ]
                       ),
                    

                    //Slider for timeline scroll
                    Padding(
                      padding: EdgeInsets.only(left: _scrollbarLeft(isTablet), right: _listPadding),
                      child: TimelineScrollbar(
                        contentWidth: maxTimelineWidth,
                        viewportWidth: _viewportWidth,
                        offset: timelineScroll,
                        onChanged: (v) => setState(() => timelineScroll = v),
                      ),
                    ),
                  ],
                ),
              
              
              const SizedBox(height: 40,),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ปุ่ม Generate Preview
                    Container(
                      height: isTablet?225:117,
                      width: isTablet?400:208,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.yellow),
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.black,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.music_video,size: 45,),
                          const SizedBox(height: 20,),
                          const Text('Preview will be shown here', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                    SizedBox(width: 50,),
                    Column(
                      children: [
                        SizedBox(
                          width: 300,
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
                              onPressed: () async{
                                final previewUrl = await generatePreview(
                                  layoutName: widget.layoutName,
                                  clip1: "L" ,
                                  clip2:"L" ,
                                  clipsNum: '${widget.selectedVideos.length}',
                                  video01File: widget.selectedVideos[0]['url'],
                                  video02File: widget.selectedVideos[1]['url'],
                                  bar01: audioDelays[0],
                                  bar02: audioDelays[1],
                                  audio01: players[0].volume,
                                  audio02: players[1].volume,
                                  startTime: 10,
                                );
                                print('Preview Url: $previewUrl');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
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
                      const SizedBox(height: 30,),
                      SizedBox(
                      width: isTablet?300:200,
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
                            backgroundColor: Colors.yellow,
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

Future<String> generatePreview({
  required String layoutName,
  required String clip1,
  required String clip2,
  required String clipsNum,
  required String video01File,
  required String video02File,
  required double bar01,
  required double bar02,
  required double audio01,
  required double audio02,
  required double startTime,
}) async {
  final uri = Uri.https(
    'media05.fuzikapp.com',
    '/ajax_preview2.php',
    {
      'layout_name': layoutName,
      'clip1': clip1,
      'clip2': clip2,
      'clips_num': clipsNum,
      'video01_file': video01File,
      'video02_file': video02File,
      'bar01': bar01.toStringAsFixed(0),
      'bar02': bar02.toStringAsFixed(0),
      'audio01': audio01.toString(),
      'audio02': audio02.toString(),
      'start_time': startTime.toString()
    },
  );

  final response = await http.get(uri);

  if (response.statusCode != 200) {
    throw Exception(
      'Preview generation failed: HTTP ${response.statusCode}',
    );
  }

  final result = response.body.trim();

  if (result.isEmpty) {
    throw Exception('The server returned an empty preview result.');
  }

  // The web version treats the response as a path or filename.
  return 'https://media05.fuzikapp.com/$result';
}
//Tracks
Widget _buildTrackTimeline(int index, {required bool isTablet}) {
    double secondsDelay = audioDelays[index];
    final video = widget.selectedVideos[index];
    final preview = video['preview']?.toString() ?? '';
    final duration = players[index].duration;
    final durationInSeconds = duration?.inSeconds ;
    final waveformLeft =audioDelays[index] * pixelsPerSecond;
    final visibleWaveformLeft= waveformLeft-timelineScroll;
  
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: _badgeColumnWidth,
                child: Column(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withValues(alpha: 0.9),
                            blurRadius: 10,
                            spreadRadius: 2
                          )
                        ]
                      ),
                      child: Center(
                        child: Text('${index+1}', style: TextStyle(color:Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                        )
                      )
                      ),
                      SizedBox(width: 10,height: 10,),
                      durationInSeconds == null
                        ? const Text(
                            'Loading',
                            style: TextStyle(color: Colors.white),
                          )
                        : Text(
                            '${durationInSeconds ~/ 60}:${(durationInSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white),
                          )
                  ],
                ),
              ),
              SizedBox(width: 20,),
              Container(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
                width: isTablet?200:100,
                height: isTablet?150:100,
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(8),
                  
                ),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 180,
                          height: 95,
                          clipBehavior: Clip.antiAliasWithSaveLayer,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            
                          ),
                          child: CachedNetworkImage(
                            imageUrl: preview,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,          
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              StreamBuilder<PlayerState>(
                                stream: players[index].playerStateStream,
                                builder: (context, snapshot) {
                                  final playerState = snapshot.data;
                                  final isPlaying = (playerState?.playing ?? false) && playerState?.processingState!=ProcessingState.completed;
                                  return IconButton(
                                      icon: Icon(
                                        isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: Colors.white,
                                        size: 25,
                                      ),
                                      onPressed: () => togglePlay(index,secondsDelay),
                                    );
                                }
                              ),
                              
                              IconButton(
                                icon: const Icon(Icons.skip_previous, color: Colors.white, size: 30),
                                onPressed: () => startOver(index),
                              ),
                              IconButton(
                                icon: const Icon(Icons.replay, color: Colors.white, size: 25),
                                onPressed: () {
                                  setState(() {
                                    audioDelays[index] = 0.0;
                                  });
                                },
                              ),
                            ],),
                        )
                      ],
                    ),
                    Positioned(
                      right: 10,
                      top: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          color: Colors.yellow,
                        ),
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child:Text('${secondsDelay.toStringAsFixed(2)}s',
                            style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12), 
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth - _viewportWidth.abs()>0.5) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if(mounted){
                          setState(() {
                            _viewportWidth=constraints.maxWidth;
                          });
                        }
                      });
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [                                
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: GestureDetector(
                            onPanStart: (_){
                              if(_anythingActive) pauseAllTracks();
                            },
                          onPanUpdate: (details) {
                            setState(() {                   
                                audioDelays[index] += details.delta.dx / pixelsPerSecond;
                                if (audioDelays[index] < 0) {
                                  audioDelays[index] = 0;
                                }
                            });
                          },
                      child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: RulerPainter(pixelsPerSecond: pixelsPerSecond, timelineScroll: timelineScroll),
                          ),
                        ),
                        Positioned(
                          left: visibleWaveformLeft,
                          top: (150 - 80) / 2,
                          child: BarWaves(index)
                        ),
                        Positioned(
                          top:10,
                          right:10,
                          child: AnimatedContainer(
                            duration:Duration(milliseconds: 200),
                            //padding: EdgeInsets.fromLTRB(10,10,10,10),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              color:Colors.black,
                              borderRadius: BorderRadius.circular(30)
                            ),
                            width:_volumeOpen[index]?220:50,
                            height: 50,
                            clipBehavior: Clip.hardEdge,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.volume_up_rounded,size:30
                                  ),
                                  onPressed: (){
                                    setState(() {
                                     _volumeOpen[index]=!_volumeOpen[index];
                                    });
                                  },
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 1,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8), 
                                    ),
                                    child: Slider(
                                      padding:EdgeInsets.only(right:20),
                                      activeColor: Colors.white,                         
                                      min: 0,
                                      max: 1,
                                      value: volumes[index],
                                      onChanged: (v) {
                                        setState(() {
                                          volumes[index] = v;
                                        });
                                        players[index].setVolume(v);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),)
                          ],
                          ),
                          ),
                          ),
                    ],
                  );}
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

Widget _alignmentBar(bool isTablet) {
  // Absolute X position on the full timeline.
  final rawX = _guideX;

  // Convert timeline coordinates to visible viewport coordinates.
  final visibleX = rawX - timelineScroll;

  // Keep the alignment bar visible at the viewport edges.
  final maxVisibleX =(_viewportWidth - 2.0).clamp(0.0, double.infinity);

  final x = visibleX.clamp(0.0, maxVisibleX).toDouble();

  // Fade the bar when its actual timeline position is outside
  // the visible viewport.
  final offscreen =visibleX < 0 || visibleX > maxVisibleX;

  return Positioned(
    left: _scrollbarLeft(isTablet) + x - 20,
    top: 0,
    bottom: 0,
    width: 40,
    child: GestureDetector(
      behavior: HitTestBehavior.translucent,

      onHorizontalDragUpdate: (d) {
        setState(() {
          // Move relative to the bar's displayed position.
          final newX = (x + d.delta.dx)
              .clamp(0.0, _viewportWidth)
              .toDouble();

          // Convert the visible position back into timeline time.
          guideSeconds =
              (newX + timelineScroll) / pixelsPerSecond;
        });
      },

      child: Opacity(
        opacity: offscreen ? 0.4 : 1.0,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Center(
              child: Container(
                width: 2,
                color: Colors.redAccent,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${guideSeconds.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  //Waves
Widget BarWaves(int index){
    final waveform = waveforms[index];
    if(waveform==null){
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
    final duration = players[index].duration;
    if(duration==null){
      return const SizedBox(
      width: 300,
      height: 80,);}
    final waveformWidth= duration.inMilliseconds/1000 *pixelsPerSecond;
    return SizedBox(
      width: waveformWidth,
      height: 80,
      child: CustomPaint(
        painter: BarWaveformPainter(
          waveform: waveform,
          peak: wavePeaks[index],
          color: trackColors[index % trackColors.length],
          pixelsPerSecond: pixelsPerSecond,
        ),
      ),
    );
  }
}

class RulerPainter extends CustomPainter {
  final double pixelsPerSecond;
  final double timelineScroll;
  RulerPainter({required this.pixelsPerSecond, required this.timelineScroll});
  @override
  void paint(Canvas canvas, Size size) {

    final backgroundPaint = Paint()
      ..color = Colors.grey[850]!;

    canvas.drawRect(
      Offset.zero & size,
      backgroundPaint,
    );
    
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    for (double i = -timelineScroll%pixelsPerSecond; i < size.width; i += pixelsPerSecond) {
      canvas.drawLine(Offset(i, 0), Offset(i, 10), paint);
    }
    final middleLinePaint = Paint()
  ..color = Colors.grey[600]!
  ..strokeWidth = 0.8;

final middleY = size.height / 2;

canvas.drawLine(
  Offset(0, middleY),
  Offset(size.width, middleY),
  middleLinePaint,
);
  }

  @override
  bool shouldRepaint(covariant RulerPainter old) =>
      old.pixelsPerSecond != pixelsPerSecond ||
      old.timelineScroll != timelineScroll;
}

class BarWaveformPainter extends CustomPainter {
  final Waveform waveform;
  final int peak;
  final Color color;
  final double barWidth;
  final double pixelsPerSecond;
  final double barsPerSecond;

  BarWaveformPainter({
    required this.waveform,
    required this.peak,
    required this.color,
    required this.pixelsPerSecond,
    this.barWidth = 3,
    this.barsPerSecond = 25,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final centerY = size.height / 2;

    final barSpacing = pixelsPerSecond / barsPerSecond;       
    final wavePxPerSecond = waveform.sampleRate / waveform.samplesPerPixel;
    final wavePxPerBar = wavePxPerSecond / barsPerSecond;
    final barCount = (size.width / barSpacing).ceil();

    for (int b = 0; b < barCount; b++) {
      final start = (b * wavePxPerBar).floor();
      if (start >= waveform.length) break;
      var end = ((b + 1) * wavePxPerBar).floor();
      if (end <= start) end = start + 1;

      // loudest value inside this bar's slice of audio
      int amp = 0;
      for (int p = start; p < end && p < waveform.length; p++) {
        amp = math.max(
          amp,
          math.max(waveform.getPixelMax(p).abs(), waveform.getPixelMin(p).abs()),
        );
      }

      final h = math.max(2.0, amp / peak * size.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(b * barSpacing, centerY - h / 2, barWidth, h),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant BarWaveformPainter old) =>
      old.waveform != waveform ||
      old.peak != peak ||
      old.color != color ||
      old.pixelsPerSecond != pixelsPerSecond;
}

class TimelineScrollbar extends StatelessWidget {
  final double contentWidth;
  final double viewportWidth;
  final double offset;
  final ValueChanged<double> onChanged;

  const TimelineScrollbar({
    super.key,
    required this.contentWidth,
    required this.viewportWidth,
    required this.offset,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final trackW = c.maxWidth;
      final maxOffset = (contentWidth - viewportWidth).clamp(0.0, double.infinity);
      final ratio = contentWidth <= 0
          ? 1.0
          : (viewportWidth / contentWidth).clamp(0.08, 1.0);
      final thumbW = trackW * ratio;
      final travel = trackW - thumbW;
      final thumbLeft =
          maxOffset > 0 ? (offset / maxOffset).clamp(0.0, 1.0) * travel : 0.0;

      void jumpTo(double dx) {
        if (maxOffset <= 0 || travel <= 0) return;
        onChanged(((dx - thumbW / 2) / travel * maxOffset).clamp(0.0, maxOffset));
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => jumpTo(d.localPosition.dx),
        onHorizontalDragUpdate: (d) {
          if (maxOffset <= 0 || travel <= 0) return;
          onChanged((offset + d.delta.dx / travel * maxOffset)
              .clamp(0.0, maxOffset));
        },
        child: SizedBox(
          height: 24,
          child: Stack(alignment: Alignment.centerLeft, children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.yellowAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Positioned(
              left: thumbLeft,
              child: Container(
                width: thumbW,
                height: 10,
                decoration: BoxDecoration(
                  color: maxOffset > 0 ? Colors.yellow.withValues(alpha: 0.5) : Colors.white24,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}