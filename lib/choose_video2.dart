import 'package:flutter/material.dart';
import 'adjust_timeline.dart';

enum SlotOrientation { landscape, portrait }
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
class ChooseVideo2 extends StatefulWidget{
  const ChooseVideo2({super.key, required this.layoutData});
  final Map<String, dynamic> layoutData;
  
  @override
  State<ChooseVideo2> createState()=> _ChooseVideo2State();
}

class _ChooseVideo2State extends State<ChooseVideo2>{
   final TextEditingController _searchController=TextEditingController();
   List<SampleVideo> selectedVideos = [];
  @override
  Widget build(BuildContext context){
    print('Choose: ${widget.layoutData}');
    int totalVideo= widget.layoutData['l_videos_num'] + widget.layoutData['p_videos_num'];
    final imagePath = widget.layoutData['layout_file_location'];
    final imageUrl = 'https://media05.fuzikapp.com/$imagePath';
    final layoutName= widget.layoutData['layout_name'];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.yellow),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Video ($totalVideo)',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                                        return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40));
                                      },
                              ),
                ),
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: selectedVideos.length==totalVideo? [
                        BoxShadow(color:Colors.yellow.withValues(alpha: 0.4),

                        blurRadius: 5,
                        spreadRadius: 1.5)
                        ]:[]
                    ),
                    child: ElevatedButton(
                      style:ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: const Color.fromARGB(255, 99, 94, 45), 
                        disabledForegroundColor: Colors.grey[600], 
                         
                      ),
                      onPressed: selectedVideos.length==totalVideo?(){
                         Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdjustTimelineScreen(
                                layoutName: layoutName,
                                selectedVideos: selectedVideos
                                   // ส่ง Map ของวิดีโอที่เลือกไปด้วย
                              ),
                            ),
                          );
                        } 
                      :null, 
                    child: const Text("Next")
                    ),
                  ),
                )
              ],
            ),
            DraggableScrollableSheet(
                  initialChildSize: 0.45,
                  minChildSize: 0.45,
                  maxChildSize: 0.9,
                  builder: (context, scrollController){
                    return Container(
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 71, 71, 71),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          
                           Container(  // Search bar   
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
                            SizedBox(
                              height: selectedVideos.isEmpty?0:115,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(6,0,6,0),
                                  child: Row(
                                    
                                    children: [
                                      ...selectedVideos.map((video) {
                                  
                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(                                           
                                              margin: EdgeInsets.fromLTRB(6,0,6,0),
                                              decoration: BoxDecoration(
                                                border: BoxBorder.all(color:Colors.yellow,width: 1)
                                              ),
                                              child:Image.network(
                                                video.thumbnailUrl,
                                                width: 100,
                                                height: 100,
                                                fit:BoxFit.cover,
                                              )
                                            ),
                                            Positioned(
                                              top:-5,
                                              right: -5,
                                              child: GestureDetector(
                                                onTap: (){
                                                  setState(() {
                                                    selectedVideos.remove(video);
                                                    totalVideo=totalVideo-selectedVideos.length;
                                                    });
                                                  },
                                                child: Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    
                                                    borderRadius: BorderRadius.circular(25),
                                                    color: Colors.red
                                                  ),
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 14,),
                                                ),
                                              ),
                                            )
                                          ],
                                        );
                                      }),
                                    ],
                                  ),
                                ),
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
                                    return GestureDetector(
                                      onTap: (){
                                        if(selectedVideos.length>=totalVideo){
                                          ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            
                                            SnackBar(
                                              content: Text(
                                                'You can only select $totalVideo videos.',
                                              ),
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                              margin: const EdgeInsets.all(16),
                                            ),
                                          );
                                          return;
                                        }
                                        setState(() {
                                          selectedVideos.add(video);
                                          });
                                      },
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
          ],
        ),
      ),
    );
  }
}