import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'inventory_video.dart';

class InventoryContent extends StatefulWidget {
  const InventoryContent({super.key});

  @override
  State<InventoryContent> createState() => _InventoryContentState();
}

class _InventoryContentState extends State<InventoryContent> {
  static const String baseUrl = 'https://engine01.fuzikapp.com';

  List<Map<String, dynamic>> _myVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || user.email == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // GET MUSICIAN PROFILE

      final profileResponse = await http.get(
        Uri.parse(
          '$baseUrl/musician2_detail'
              '?email=${Uri.encodeComponent(user.email!)}',
        ),
      );

      print('PROFILE STATUS: ${profileResponse.statusCode}');
      print('PROFILE RESPONSE: ${profileResponse.body}');

      if (profileResponse.statusCode != 200) {
        throw Exception('Failed to load musician profile');
      }

      final profileData = jsonDecode(profileResponse.body);

      if (profileData is! List || profileData.isEmpty) {
        throw Exception('Musician profile not found');
      }

      final displayName =
          profileData[0]['display_name']?.toString() ?? '';

      if (displayName.isEmpty) {
        throw Exception('Display name not found');
      }

      print('MUSICIAN DISPLAY NAME: $displayName');


      //GET LANDSCAPE VIDEOS

      final landscapeResponse = await http.get(
        Uri.parse(
          '$baseUrl/play2s_l/'
              '?musician=${Uri.encodeComponent(displayName)}',
        ),
      );

      print(
        'LANDSCAPE VIDEO STATUS: '
            '${landscapeResponse.statusCode}',
      );

      print(
        'LANDSCAPE VIDEO RESPONSE: '
            '${landscapeResponse.body}',
      );

      if (landscapeResponse.statusCode != 200) {
        throw Exception(
          'Failed to load landscape videos',
        );
      }

      final landscapeData =
      jsonDecode(landscapeResponse.body);


      //GET PORTRAIT VIDEOS

      final portraitResponse = await http.get(
        Uri.parse(
          '$baseUrl/play2s_p/'
              '?musician=${Uri.encodeComponent(displayName)}',
        ),
      );

      print(
        'PORTRAIT VIDEO STATUS: '
            '${portraitResponse.statusCode}',
      );

      print(
        'PORTRAIT VIDEO RESPONSE: '
            '${portraitResponse.body}',
      );

      if (portraitResponse.statusCode != 200) {
        throw Exception(
          'Failed to load portrait videos',
        );
      }

      final portraitData =
      jsonDecode(portraitResponse.body);

      //  LANDSCAPE + PORTRAIT

      final List<Map<String, dynamic>> allVideos = [];

      if (landscapeData is List) {
        allVideos.addAll(
          List<Map<String, dynamic>>.from(
            landscapeData,
          ),
        );
      }

      if (portraitData is List) {
        allVideos.addAll(
          List<Map<String, dynamic>>.from(
            portraitData,
          ),
        );
      }

      // UPDATE INVENTORY

      if (!mounted) return;

      setState(() {
        _myVideos = allVideos;
        _isLoading = false;
      });

      print(
        'TOTAL INVENTORY VIDEOS: '
            '${_myVideos.length}',
      );
    } catch (e) {
      print('INVENTORY ERROR: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load inventory: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // เช็กความกว้างหน้าจอเพื่อจัด Layout ให้เหมาะกับมือถือ หรือแท็บเล็ต
    double screenWidth = MediaQuery.of(context).size.width;
    double paddingHorizontal = screenWidth < 600 ? 16.0 : 40.0;
    
    // คำนวณจำนวนคอลัมน์อัตโนมัติ 
    int columns = screenWidth < 400 ? 1 : (screenWidth < 600 ? 2 : 4);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Inventory', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Manage your uploaded videos and collaborations.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // ใช้ตัวแปร columns ตรงนี้ เพื่อให้มันเปลี่ยนจำนวนตามจอ
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns, 
              crossAxisSpacing: 16, 
              mainAxisSpacing: 24, 
              childAspectRatio: columns == 1 ? 1.4 : 1.05 // ปรับสัดส่วนการ์ดถ้าย่อเหลือคอลัมน์เดียว
            ),
            itemCount: _myVideos.length,
            itemBuilder: (context, index) {
              final video = _myVideos[index];

              return _buildInventoryCard(video);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> video) {
    final title = video['video_title']?.toString() ?? 'Untitled';
    final views = video['view_count']?.toString() ?? '0';
    final date = video['created_time']?.toString() ?? '';
    final preview = video['preview']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              print('Clicked video: ${video['url']}');

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InventoryVideoScreen(
                    videoUrl: video['url']?.toString() ?? '',
                  ),
                ),
              );
            },
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD600).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: preview.isNotEmpty
                        ? Image.network(
                      preview,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: 48,
                          ),
                        );
                      },
                    )
                        : const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white30,
                        size: 48,
                      ),
                    ),
                  ),

                  // Play icon
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white70,
                      size: 48,
                    ),
                  ),

                  // Edit, Delete
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InventoryVideoScreen(
                                    videoUrl: video['url']?.toString() ?? '',
                                    autoEdit: true,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                            onPressed: () {
                              _showDeleteDialog(video);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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

        const SizedBox(height: 4),

        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$views views',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),

          title: const Text(
            'Delete Video?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            'Are you sure you want to delete this video?',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                // MOCKUP ONLY


                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Delete is not connected yet',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );
  }

}