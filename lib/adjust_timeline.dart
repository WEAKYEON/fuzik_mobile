import 'package:flutter/material.dart';
import 'choose_video2.dart';

class AdjustTimelineScreen extends StatefulWidget {
  final String layoutName;
  final List<SampleVideo> selectedVideos;

  const AdjustTimelineScreen({
    super.key,
    required this.layoutName,
    required this.selectedVideos,
  });

  @override
  State<AdjustTimelineScreen> createState() => _AdjustTimelineScreenState();
}

class _AdjustTimelineScreenState extends State<AdjustTimelineScreen> {
  List<double> offsets = [0.0, 0.0];
  
  final List<Color> trackColors = [Colors.redAccent, Colors.blueAccent];

  @override
  Widget build(BuildContext context) {
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
                        print("Track 1 Offset: ${offsets[0]}");
                        print("Track 2 Offset: ${offsets[1]}");
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
                itemCount: 2, // จำนวนวิดีโอ
                padding: const EdgeInsets.all(16.0),
                itemBuilder: (context, index) {
                  return _buildTrackTimeline(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTimeline(int index) {
    double secondsDelay = offsets[index] / 50.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.video_file, color: Colors.white54),
              ),
              const SizedBox(width: 12),
              // ปุ่มปรับจังหวะละเอียด (< >)
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
              )
            ],
          ),
          const SizedBox(height: 8),

          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
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
                            (i) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              width: 2,
                              height: (i % 2 == 0) ? 20 : 10, // คลื่นหยักๆ หลอกๆ
                              color: trackColors[index],
                            ),
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