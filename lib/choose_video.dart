import 'package:flutter/material.dart';

enum SlotOrientation { landscape, portrait }

// Sample data model + mock list — swap for your real VideoAsset/API later
class SampleVideo {
  final String id;
  final String title;
  final String thumbnailUrl;
  final SlotOrientation orientation;
  const SampleVideo({required this.id, required this.title, required this.thumbnailUrl, required this.orientation});
}

final List<SampleVideo> sampleVideos = List.generate(12, (i) {
  return SampleVideo(
    id: 'vid_$i',
    title: 'Sample video $i',
    thumbnailUrl: 'https://picsum.photos/seed/video$i/300/300',
    orientation: SlotOrientation.portrait,
  );
});

class LayoutSlot {
  final int index;
  final SlotOrientation orientation;
  final double x, y, w, h; // fractional rect (0.0-1.0)

  const LayoutSlot({
    required this.index,
    required this.orientation,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });
}

/// A full layout definition: the overall canvas shape (aspectRatio)
/// plus the slots positioned within it. The canvas shape matters just
/// as much as each slot's shape — a layout of 3 portrait videos
/// side-by-side is itself a wide canvas, but a layout of 1 landscape
/// strip over 2 portraits is a tall canvas.
class LayoutDefinition {
  final double aspectRatio; // width / height of the WHOLE canvas
  final List<LayoutSlot> slots;

  const LayoutDefinition({required this.aspectRatio, required this.slots});
}

/// Hardcoded geometry per layout_name. Fill these in to match your
/// actual template art (e.g. the 1/2/3/4 numbered grid images).
/// aspectRatio is a guess per layout here — set it to match your real
/// template canvas dimensions.
const Map<String, LayoutDefinition> kLayoutGeometry = {
  '4_01': LayoutDefinition(
    aspectRatio: 16 / 9, // wide canvas: 4 landscape videos in a 2x2 grid
    slots: [
      LayoutSlot(index: 0, orientation: SlotOrientation.landscape, x: 0, y: 0, w: 0.5, h: 0.5),
      LayoutSlot(index: 1, orientation: SlotOrientation.landscape, x: 0.5, y: 0, w: 0.5, h: 0.5),
      LayoutSlot(index: 2, orientation: SlotOrientation.landscape, x: 0, y: 0.5, w: 0.5, h: 0.5),
      LayoutSlot(index: 3, orientation: SlotOrientation.landscape, x: 0.5, y: 0.5, w: 0.5, h: 0.5),
    ],
  ),
  '3_07': LayoutDefinition(
    aspectRatio: 16/ 9, // tall canvas: 3 portrait videos side-by-side
    slots: [
      LayoutSlot(index: 0, orientation: SlotOrientation.portrait, x: 0, y: 0, w: 1 / 3, h: 1),
      LayoutSlot(index: 1, orientation: SlotOrientation.portrait, x: 1 / 3, y: 0, w: 1 / 3, h: 1),
      LayoutSlot(index: 2, orientation: SlotOrientation.portrait, x: 2 / 3, y: 0, w: 1 / 3, h: 1),
    ],
  ),
  '3_06': LayoutDefinition(
    aspectRatio: 9 / 16, // tall canvas: 1 landscape strip over 2 portraits
    slots: [
      LayoutSlot(index: 0, orientation: SlotOrientation.landscape, x: 0, y: 0, w: 1, h: 0.35),
      LayoutSlot(index: 1, orientation: SlotOrientation.portrait, x: 0, y: 0.35, w: 0.5, h: 0.65),
      LayoutSlot(index: 2, orientation: SlotOrientation.portrait, x: 0.5, y: 0.35, w: 0.5, h: 0.65),
    ],
  ),
  '3_05': LayoutDefinition(
    aspectRatio: 1, // roughly square canvas: 2 landscape over 1 portrait
    slots: [
      LayoutSlot(index: 0, orientation: SlotOrientation.landscape, x: 0, y: 0, w: 1, h: 0.5),
      LayoutSlot(index: 1, orientation: SlotOrientation.landscape, x: 0, y: 0.5, w: 0.5, h: 0.5),
      LayoutSlot(index: 2, orientation: SlotOrientation.portrait, x: 0.5, y: 0.5, w: 0.5, h: 0.5),
    ],
  ),
  '3_04': LayoutDefinition(
    aspectRatio: 1,
    slots: [
      LayoutSlot(index: 0, orientation: SlotOrientation.landscape, x: 0, y: 0, w: 0.5, h: 1),
      LayoutSlot(index: 1, orientation: SlotOrientation.landscape, x: 0.5, y: 0, w: 0.5, h: 0.5),
      LayoutSlot(index: 2, orientation: SlotOrientation.portrait, x: 0.5, y: 0.5, w: 0.5, h: 0.5),
    ],
  ),
  '3_03': LayoutDefinition(
    aspectRatio: 16 / 9, // wide canvas: 3 landscape videos stacked
    slots: [
      LayoutSlot(index: 0, orientation: SlotOrientation.landscape, x: 0, y: 0, w: 1, h: 1 / 3),
      LayoutSlot(index: 1, orientation: SlotOrientation.landscape, x: 0, y: 1 / 3, w: 1, h: 1 / 3),
      LayoutSlot(index: 2, orientation: SlotOrientation.landscape, x: 0, y: 2 / 3, w: 1, h: 1 / 3),
    ],
  ),
  '3_02': LayoutDefinition(
    aspectRatio: 16 / 9,
    slots: [
      LayoutSlot(index: 0, orientation: SlotOrientation.landscape, x: 0, y: 0, w: 1, h: 0.5),
      LayoutSlot(index: 1, orientation: SlotOrientation.landscape, x: 0, y: 0.5, w: 0.5, h: 0.5),
      LayoutSlot(index: 2, orientation: SlotOrientation.landscape, x: 0.5, y: 0.5, w: 0.5, h: 0.5),
    ],
  ),
};

