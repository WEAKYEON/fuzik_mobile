import 'package:flutter/material.dart';
import 'adjust_timeline.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum SlotOrientation { landscape, portrait }

Future<List<Map<String, dynamic>>> _fetchLandscapeVideos() async {
    try {     
      final url=Uri.parse('https://engine01.fuzikapp.com/play2s_l/');
      final response= await http.get(url);
        if (response.statusCode == 200) {
        // jsonDecode parses the raw string into a Dart Map or List
          final data = List<Map<String, dynamic>>.from(jsonDecode(response.body),);         
          return data;
        } else {
          
          throw Exception('Failed to load data');
        } 
    } catch (e) {
      print('There is an error while fetching the landscape videos: $e');
      return [];
    }
  }

Future<List<Map<String, dynamic>>> _fetchPortraitVideos() async {
    try {     
      final url=Uri.parse('https://engine01.fuzikapp.com/play2s_p/');
      final response= await http.get(url);
        if (response.statusCode == 200) {
        // jsonDecode parses the raw string into a Dart Map or List
          final data = List<Map<String, dynamic>>.from(jsonDecode(response.body),);         
          return data;
        } else {
          
          throw Exception('Failed to load data');
        } 
    } catch (e) {
      print('There is an error while fetching the landscape videos: $e');
      return [];
    }
  }

class ChooseVideo2 extends StatefulWidget{
  const ChooseVideo2({super.key, required this.layoutData});
  final Map<String, dynamic> layoutData;
  
  @override
  State<ChooseVideo2> createState()=> _ChooseVideo2State();
}

class _ChooseVideo2State extends State<ChooseVideo2>{
   final TextEditingController _searchController=TextEditingController();
   List<Map<String,dynamic>> selectedVideos = [];
   SlotOrientation orientation=SlotOrientation.landscape;

  @override
  Widget build(BuildContext context){
    //print('Chosen: ${widget.layoutData}');
    int totalVideo= widget.layoutData['l_videos_num'] + widget.layoutData['p_videos_num'];
    final imagePath = widget.layoutData['layout_file_location'];
    final imageUrl = 'https://media05.fuzikapp.com/$imagePath';
    final layoutName= widget.layoutData['layout_name'];

    bool isLandscape= orientation==SlotOrientation.landscape ;
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
                                                video['preview'],
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
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                            child: CupertinoSlidingSegmentedControl<SlotOrientation>(
                              groupValue: orientation,
                              backgroundColor: Colors.black26,
                              thumbColor: Colors.yellow,
                              onValueChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    orientation = value;
                                    print(orientation);
                                  });
                                }
                              },
                              children: {
                                SlotOrientation.landscape: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.crop_landscape_rounded,
                                        size: 16,
                                        color: orientation == SlotOrientation.landscape ? Colors.black : Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Landscape',
                                        style: TextStyle(
                                          color: orientation == SlotOrientation.landscape ? Colors.black : Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SlotOrientation.portrait: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.crop_portrait_rounded,
                                        size: 16,
                                        color: orientation == SlotOrientation.portrait ? Colors.black : Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Portrait',
                                        style: TextStyle(
                                          color: orientation == SlotOrientation.portrait ? Colors.black : Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              },
                            ),
                          ),
                          SizedBox(width:double.infinity, height: 20,) ,
                          Expanded(
                              child:                               
                              FutureBuilder(
                                                          
                                future: isLandscape?_fetchLandscapeVideos():_fetchPortraitVideos(),
                                builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFFFFD600))));
                                }
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('ไม่พบข้อมูลวิดีโอ', style: TextStyle(color: Colors.white54, fontSize: 16))));
                                }
                                final videos = snapshot.data!;
                                return Padding(
                                  padding: EdgeInsets.fromLTRB(5, 20, 5, 0),
                                  child: GridView.builder(
                                    controller: scrollController,
                                    shrinkWrap: true,
                                    //physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3, 
                                      crossAxisSpacing: 10, 
                                      mainAxisSpacing: 10, 
                                      childAspectRatio: isLandscape?16/9:9/16, 
                                    ),
                                    itemCount: videos.length,
                                    itemBuilder: (context, index) {
                                      final video = videos[index];
                                  
                                      final preview = video['preview']?.toString()??'';
                                  
                                      return GestureDetector(
                                        onTap: (){
                                          
                                          final alreadySelected = selectedVideos.any(
                                            (selected) => selected['url'] == video['url'],
                                          );

                                          if (alreadySelected) {
                                            ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('This video is already selected'),
                                                duration: Duration(seconds: 2),
                                                behavior: SnackBarBehavior.floating,
                                                margin: EdgeInsets.all(16),
                                              ),
                                            );
                                            return;
                                          }
                                          if (selectedVideos.length >=totalVideo) {
                                            ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Maximum video reached'),
                                                duration: Duration(seconds: 2),
                                                behavior: SnackBarBehavior.floating,
                                                margin: EdgeInsets.all(16),
                                              ),
                                            );
                                            return;
                                          }
                                          setState(() {
                                          
                                            selectedVideos.add(video);
                                            
                                          });
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadiusGeometry.circular(5),
                                          child: CachedNetworkImage(
                                            imageUrl: preview,
                                            fit:BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                            placeholder: (context, url) => Center(child: CircularProgressIndicator(color:Colors.yellow)),
                                            errorWidget: (context, url, error) => Icon(Icons.error),
                                                                            ),
                                        ),
                                      );
                                    },
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