import 'package:flutter/material.dart';
import 'adjust_timeline.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum SlotOrientation { landscape, portrait }

Future<Map<String, List<Map<String, dynamic>>>> _fetchVideos({
    String query = '',
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);

      final lUri = Uri.parse(
        'https://engine01.fuzikapp.com/play2s_l/?q=$encodedQuery',
      );

      final pUri = Uri.parse(
        'https://engine01.fuzikapp.com/play2s_p/?q=$encodedQuery',
      );

      final responses = await Future.wait([
        http.get(lUri),
        http.get(pUri),
      ]);

      final lResponse = responses[0];
      final pResponse = responses[1];

      if (lResponse.statusCode != 200 || pResponse.statusCode != 200) {
        throw Exception('Failed to load videos');
      }

      final lData = jsonDecode(lResponse.body);
      final pData = jsonDecode(pResponse.body);

      final lvideos = List<Map<String, dynamic>>.from(lData);
      final pvideos = List<Map<String, dynamic>>.from(pData);
      Map<String, List<Map<String, dynamic>>> result = {
        'landscape': lvideos,
        'portrait': pvideos,
      };
      //print("Line 57: This is the result for p: ${result['portrait']}");
      return result;
    } catch (e) {
      print('Error fetching videos: $e');
      return {'landscape': [], 'portrait': []};
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
   String searchQuery = '';
   late List orientations;
    
     @override
      void dispose() {
        _searchController.dispose();
        super.dispose();
      }

List<SlotOrientation> getOrientationList(String layoutname){
  late List<SlotOrientation> result;
  if(layoutname=='4_01'){
    result=[SlotOrientation.landscape, SlotOrientation.landscape, SlotOrientation.landscape, SlotOrientation.landscape];
  }
  if(layoutname=='3_07'){
    result=[SlotOrientation.portrait,SlotOrientation.portrait,SlotOrientation.portrait];
  }
  if(layoutname=='3_06'){
    result=[SlotOrientation.landscape,SlotOrientation.portrait,SlotOrientation.portrait];
  }
  if(layoutname=='3_05'){
    result=[SlotOrientation.landscape,SlotOrientation.portrait,SlotOrientation.landscape];
  }
  if(layoutname=='2_01'||layoutname=='2_02'|| layoutname=='2_03'||layoutname=='2_04'||layoutname=='2_05'){
    result=[SlotOrientation.landscape,SlotOrientation.landscape];
  }
  if(layoutname=='3_03'||layoutname=='3_02'||layoutname=='3_01'){
    result=[SlotOrientation.landscape,SlotOrientation.landscape,SlotOrientation.landscape];
  }
  if(layoutname=='3_04'){
    result=[SlotOrientation.portrait,SlotOrientation.landscape,SlotOrientation.landscape];
  }
  if(layoutname=='2_06'||layoutname=='2_07'){
    result=[SlotOrientation.portrait,SlotOrientation.landscape];
  }
  if(layoutname=='2_08'){
    result=[SlotOrientation.portrait,SlotOrientation.portrait];
  }
  return result;
}

Future<bool> orientationChecker(Map<String,dynamic> videoInformation, SlotOrientation slotOrientaion) async{
   
    final videoCode=videoInformation['url'];
  
    Uri url=Uri.parse('https://engine01.fuzikapp.com/play2_watch?p=$videoCode');
    final response = await http.get(url);
    final data=jsonDecode(response.body);
    final dimension =data[0]['dimension'];
    final SlotOrientation videoOrientation;
    if (dimension == 'L') {
      videoOrientation = SlotOrientation.landscape;
    } else if (dimension == 'P') {
      videoOrientation = SlotOrientation.portrait;
    } else {
      throw FormatException('Unknown video dimension: $dimension');
    }
    bool audit=videoOrientation==slotOrientaion;
    return audit;
  }

Widget buildLayoutPreview(String layoutName, List<dynamic> selectedVideos, int totalVideo, bool isTablet) {
  switch (layoutName) {
    case '4_01': 
      return Column(
        children: [
          Expanded(child: Row(children: [
            Expanded(child: _slot(selectedVideos, 0)),
            Expanded(child: _slot(selectedVideos, 1)),
          ])),
          Expanded(child: Row(children: [
            Expanded(child: _slot(selectedVideos, 2)),
            Expanded(child: _slot(selectedVideos, 3)),
          ])),
        ],
      );

    case '3_07': 
      return Row(
        children: List.generate(3, (i) => Expanded(child: _slot(selectedVideos, i))),
      );

    case '3_06': 
      return Stack(
          children: [
            Positioned.fill(
              child: _slot(selectedVideos, 0),
            ),

            Positioned(
              right: 12,
              bottom: 12,
              width:isTablet?180:90,
              height:isTablet?320:160,             
              child: _slot(selectedVideos, 2),        
            ),

            Positioned(
              left: 12,
              bottom: 12,
              width:isTablet?180:90,
              height:isTablet?320:160,
              child: _slot(selectedVideos, 1),
            ),
          ],
        );

      case '3_05':
        return Stack(
          children: [
            Positioned.fill(
              child: _slot(selectedVideos, 0),
            ),

            Positioned(
              right: 12,
              bottom: 12,
              height:isTablet?180:90,
              width:isTablet?320:160,             
              child: _slot(selectedVideos, 2),             
            ),

            Positioned(
              left: 12,
              bottom: 12,
              width:isTablet?180:90,
              height:isTablet?320:160,
              child: _slot(selectedVideos, 1),
            ),
          ],
        );

      case '3_04':
      return LayoutBuilder(
        builder:(context, constraints){
         
          return Stack(
            children: [
              // Your video layout
              Positioned(
                width:3*constraints.maxWidth/10,
                height:constraints.maxHeight,
                child:_slot(selectedVideos, 0)
                ),
              
              Positioned(
                left:3*constraints.maxWidth/10,
                width: 5*constraints.maxWidth/10,
                height:constraints.maxHeight,
                child: Column(
                  children: [
                    Expanded(child: _slot(selectedVideos, 1)),
                    Expanded(child: _slot(selectedVideos, 2))
                  ],
                )),
              Positioned(
                left:8*constraints.maxWidth/10,
                width: 2*constraints.maxWidth/10,
                height: constraints.maxHeight,
                child: 
                Column(
                  children: [
                    SizedBox(
                      height: constraints.maxHeight/4,
                      child: DecorativeWaveform(color:Colors.cyanAccent,width: 2*constraints.maxWidth/10,)),
                    SizedBox(
                      height: constraints.maxHeight/4,
                      child: DecorativeWaveform(color:Colors.yellowAccent,width: 2*constraints.maxWidth/10,)),
                    SizedBox(
                      height: constraints.maxHeight/4,
                      child: DecorativeWaveform(color:Colors.lightBlueAccent,width: 2*constraints.maxWidth/10,)),
                    SizedBox(
                      height: constraints.maxHeight/4,
                      child: DecorativeWaveform(color:Colors.lightGreenAccent,width: 2*constraints.maxWidth/10,)),
                    
                
                  ],
                )
                )
            ],
          );
        }
      );
        
      case '3_02':
        return Stack(
          children:[
            Positioned.fill(child:_slot(selectedVideos, 0),),
            Positioned(
              left: 12,
              bottom: 12,
              child: Row(
              spacing:5,
              children:[
                SizedBox(
                  height:isTablet?180:90,
                  width:isTablet?320:160,
                  child:_slot(selectedVideos, 1), ),
                SizedBox(
                  height:isTablet?180:90,
                  width:isTablet?320:160,
                  child:_slot(selectedVideos, 2), ),
                ]
            ),)
          ]
        );
      case '3_01':
            return Stack(
          children:[
            Positioned.fill(child:_slot(selectedVideos, 0),),
            Positioned(
              left: 12,
              bottom: 12,
              child: Column(
              spacing:5,
              children:[
                SizedBox(
                  height:isTablet?180:90,
                  width:isTablet?320:160,
                  child:_slot(selectedVideos, 1), ),
                SizedBox(
                  height:isTablet?180:90,
                  width:isTablet?320:160,
                  child:_slot(selectedVideos, 2), ),
                ]
            ),)
          ]
        );
        case '2_07':
        return Stack(
          children:[
            Positioned.fill(
              child:_slot(selectedVideos, 0),
            ),
             Positioned(
              right: 12,
              bottom: 12,
              width:isTablet?180:90,
              height:isTablet?320:160,             
              child: _slot(selectedVideos, 1),
              
            ),
          ]
        );

        case '2_06':
        return LayoutBuilder(
          builder: (context, constraints){
            return Stack(
              children: [
                SizedBox(
                  width: constraints.maxWidth/3,
                  height: constraints.maxHeight,
                  child: _slot(selectedVideos, 0),
                ),
                Positioned(
                  left:constraints.maxWidth/3,
                  width: 2*constraints.maxWidth/3,
                  height: 4*constraints.maxHeight/5,
                  child: _slot(selectedVideos, 1)
                  ),
                Positioned(
                  left:constraints.maxWidth/3,
                  top:4*constraints.maxHeight/5,
                  child:DecorativeWaveform(
                    width: 2*constraints.maxWidth /9,
                    height: constraints.maxHeight/5,
                  ),
                   ),
                  Positioned(
                  left:constraints.maxWidth/3+2*constraints.maxWidth/9,
                  top:4*constraints.maxHeight/5,
                  child:DecorativeWaveform(
                    width: 2*constraints.maxWidth /9,
                    height: constraints.maxHeight/5,
                  ),
                   ),
                   Positioned(
                  left:7*constraints.maxWidth/9,
                  top:4*constraints.maxHeight/5,
                  child:DecorativeWaveform(
                    width: 2*constraints.maxWidth /9,
                    height: constraints.maxHeight/5,
                  ),
                   )
              ],
            );
          }
        );
        case '2_02':
        return Stack(
          children:[
            Positioned.fill(
              child:_slot(selectedVideos, 0),
            ),
             Positioned(
              left: 12,
              top: 12,
              height:isTablet?180:90,
              width:isTablet?320:160,             
              child: _slot(selectedVideos, 1),
              
            ),
          ]
        );
        case '2_03':
        return Stack(
          children:[
            Positioned.fill(
              child:_slot(selectedVideos, 0),
            ),
             Positioned(
              right: 12,
              top: 12,
              height:isTablet?180:90,
              width:isTablet?320:160,             
              child: _slot(selectedVideos, 1),
              
            ),
          ]
        );
        case '2_04':
        return Stack(
          children:[
            Positioned.fill(
              child:_slot(selectedVideos, 0),
            ),
             Positioned(
              right: 12,
              bottom: 12,
              height:isTablet?180:90,
              width:isTablet?320:160,             
              child: _slot(selectedVideos, 1),
              
            ),
          ]
        );
      case '2_01':
        return Stack(
          children:[
            Positioned.fill(
              child:_slot(selectedVideos, 0),
            ),
             Positioned(
              left: 12,
              bottom: 12,
              height:isTablet?180:90,
              width:isTablet?320:160,             
              child: _slot(selectedVideos, 1),
              
            ),
          ]
        );

    default:
      return const Center(child: Text('We are sorry. Layout preview is still in development', style: TextStyle(color: Colors.white54)));
  }
}

// Shared slot renderer — same widget type always, just swaps content
Widget _slot(List<dynamic> selectedVideos, int index) {
  final hasVideo = index < selectedVideos.length;
  return GestureDetector(
    onTap:  () {
    } , // wire up removal in your State class
    child: Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.yellow, width: 2)),
      child: hasVideo
          ?  CachedNetworkImage(
              imageUrl: selectedVideos[index]['preview']?.toString() ?? '',
              fit: BoxFit.cover,
            )
          : Container(
            decoration: BoxDecoration(
                color: Color(0xFF050505),
                border: Border.all(color: Colors.yellow, width: 1),
              ),
            child: Center(
                child: Text('${index + 1}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              ),
          ),
    ),
  );
}

  @override
  Widget build(BuildContext context){

    int totalVideo= widget.layoutData['l_videos_num'] + widget.layoutData['p_videos_num'];
    final layoutName= widget.layoutData['layout_name'];
    final screenSize=MediaQuery.of(context).size.shortestSide;
    final isTablet=screenSize>=600;
    bool isLandscape= orientation==SlotOrientation.landscape ;
    Future<Map<String, List<Map<String, dynamic>>>> videos=_fetchVideos(query: searchQuery); 
    Future<List<Map<String, dynamic>>> landscapeVideos=videos.then((value) => value['landscape'] ?? []);
    Future<List<Map<String, dynamic>>> portraitVideos=videos.then((value) => value['portrait'] ?? []);
    List<SlotOrientation> desiredOrientations= getOrientationList(layoutName);
    print('You are viewing $layoutName');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
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
                  child: AspectRatio(
                    aspectRatio: 16 / 9, 
                    child: SizedBox.expand(
                      child: buildLayoutPreview(
                        widget.layoutData['layout_name'],
                        selectedVideos,
                        totalVideo,
                        isTablet
                      ),
                    ),
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
                        disabledForegroundColor: Colors.black, 
                         
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
                      margin: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                      decoration:  BoxDecoration(
                        color: Color(0xFF242424),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        //border:Border(top: BorderSide(color: Colors.yellow, width: 2), ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellow.withValues(alpha: 0.3),
                            spreadRadius: 2,
                            blurRadius: 15,
                            offset: Offset(0, 3), // changes position of shadow
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [                         
                           Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.fromLTRB(15, 30, 8, 15),
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Search videos...',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Colors.grey,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 5,
                                  right: 12,
                                ),
                                child: SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        searchQuery = _searchController.text.trim();
                                        print('Search query: $searchQuery');
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFFD600),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                    ),
                                    child: const Text(
                                      'Search',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height: selectedVideos.isEmpty?0:115,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(15,0,15,0),
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
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
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
                          ),
                          SizedBox(width:double.infinity, height: 20,) ,
                          Expanded(
                              child:                               
                              FutureBuilder(                           
                                future: isLandscape?landscapeVideos:portraitVideos,
                                builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: Color(0xFFFFD600))));
                                }
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('ไม่พบข้อมูลวิดีโอ', style: TextStyle(color: Colors.white54, fontSize: 16))));
                                }
                                final videoData = snapshot.data!;
                                return Padding(
                                  padding: EdgeInsets.fromLTRB(15, 20, 15, 0),
                                  child: GridView.builder(
                                    controller: scrollController,
                                    shrinkWrap: true,
                                    //physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isTablet?orientation==SlotOrientation.portrait?5:3: orientation==SlotOrientation.portrait?3:2, 
                                      crossAxisSpacing: isTablet?10:5, 
                                      mainAxisSpacing: isTablet?10:5, 
                                      childAspectRatio: isLandscape?4/3:1/2, 
                                    ),
                                    itemCount: videoData.length,
                                    itemBuilder: (context, index) {
                                      final video = videoData[index];
                                  
                                      final preview = video['preview']?.toString()??'';
                                  
                                      return GestureDetector(
                                        onTap: ()async{
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
                                          
                                          int currentSelectVideoIndex=selectedVideos.length;
                                          SlotOrientation currentOrientation=desiredOrientations[currentSelectVideoIndex];
                                          
                                          Future<bool> orientationCheck=orientationChecker(video, currentOrientation);
                                          
                                          bool orientationCheckResult=await orientationCheck;
                                          if(!context.mounted){return;}
                                          if(!orientationCheckResult){
                                            ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Wrong Video Orientation'),
                                                duration: Duration(seconds: 2),
                                                behavior: SnackBarBehavior.floating,
                                                margin: EdgeInsets.all(16),
                                              ),
                                            );
                                            return;
                                          }
                                          setState(() =>selectedVideos.add(video)                                            
                                          );
                                        },
                                        child: Container(
                                          padding:const EdgeInsets.only(left: 2, right: 2),
                                          width: double.infinity,
                                            child: Column(
                                              children: [
                                                AspectRatio(
                                                  aspectRatio: isLandscape?16/9:9/16,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: Colors.yellow, width: 1.5),
                                                      borderRadius: BorderRadiusGeometry.circular(8),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: CachedNetworkImage(
                                                        imageUrl: preview,
                                                        fit:BoxFit.cover,
                                                        width: double.infinity,
                                                        placeholder: (context, url) => Center(child: CircularProgressIndicator(color:Colors.yellow)),
                                                        errorWidget: (context, url, error) => Icon(Icons.error),
                                                        ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: 5),
                                                Text('${video['video_title']}', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2,),
                                              ],
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

class DecorativeWaveform extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const DecorativeWaveform({
    super.key,
    this.color = Colors.black,
    this.width = 120,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color.fromARGB(255, 56, 55, 55)),
      width: width,
      height: height,
      child: CustomPaint(
        painter: DecorativeWaveformPainter(
          color: color,
        ),
      ),
    );
  }
}
class DecorativeWaveformPainter extends CustomPainter {
  final Color color;

  DecorativeWaveformPainter({
    required this.color,
  });

  final List<double> amplitudes = [
    0.25,
    0.45,
    0.70,
    0.85,
    0.69,
    0.70,
    0.75,
    0.60,
    0.25,
    0.45,
    0.70,
    0.65,
    1.00,
    0.60,
    0.75,
    0.65,
    0.82,
    0.65,
    0.48,
    0.35,
    0.25,
    0.45,
    0.70,
    0.85,
    1.00,
    0.70,
    0.75,
    0.60,
    0.25,
    0.45,
    0.70,
    0.65,
    1.00,
    0.60,
    0.75,
    0.65,
    0.82,
    0.65,
    0.48,
    0.35,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square;

    final centerY = size.height / 2;

    final spacing = size.width / (amplitudes.length + 1);

    for (int i = 0; i < amplitudes.length; i++) {
      final x = spacing * (i + 1);

      final lineHeight =
          size.height * 0.8 * amplitudes[i];

      final top = centerY - lineHeight / 2;
      final bottom = centerY + lineHeight / 2;

      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant DecorativeWaveformPainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}