class ChooseVideoScreen extends StatefulWidget {

  final Map<String, dynamic> layoutData;

  const ChooseVideoScreen({super.key, required this.layoutData});
  @override
  State<ChooseVideoScreen> createState()=>_ChooseVideoScreen();
}

class _ChooseVideoScreen extends State<ChooseVideoScreen>{
  final TextEditingController _searchController=TextEditingController();
  final Map<int, SampleVideo?> _slotSelections = {};
  final Set<int> _warnedSlots = {};
  

  LayoutDefinition? _getDefinitionForLayout(String layoutName) {
    if (layoutName == '4_01') {
      return kLayoutGeometry['4_01'];
    } else if (layoutName == '3_07') {
      return kLayoutGeometry['3_07'];
    } else if (layoutName == '3_06') {
      return kLayoutGeometry['3_06'];
    } else if (layoutName == '3_05') {
      return kLayoutGeometry['3_05'];
    } else if (layoutName == '3_04') {
      return kLayoutGeometry['3_04'];
    } else if (layoutName == '3_03') {
      return kLayoutGeometry['3_03'];
    } else if (layoutName == '3_02') {
      return kLayoutGeometry['3_02'];
    } else {
      return null; // layout not mapped yet
    }
  }

  @override
  Widget build(BuildContext context) {
    final String layoutName = widget.layoutData['layout_name'];
    final definition = _getDefinitionForLayout(layoutName);
    bool isNextEnabled= _slotSelections.length == (definition?.slots.length );
    
    return Scaffold(
      appBar: AppBar(
        leading:IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,color:Colors.yellow),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Choose videos — $layoutName')),
      body: definition == null
          ? Center(
              child: Text(
                'No geometry defined for layout "$layoutName" yet.',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : Stack(
            children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(16,60,16,16),
                  child: AspectRatio(
                    aspectRatio: definition.aspectRatio,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                         children: definition.slots.map((slot) {
                            return Positioned(
                              left: slot.x * constraints.maxWidth,
                              top: slot.y * constraints.maxHeight,
                              width: slot.w * constraints.maxWidth,
                              height: slot.h * constraints.maxHeight,
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: DragTarget<SampleVideo>(
                                  onWillAcceptWithDetails: (details) {
                                    final accpet= details.data.orientation == slot.orientation;
                                    if (!accpet && !_warnedSlots.contains(slot.index)) {
                                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                      _warnedSlots.add(slot.index);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Video orientation mismatch for slot #${slot.index+1} (${slot.orientation.name})',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          backgroundColor: Colors.redAccent,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                    return accpet;
                                  },
                                  onLeave:(details){
                                    _warnedSlots.remove(slot.index);
                                  },
                                  onAcceptWithDetails: (details) {
                                    setState(() {
                                      _slotSelections[slot.index] = details.data;
                                    });
                                  },
                                  builder: (context, candidateData, rejectedData) {
                                    final assignedVideo = _slotSelections[slot.index];
                                    final isHovering = candidateData.isNotEmpty;
                                    final isRejected = rejectedData.isNotEmpty;

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade800,
                                        border: Border.all(
                                          color: isRejected ? Colors.red: isHovering ? Colors.green : Colors.yellow,
                                          width: (isHovering||isRejected) ? 3 : 1,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: assignedVideo != null
                                          ? ClipRRect(
                                              child: Image.network(
                                                assignedVideo.thumbnailUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                              ),
                                            )
                                          : Text(
                                              '#${slot.index+1}\n${slot.orientation.name}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),
                DraggableScrollableSheet(
                  initialChildSize: 0.45,
                  minChildSize: 0.15,
                  maxChildSize: 0.9,
                  builder: (context, scrollController){
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 71, 71, 71),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        
                        children: [
                          
                           Container(     
                              margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),                 
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search videos...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                  filled: true,
                                  fillColor: Colors.black26,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (query) {
                                  // TODO: query
                                },
                              ),
                            ),
                          Expanded(
                              child:
                                GridView.builder(
                                  controller: scrollController, 
                                  padding: const EdgeInsets.all(12),
                                  itemCount: sampleVideos.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 1, //later, to be adjusted according to the video
                                  ),
                                  itemBuilder: (context, index) {
                                    final video = sampleVideos[index];
                                    return Draggable<SampleVideo>(
                                      data: video,
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(video.thumbnailUrl, fit: BoxFit.cover),
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.3,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(video.thumbnailUrl, fit: BoxFit.cover),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(video.thumbnailUrl, fit: BoxFit.cover),
                                      ),
                                    );
                                  },
                                ),
                          )
                              ],
                      
                          ),
                    );}
                ),
                Positioned(
                top:0,
                right:10,
                child: Container(
                  margin:const EdgeInsets.fromLTRB(0, 5, 0, 0),
                  decoration:BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isNextEnabled ? [
                      BoxShadow(
                        color: Colors.yellow.withValues(alpha:0.3),
                        blurRadius: 5,
                        spreadRadius: 0.5,
                      ),
                    ]:[],
                  ),
                  child: ElevatedButton(
                    style:ElevatedButton.styleFrom(
                      backgroundColor:Colors.yellow,
                      foregroundColor:Colors.black,
                      shape:RoundedRectangleBorder(
                        borderRadius:BorderRadius.circular(8),
                      ),
                    ),
                    onPressed:isNextEnabled ?(){} : null,
                    
                    child:const Text('Next'),
                    
                  ),
                ),
                )
              
                ]
                      ),
                    );
                    
                              }
}
                