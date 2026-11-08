import 'package:flutter/material.dart';
import 'package:fuzik_mobile/services/fetch_collaboration_videos.dart';
import 'dart:async';
import 'dart:convert';
import 'view_play.dart';
import 'jam_watch.dart'; 
import 'package:cached_network_image/cached_network_image.dart'; 
import 'package:fuzik_mobile/services/fetch_videos.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => DashboardContentState();
}

class DashboardContentState extends State<DashboardContent> {
  bool isSoloSelected = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<FetchVideos> _videosFuture;
  late Future<CollaborationVideos> _collaborationVideosFuture;

  void _reload() { 

  isSoloSelected? setState(() {
     _videosFuture = fetchVideos(query: _searchQuery);
  }) : setState(() {
    _collaborationVideosFuture= fetchCollaborationVideos(query:_searchQuery);
  });
  }

  void refreshDashboardData() {
    setState(() {
      _videosFuture =
          fetchVideos(query: _searchQuery);

      _collaborationVideosFuture =
          fetchCollaborationVideos(
            query: _searchQuery,
          );
    });
    refreshDashboard();
  }

  Future<int> getJamViews({required String videoUrl}) async{
    final url=Uri.parse('https://engine01.fuzikapp.com/get_jam2_count?j=$videoUrl');
    try{
      final response=await http.get(url);
      if(response.statusCode!=200){
        return 0;
      }
      final jsonString=response.body;
      final data=jsonDecode(jsonString);
      final viewCount=data[0]['view_count'];
      return viewCount;
    }
    catch(e){
      throw Exception(e);
    }
  }

