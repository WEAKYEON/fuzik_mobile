import 'package:flutter/material.dart';
import 'collaboration.dart'; 

class JamWatchScreen extends StatelessWidget {
  const JamWatchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD600), width: 2), 
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: Container(color: Colors.grey[800])),
                              const SizedBox(width: 2),
                              Expanded(child: Container(color: Colors.grey[850])),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: Container(color: Colors.grey[900])),
                              const SizedBox(width: 2),
                              Expanded(child: Container(color: Colors.grey[700])),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Center(
                      child: Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              '4-piece collaboration - Guitar, Guitar, Bass and Drums.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: Icon(Icons.music_note, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Created by FuzikOfficial',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '33 views • 11 months ago',
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CollaborationContent(showBackButton: true),
                          ),
                        );
                        print("Go to Collaboration Screen");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD600), // สีเหลือง
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Join Jam',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Wrap(
                  spacing: 12, 
                  runSpacing: 12, 
                  children: [
                    _buildPillButton(Icons.remove, 'Fans', const Color(0xFFFFB300)),
                    _buildPillButton(Icons.remove, 'Like', const Color(0xFFFFB300)),
                    _buildPillButton(Icons.share, 'Share', const Color(0xFFFFB300)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),
            
            const Divider(color: Colors.white24, thickness: 1),
            
            const SizedBox(height: 16),

            // 4. Description section
            const Text(
              'Description',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This collaboration consists of:\n'
              'Pop Rock Backing Track | Guitar Solo | E Major | 81 BPM\n'
              'Guitar Pop Rock Backing Track | Guitar | E Major | 81 BPM\n'
              'Bass Pop Rock Backing Track | Bass | F Major | 81 BPM\n'
              'Drums Pop Rock Backing Track | Drums | E Major | 81 BPM',
              style: TextStyle(
                color: Colors.grey[400], 
                fontSize: 13,
                height: 1.6, 
              ),
            ),
            
            const SizedBox(height: 40), 
          ],
        ),
      ),
    );
  }

  Widget _buildPillButton(IconData icon, String label, Color iconColor) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: iconColor, size: 18),
      label: Text(
        label,
        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, 
        foregroundColor: Colors.grey[200], 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 0,
      ),
    );
  }
}