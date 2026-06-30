import 'package:flutter/material.dart';

class InventoryContent extends StatefulWidget {
  const InventoryContent({super.key});

  @override
  State<InventoryContent> createState() => _InventoryContentState();
}

class _InventoryContentState extends State<InventoryContent> {
  final List<Map<String, dynamic>> _myVideos = List.generate(5, (index) => {
    'id': index.toString(),
    'title': 'My Awesome Bass Cover ${index + 1}',
    'artist': 'omiejung2',
    'views': (index + 1) * 42,
    'date': '2 days ago',
  });

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
              return _buildInventoryCard(video['title'], video['views'].toString(), video['date']);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(String title, String views, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFD600).withOpacity(0.4), width: 1)),
            child: Stack(
              children: [
                const Center(child: Icon(Icons.play_circle_fill, color: Colors.white30, size: 48)),
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.white, size: 16), constraints: const BoxConstraints(), padding: const EdgeInsets.all(6), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16), constraints: const BoxConstraints(), padding: const EdgeInsets.all(6), onPressed: () {}),
                      ],
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
            const Icon(Icons.music_note, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$views views', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              Text(date, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}