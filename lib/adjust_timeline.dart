import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  
  @override
  void initState(){
    super.initState();
    offsets = List<double>.filled(widget.selectedVideos.length, 0.0);
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ปุ่ม Generate Preview
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD600),
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Generate 20s preview'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFFD600)),
                      color: Colors.black,
                    ),
                    alignment: Alignment.center,
                    child: const Text('Not available', style: TextStyle(color: Colors.white54)),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: บันทึกค่า offsets และส่งข้อมูลไปประมวลผลที่เซิร์ฟเวอร์
                        for (int i = 0; i < offsets.length; i++) {
                          print("Track ${i + 1} Offset: ${offsets[i]}");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD600),
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Send to Queue'),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.white24, thickness: 1),

            Expanded(
              child: ListView.builder(
                itemCount: widget.selectedVideos.length, // จำนวนวิดีโอ
                padding: const EdgeInsets.all(16.0),
                itemBuilder: (context, index) {
                  return _buildTrackTimeline(index, isTablet: isTablet);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                width: isTablet?150:80,
                height: isTablet?100:45,
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
                    Row(
                      children: [
                        Text(
                          '${secondsDelay > 0 ? '+' : ''}${secondsDelay.toStringAsFixed(2)}s',
                          style: TextStyle(color: trackColors[index], fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                          onPressed: () => setState(() => offsets[index] -= 5),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                          onPressed: () => setState(() => offsets[index] += 5),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    Container(
                            height: 60,
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
                  });
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: RulerPainter(),
                      ),
                    ),
                    
                    Transform.translate(
                      offset: Offset(offsets[index], 0),
                      child: Center(
                        child: Container(
                          height: 20,
                          width: 1000,
                          child: Row(
                            children: List.generate(
                              100,
                              (i) {
                                final wave = [
                                  8, 14, 20, 12, 28, 35, 24, 16, 10, 18,
                                  30, 38, 26, 20, 12, 16, 24, 32, 40, 28,
                                  18, 10, 14, 26, 34, 42, 30, 20, 14, 22,
                                  32, 38, 28, 18, 12, 20, 30, 36, 24, 16,
                                ];
                
                                final height = wave[i % wave.length];
                
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  width: 2,
                                  height: height.toDouble(),
                                  color: trackColors[index],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
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