  Future<void> _refresh() async{
    final future=fetchVideos(query: _searchQuery);
    setState((){
      _videosFuture=future;
    });
    await future;
  }
  @override
  void initState() {
    super.initState();
    _videosFuture=fetchVideos(query: _searchQuery);
    _collaborationVideosFuture=fetchCollaborationVideos(query: _searchQuery);
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //this below commented version cause card height overflow in small phone
    /*
    double screenWidth = MediaQuery.of(context).size.shortestSide;
    double paddingHorizontal = screenWidth < 600 ? 16.0 : 40.0;
    bool isTablet = screenWidth >= 600;
    int columns = screenWidth < 400 ? 1 : (screenWidth < 600 ? 2 : 3);
    */

    final screenSize = MediaQuery.of(context).size.shortestSide;
    final bool isTablet = screenSize >= 600;
    final double paddingHorizontal = isTablet ? 40.0 : 16.0;
    final int columns = isTablet ? 3 : 2;

    return RefreshIndicator(
      backgroundColor: Colors.yellow,
      color:Colors.black,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ปุ่ม Solo / Collaboration
            Center(
              child: Container(
                width: 320, height: 42,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white38),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isSoloSelected = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSoloSelected ? const Color(0xFFFFD600) : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Text('Solo', style: TextStyle(color: isSoloSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isSoloSelected = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !isSoloSelected ? const Color(0xFFFFD600) : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Text('Collaboration', style: TextStyle(color: !isSoloSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
      
            // ช่องค้นหา (Search)
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 550),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search by song, artist, or instrument',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                            filled: true, fillColor: Colors.black,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFFFD600)), borderRadius: BorderRadius.circular(20)),
                            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFFFD600), width: 2), borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = _searchController.text.trim();

                            if (isSoloSelected) {
                              _videosFuture =
                                  fetchVideos(query: _searchQuery);
                            } else {
                              _collaborationVideosFuture =
                                  fetchCollaborationVideos(
                                    query: _searchQuery,
                                  );
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD600), foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                        ),
                        child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            isSoloSelected?Text("Portrait", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)):Container(),
            const SizedBox(height: 16),
      
            //Portrait Videos
            isSoloSelected?FutureBuilder<FetchVideos>(
            future: _videosFuture,
            builder: (context,snapshot){
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFFFFD600))));
              }
             if(!snapshot.hasData || snapshot.data!.hasError ){
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        snapshot.data?.error ?? 'Something went wrong.',
                        style: const TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style:ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          foregroundColor: Colors.black
                        ) ,
                        onPressed: _reload, child: const Text('Retry')),
                    ],
                  ),
                ),
              ); 
             }
              if (snapshot.data!.portrait.isEmpty) {
                return  Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('Sorry, we could not find any portrait videos with $_searchQuery.', style: TextStyle(color: Colors.white54, fontSize: 16))));
              }
              final videos = snapshot.data!.portrait;
              return SizedBox(
                width: MediaQuery.of(context).size.width*0.8,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isTablet?4:3, 
                    crossAxisSpacing: 5, 
                    mainAxisSpacing: 10, 
                    childAspectRatio: 0.4, 
                  ),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    final isArtist=video['artist']?.toString()??'';
                    final title = video['video_title']?.toString() ?? '';
                    final artist = video['musician_name']?.toString() ?? '';
                    final views = '${video['view_count'] ?? 0} views';
                    final preview = video['preview']?.toString()??'';
                    final profileUrl = video['musician_profile_pic']?.toString() ?? '';
                    final youtubeCode=video['youtube_url'];
                    final videoUrl=video['url']?.toString() ??'';
                    final musicianEmail=video['musician_email']?.toString()??'';
                    final description=video['description']?.toString() ??'';
                    
                    return _buildVideoCard(
                      title,
                      artist,
                      views,
                      preview,
                      profileUrl,
                      isSolo: isSoloSelected,
                      isPortrait: true,
                      isArtist: isArtist,
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewPlayScreen(
                                title: title,
                                artist: artist,
                                views: views,
                                youTubeCode: youtubeCode,
                                profileUrl: profileUrl,
                                description:description,
                                videoUrl: videoUrl,
                                musicianEmail:musicianEmail ,
                              ),
                            ),
                          );
                        if (!mounted) return;

                        setState(() {
                          _videosFuture =
                              fetchVideos(query: _searchQuery);
                        });
                        
                      },
                    );
                  },
                ),
              );
            }
            ):Container(),

            SizedBox(height: 20),

            Text(isSoloSelected ? 'Landscape' : 'Jam', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Landscape
            isSoloSelected? FutureBuilder<FetchVideos>(
              future: _videosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFFFFD600))));
                }
               if(!snapshot.hasData || snapshot.data!.hasError ){
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            snapshot.data?.error ?? 'Something went wrong.',
                            style: const TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              foregroundColor: Colors.black
                            ),
                            onPressed: _reload, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ); 
                }
                if (snapshot.data!.landscape.isEmpty) {
                  return  Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('Sorry, we could not find any landscape videos with $_searchQuery.', style: TextStyle(color: Colors.white54, fontSize: 16))));
                }
                final videos = snapshot.data!.landscape;
                return GridView.builder(  
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns, 
                    crossAxisSpacing: 16, 
                    mainAxisSpacing: 10, 
                    childAspectRatio: columns == 1 ? 1.5 : 1.0, 
                  ),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    final isArtist=video['artist']?.toString()??'';
                    final title = video['video_title']?.toString() ?? '';
                    final artist = video['musician_name']?.toString() ?? '';
                    final views = '${video['view_count'] ?? 0} views';
                    final preview = video['preview']?.toString()??'';
                    final profileUrl = video['musician_profile_pic']?.toString() ?? '';
                    final youtubeCode=video['youtube_url'];
                    final description = video['description']?.toString()??'';
                    final videoUrl=video['url']?.toString()??'';
                    final musicanEmail= video['musician_email']?.toString()??'';
                    return _buildVideoCard(
                      title,
                      artist,
                      views,
                      preview,
                      profileUrl,
                      isPortrait: false,
                      isSolo: isSoloSelected,
                      isArtist: isArtist,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewPlayScreen(
                              title: title,
                              artist: artist,
                              views: views,
                              youTubeCode: youtubeCode,
                              profileUrl: profileUrl,
                              description: description,
                              videoUrl: videoUrl,
                              musicianEmail: musicanEmail,
                            ),
                          ),
                        );

                        if (!mounted) return;

                        setState(() {
                          _videosFuture =
                              fetchVideos(query: _searchQuery);
                        });
                      },
                    );
                  },
                );
              },
            ): Container(),
           
           //Collaboration Videos
           isSoloSelected?Container()
           :FutureBuilder<CollaborationVideos>(
            future: _collaborationVideosFuture,
            builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFFFFD600))));
                }
               if(!snapshot.hasData || snapshot.data!.hasError ){
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            snapshot.data?.error ?? 'Something went wrong.',
                            style: const TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              foregroundColor: Colors.black
                            ),
                            onPressed: _reload, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ); 
                }
                if (snapshot.data!.videos.isEmpty) {
                  return  Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('Sorry, we could not find any jam videos with $_searchQuery.', style: TextStyle(color: Colors.white54, fontSize: 16))));
                }
                final videos = snapshot.data!.videos;
                return GridView.builder(  
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns, 
                    crossAxisSpacing: 16, 
                    mainAxisSpacing: 10,
                    childAspectRatio: isTablet
                        ? 1.0
                        : (columns == 1 ? 1.5 : 0.96),
                  ),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    final title = video['description']?.toString() ?? '';
                    final artist = video['owner_name']?.toString() ?? '';
                    final videoUrl=video['url']?.toString()??'';
                    final previewUrl = video['preview']?.toString()??'';
                    final profileUrl = video['profile_pic']?.toString() ?? '';
                    final youtubeCode=video['youtube_url']??'';
                    final description = video['description']?.toString()??'';
                    final views='';
                    final preview='https://media05.fuzikapp.com/$previewUrl';
                    return _buildVideoCard(
                      title,
                      artist,
                      views,
                      preview,
                      profileUrl,
                      isPortrait: false,
                      isSolo: isSoloSelected,
                      videoUrl: videoUrl,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JamWatchScreen(
                              title: title,
                              youTubeCode: youtubeCode,
                              profileUrl: profileUrl,
                              description: description,
                              videoUrl: videoUrl,
                              isSolo: isSoloSelected,
                              previewUrl: preview,
                            ),
                          ),
                        );

                        if (!mounted) return;

                        setState(() {
                          _collaborationVideosFuture =
                              fetchCollaborationVideos(
                                query: _searchQuery,
                              );
                        });
                      },
                    );
                  },
                );
              },
           )
          ],
        ),
      ),
    );
  }
  void refreshDashboard() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Widget _buildVideoCard(
      String title,
      String artist,
      String views,
      String preview,
      String profileUrl,{
        required bool isPortrait,
        required bool isSolo,
        VoidCallback? onTap,
        int retry = 0,
        String videoUrl='',
        String isArtist=''
      }) {
    bool checkArtist= isArtist=='Yes';
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: isPortrait ? 9/16 : 16/9,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD600).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                        imageUrl: preview,
                        fit:BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        placeholder: (context, url) => Center(child: CircularProgressIndicator(color:Colors.yellow)),
                        errorWidget: (context, url, error) => GestureDetector(
                          onTap: () async {
                            await CachedNetworkImage.evictFromCache(url);
                            setState(() => retry++);
                          },
                          child: const Icon(Icons.refresh),
                        ),
                        ),
                    
                   ),

                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      color: isSolo ? Colors.blueGrey[900] : Colors.black87,
                      child: Text(
                        isSolo ? 'SOLO' : 'JAM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  checkArtist? Positioned(
                    left: -30,
                    top: 15,
                    child: Transform.rotate(
                      angle:-pi/4,
                      child: Container(
                        alignment: Alignment.center,
                        width: 120,
                        height: 30,
                        color:Colors.yellow,
                        child:  Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Artist',style: TextStyle(color:Colors.black,fontWeight: FontWeight.bold ),),
                            Icon(Icons.music_note_rounded, color:Colors.black,size:20)
                          ],
                        ),
                      ),
                      )
                      ):Container(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              profileUrl.isNotEmpty
    ? ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: CachedNetworkImage(
          imageUrl: 'https://media05.fuzikapp.com/$profileUrl',
          httpHeaders: {
            'Referer': 'https://fuzikapp.com',
          },
          width: 30,
          height: 30,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) {
            return const Icon(Icons.person);
          },
        ),
    )
    : const Icon(Icons.person),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              artist,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: isSolo? Text(
              views,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            )
            : FutureBuilder(future: getJamViews(videoUrl: videoUrl), 
                            builder: (context,snapeshot){
                               if(snapeshot.connectionState==ConnectionState.waiting){
                                return CircularProgressIndicator(color:Colors.yellow);
                               }
                               if(!snapeshot.hasData){
                                return Text('0');
                               }
                               final result=snapeshot.data!.toString();
                               return Text(
                                '$result views',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              );
                            }
                            )
          ),
        ],
      ),
    );
  }
}