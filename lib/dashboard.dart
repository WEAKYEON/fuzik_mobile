import 'package:flutter/material.dart';
import 'view_play.dart';
import 'jam_watch.dart'; 

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool isSoloSelected = false; 
  final _searchController = TextEditingController();

  Future<List<Map<String, dynamic>>> _fetchVideos() async {
    try {
      await Future.delayed(const Duration(seconds: 1)); 
      return List.generate(8, (index) => {
        'id': index.toString(),
        'title': 'Sample Jamming ${index + 1}',
        'artist': 'Fuzik User',
        'views': (index + 1) * 15,
        'date': '1 month ago',
      });
    } catch (e) {
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
    double screenWidth = MediaQuery.of(context).size.width;
    double paddingHorizontal = screenWidth < 600 ? 16.0 : 40.0;
    
    int columns = screenWidth < 400 ? 1 : (screenWidth < 600 ? 2 : 4);

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
                          hintText: 'Song name or artist name',
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
                      onPressed: () {},
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
          
          const Text('All Jams / Videos', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // ตารางวิดีโอ (GridView)
          FutureBuilder<List<dynamic>>(
            future: _fetchVideos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFFFFD600))));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('ไม่พบข้อมูลวิดีโอ', style: TextStyle(color: Colors.white54, fontSize: 16))));
              }
              final videos = snapshot.data!;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns, 
                  crossAxisSpacing: 16, 
                  mainAxisSpacing: 24, 
                  childAspectRatio: columns == 1 ? 1.5 : 1.0, 
                ),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  final title = video['title']?.toString() ?? '';
                  final artist = video['artist']?.toString() ?? '';
                  final views = '${video['views'] ?? 0} views';

                  return _buildVideoCard(
                    title,
                    artist,
                    views,
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
      String views, {
        required bool isSolo,
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
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
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white30,
                      size: 48,
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