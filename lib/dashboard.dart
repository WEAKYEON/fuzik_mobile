import 'package:flutter/material.dart';
import 'dart:convert';
import 'view_play.dart';
import 'jam_watch.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart'; //This is a package to cache the images, t

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool isSoloSelected = true; 
  final _searchController = TextEditingController();
  String _searchQuery = '';


  Future<List<Map<String, dynamic>>> _fetchVideos({
    String query = '',
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);

      final lUri = Uri.parse(
        'https://engine01.fuzikapp.com/play2s_l/?q=$encodedQuery',
      );

      final pUri = Uri.parse(
        'https://engine01.fuzikapp.com/play2s_p/?q=$encodedQuery',
      );

      final responses = await Future.wait([
        http.get(lUri),
        http.get(pUri),
      ]);

      final lResponse = responses[0];
      final pResponse = responses[1];

      if (lResponse.statusCode != 200 || pResponse.statusCode != 200) {
        throw Exception('Failed to load videos');
      }

      final lData = jsonDecode(lResponse.body);
      final pData = jsonDecode(pResponse.body);

      final videos = [
        ...List<Map<String, dynamic>>.from(lData),
        ...List<Map<String, dynamic>>.from(pData),
      ];

      return videos;
    } catch (e) {
      print('Error fetching videos: $e');
      return [];
    }
  }

Future<List<Map<String, dynamic>>> _fetchPortraitVideos() async {
    try {
      
      final url=Uri.parse('https://engine01.fuzikapp.com/play2s_p/');
      final response= await http.get(url);
        if (response.statusCode == 200) {
        // jsonDecode parses the raw string into a Dart Map or List
          final data = List<Map<String, dynamic>>.from(jsonDecode(response.body),);
          
          return data;
        } else {
          
          throw Exception('Failed to load data');
        } 
    } catch (e) {
      print(e);
      return [];
    }
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.shortestSide;
    double paddingHorizontal = screenWidth < 600 ? 16.0 : 40.0;
    bool isTablet = screenWidth >= 600;
    int columns = screenWidth < 400 ? 1 : (screenWidth < 600 ? 2 : 3);

    return SingleChildScrollView(
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
          
          Text(isSoloSelected ? 'Portrait' : 'Group', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          //Portrait Videos
          FutureBuilder(future: _fetchPortraitVideos(), 
          builder: (context,snapshot){
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFFFFD600))));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('ไม่พบข้อมูลวิดีโอ', style: TextStyle(color: Colors.white54, fontSize: 16))));
            }
            final videos = snapshot.data!;
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
              
                  final title = video['video_title']?.toString() ?? '';
                  final artist = video['musician_name']?.toString() ?? '';
                  final views = '${video['views'] ?? 0} views';
                  final preview = video['preview']?.toString()??'';
              
                  return _buildVideoCard(
                    title,
                    artist,
                    views,
                    preview,
                    isSolo: isSoloSelected,
                    isPortrait: true,
                    onTap: () {
                      if (isSoloSelected) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewPlayScreen(
                              title: title,
                              artist: artist,
                              views: views,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const JamWatchScreen(),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            );
          }
          ),

          Text(isSoloSelected ? 'Landscape' : 'Group', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // ตารางวิดีโอ (GridView)
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchVideos(query: _searchQuery),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFFFFD600))));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('No matching videos found', style: TextStyle(color: Colors.white54, fontSize: 16))));
              }
              final videos = snapshot.data!;
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

                  final title = video['video_title']?.toString() ?? '';
                  final artist = video['musician_name']?.toString() ?? '';
                  final views = '${video['views'] ?? 0} views';
                  final preview = video['preview']?.toString()??'';

                  return _buildVideoCard(
                    title,
                    artist,
                    views,
                    preview,
                    isPortrait: false,
                    isSolo: isSoloSelected,
                    onTap: () {
                      if (isSoloSelected) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewPlayScreen(
                              title: title,
                              artist: artist,
                              views: views,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const JamWatchScreen(),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(
      String title,
      String artist,
      String views,
      String preview, {
        required bool isPortrait,
        required bool isSolo,
        VoidCallback? onTap,
      }) {
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
                        errorWidget: (context, url, error) => Icon(Icons.error),
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 16,
              ),
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
            child: Text(
              views,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}