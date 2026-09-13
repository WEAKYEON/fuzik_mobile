import 'package:flutter/material.dart';
import 'youtube_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewPlayScreen extends StatelessWidget {
  final String title;
  final String artist;
  final String views;
  final String url;
  final String profileUrl;
  final String description;
  const ViewPlayScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.views,
    required this.url,
    required this.profileUrl,
    required this.description
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video player mockup
           YouTubeScreen(videourl: url),

            const SizedBox(height: 20),

            // Video title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // user
            Row(
              children: [
                profileUrl.isNotEmpty
                ? CachedNetworkImage(
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
                  )
                : const Icon(Icons.person),
                const SizedBox(width: 6),
                Text(
                  artist,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Views
            Row(
              children: [
                const Icon(
                  Icons.visibility,
                  color: Colors.white38,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Text(
                  views,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Divider
            Container(
              height: 1,
              color: Colors.white12,
            ),

            const SizedBox(height: 20),

            const Text(
              'Description',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              description,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 30),

            // Mock action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // need to do Like functionality
                    },
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Like',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.white24,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // need to do Share functionality
                    },
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Share',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.white24,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//  AspectRatio(
//               aspectRatio: 16 / 9,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF151515),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: const Color(0xFFFFD600).withValues(
//                       alpha: 0.5,
//                     ),
//                   ),
//                 ),
//                 child: Stack(
//                   children: [

//                     // Play button
//                     Center(
//                       child: Container(
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: Colors.white54,
//                         ),
//                         child: IconButton(
//                           iconSize: 42,
//                           icon: const Icon(
//                             Icons.play_arrow,
//                             color: Colors.black,
//                           ),
//                           onPressed: () {
//                             // to Connect real video player here.
//                           },
//                         ),
//                       ),
//                     ),

//                     // JAM label
//                     Positioned(
//                       left: 12,
//                       top: 12,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 5,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.black87,
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         child: const Text(
//                           'JAM',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 11,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),

//                     // Mock progress bar
//                     Positioned(
//                       left: 12,
//                       right: 12,
//                       bottom: 12,
//                       child: Column(
//                         children: [
//                           Container(
//                             height: 4,
//                             decoration: BoxDecoration(
//                               color: Colors.white24,
//                               borderRadius:
//                               BorderRadius.circular(4),
//                             ),
//                             child: FractionallySizedBox(
//                               alignment: Alignment.centerLeft,
//                               widthFactor: 0.55,
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   color: Colors.white54,
//                                   borderRadius:
//                                   BorderRadius.circular(4),
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           const Row(
//                             mainAxisAlignment:
//                             MainAxisAlignment.spaceBetween,
//                             children: [
//                               Text(
//                                 '0:00',
//                                 style: TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 11,
//                                 ),
//                               ),
//                               Text(
//                                 '0:00',
//                                 style: TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 11,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),