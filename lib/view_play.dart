import 'package:flutter/material.dart';
import 'youtube_player.dart';
import 'httpsVideoPlayer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewPlayScreen extends StatelessWidget {
  final String title;
  final String artist;
  final String views;
  final String youTubeCode;
  final String profileUrl;
  final String description;
  final String videoUrl;
  const ViewPlayScreen({
    super.key,
    required this.title,
    required this.artist,
    required this.views,
    required this.youTubeCode,
    required this.profileUrl,
    required this.description,
    required this.videoUrl,
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
            Icons.arrow_back_ios_new_rounded,
            color: Colors.yellow,
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

            youTubeCode.isEmpty? HttpsVideoPlayer(videoUrl: videoUrl):
            // Video player mockup
           YouTubeScreen(youTubeurl: 'https://www.youtube.com/watch?v=$youTubeCode'),

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
                ClipRRect(
                  borderRadius: BorderRadiusGeometry.circular(25),
                child: profileUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: 'https://media05.fuzikapp.com/$profileUrl',
                    httpHeaders: {
                      'Referer': 'https://fuzikapp.com',
                    },
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) {
                      return const Icon(Icons.person);
                    },
                  )
                : const Icon(Icons.person), ),
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