import 'package:flutter/material.dart';

class CollaborationContent extends StatefulWidget {
  const CollaborationContent({super.key});

  @override
  State<CollaborationContent> createState() => _CollaborationContentState();
}

class _CollaborationContentState extends State<CollaborationContent> {
  @override
  Widget build(BuildContext context) {
    // 1. เช็กความกว้างจอ: ถ้ามือถือเล็ก (< 600) ให้โชว์แค่ 1-2 คอลัมน์
    double screenWidth = MediaQuery.of(context).size.width;
    int columns = screenWidth < 400 ? 1 : (screenWidth < 800 ? 2 : 4);
    double padding = screenWidth < 600 ? 16.0 : 40.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Collaboration Layout', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Choose a template to merge your videos together.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: columns, // เปลี่ยนจาก 4 เป็นตัวแปรที่คำนวณไว้
              crossAxisSpacing: 16, 
              mainAxisSpacing: 16, 
              childAspectRatio: 1.5,
              children: [
                _buildLayoutCard(_buildLayout1()),
                _buildLayoutCard(_buildLayout2()),
                _buildLayoutCard(_buildLayout3()),
                _buildLayoutCard(_buildLayout4()),
                _buildLayoutCard(_buildLayout5()),
                _buildLayoutCard(_buildLayout6()),
                _buildLayoutCard(_buildLayout7()),
                _buildLayoutCard(_buildLayout8()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutCard(Widget layoutDesign) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(8.0), 
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), 
        child: layoutDesign
      ),
    );
  }

  // ปรับให้ Text ในช่องเล็กลงเวลาแสดงผลบนจอเล็ก
  Widget _buildBox(String text) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.5)), 
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold))
      )
    );
  }

  Widget _buildLayout1() {
    return Column(children: [Expanded(child: Row(children: [Expanded(child: _buildBox('1')), Expanded(child: _buildBox('2'))])), Expanded(child: Row(children: [Expanded(child: _buildBox('3')), Expanded(child: _buildBox('4'))]))]);
  }

  Widget _buildLayout2() {
    return Row(children: [Expanded(child: _buildBox('1')), Expanded(child: _buildBox('2')), Expanded(child: _buildBox('3'))]);
  }

  Widget _buildLayout3() {
    return Column(children: [Expanded(flex: 3, child: Row(children: [Expanded(child: _buildBox('1')), Expanded(child: _buildBox('2'))])), Expanded(flex: 2, child: Row(children: [const Spacer(flex: 1), Expanded(flex: 2, child: _buildBox('3')), const Spacer(flex: 1)]))]);
  }

  Widget _buildLayout4() {
    return Row(children: [Expanded(child: _buildBox('1')), Expanded(child: Column(children: [Expanded(child: _buildBox('2')), Expanded(child: _buildBox('3'))]))]);
  }

  Widget _buildLayout5() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: Row(children: [Expanded(child: _buildBox('1')), const SizedBox(width: 8), Expanded(child: _buildBox('2'))]));
  }

  Widget _buildLayout6() {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32.0), child: Column(children: [Expanded(child: _buildBox('1')), const SizedBox(height: 8), Expanded(child: _buildBox('2'))]));
  }

  Widget _buildLayout7() {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0), child: Row(children: [Expanded(child: _buildBox('1')), const SizedBox(width: 8), Expanded(child: _buildBox('2'))]));
  }

  Widget _buildLayout8() {
    return Row(children: [Expanded(flex: 2, child: _buildBox('1')), Expanded(flex: 3, child: Padding(padding: const EdgeInsets.only(left: 8.0, top: 16.0, bottom: 16.0, right: 16.0), child: _buildBox('2')))]);
  }
}