import 'package:flutter/material.dart';
import 'adjust_timeline.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fuzik_mobile/services/fetch_videos.dart';

enum SlotOrientation { landscape, portrait }

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
   late Future<FetchVideos> _videosFuture;
  final DraggableScrollableController _sheetController =DraggableScrollableController();
    static const _sheetOpenSize=0.45;
    
    void reload(){
      setState(() {
        _videosFuture = fetchVideos(query: searchQuery);
      });
    }
    @override
    void initState(){
      super.initState();
      _videosFuture=fetchVideos(query:searchQuery);
    }
     @override
      void dispose() {
        _searchController.dispose();
        _sheetController.dispose();
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
                      child: DecorativeWaveform(color:Colors.yellow,width: 2*constraints.maxWidth/10,)),
                    SizedBox(
                      height: constraints.maxHeight/4,
                      child: DecorativeWaveform(color:Colors.yellow,width: 2*constraints.maxWidth/10,)),
                    SizedBox(
                      height: constraints.maxHeight/4,
                      child: DecorativeWaveform(color:Colors.yellow,width: 2*constraints.maxWidth/10,)),
                    SizedBox(
                      height: constraints.maxHeight/4,
                      child: DecorativeWaveform(color:Colors.yellow,width: 2*constraints.maxWidth/10,)),
                    
                
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
                    width: 2*constraints.maxWidth /3,
                    height: constraints.maxHeight/5,
                    extraNumberOfAmplitudes: 60,
                  
                  ),
                   ),
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
        return LayoutBuilder(
          builder: (context,c) {
            final secondVideoWidth=2*c.maxWidth/5;
            return Stack(
              children:[
                Positioned.fill(
                  child:_slot(selectedVideos, 0),
                ),
                 Positioned(
                  left: 12,
                  bottom: 12,
                  height:isTablet?secondVideoWidth*9/16:90,
                  width:isTablet?secondVideoWidth:160,             
                  child: _slot(selectedVideos, 1),
                  
                ),
              ]
            );
          }
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
    final bool isTabletLandscape=isTablet?MediaQuery.of(context).size.width>MediaQuery.of(context).size.height:false;
    bool isLandscape= orientation==SlotOrientation.landscape ;
    List<SlotOrientation> desiredOrientations= getOrientationList(layoutName);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.yellow),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Video (${selectedVideos.length}/$totalVideo)',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context,c) {
            final collapsedSize = (44 / c.maxHeight).clamp(0.05, _sheetOpenSize);
            //44 is the height of the arrowtip which appears at the top of the sheet.
            //For future developers, if you want to change one of them, change both.
            final fullHeight = c.maxHeight * 0.9;
            return Stack(
              children: [
                Column(
                  children: [
                    Container(
                      width: isTabletLandscape?2*c.maxWidth/3:c.maxWidth,
                      margin: EdgeInsets.only(top:20),
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

                    SizedBox(
                      height: isTablet ? 24 : 16,
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
                  controller: _sheetController,
                      initialChildSize: _sheetOpenSize,
                      minChildSize: collapsedSize,
                      maxChildSize: 0.9,
                      snap:true,
                      snapSizes: [collapsedSize, _sheetOpenSize],
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
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.topCenter,
                              minHeight: 0,
                              maxHeight: fullHeight,
                              child: Column(
                                children: [
                                  _buildSheetArrow(collapsedSize),
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
                                                _videosFuture=fetchVideos(query: searchQuery);
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
                                  Expanded(
                                    child: ListView(
                                      controller: scrollController,
                                      padding: EdgeInsets.zero,
                                      children: [

                                    SizedBox(
                                      height: selectedVideos.isEmpty?0:115,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(15,0,15,0),
                                          child: Row(
                                            
                                            children: [
                                              ...selectedVideos.asMap().entries.map((entry) {
                                                final index = entry.key;
                                                final video = entry.value;

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
                                                      top: isTablet ? 8 : 6,
                                                      left: isTablet ? 12 : 10,
                                                      child: Container(
                                                        width: isTablet ? 28 : 22,
                                                        height: isTablet ? 28 : 22,
                                                        decoration: const BoxDecoration(
                                                          color: Color(0xFFFFD600),
                                                          shape: BoxShape.circle,
                                                        ),
                                                        alignment: Alignment.center,
                                                        child: Text(
                                                          '${index + 1}',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: isTablet ? 13 : 11,
                                                          ),
                                                        ),
                                                      ),
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
                                      FutureBuilder<FetchVideos>(                           
                                        future:_videosFuture,
                                        builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Padding(
                                            padding: EdgeInsets.only(top: 40),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                  color: Color(0xFFFFD600),
                                              ),
                                            ),
                                          );
                                        }
                                        final result=snapshot.data;
                                        if (result == null || result.hasError) {
                                          return Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(40),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(result?.error ?? 'Something went wrong.',
                                                      style: const TextStyle(color: Colors.white54, fontSize: 16)),
                                                  const SizedBox(height: 12),
                                                  ElevatedButton(onPressed: reload, child: const Text('Retry')),
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                        final videoData=isLandscape?result.landscape:result.portrait;
                                        if (videoData.isEmpty) {
                                          return const Center(
                                            child: Padding(
                                              padding: EdgeInsets.all(40),
                                              child: Text('ไม่พบข้อมูลวิดีโอ',
                                                  style: TextStyle(color: Colors.white54, fontSize: 16)),
                                            ),
                                          );
                                        }
                                        return Padding(
                                          padding: EdgeInsets.fromLTRB(15, 20, 15, 0),
                                          child: GridView.builder(
                                            //controller: scrollController,
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: isTablet?orientation==SlotOrientation.portrait?5:3: orientation==SlotOrientation.portrait?3:2, 
                                              crossAxisSpacing: isTablet?10:8,
                                              mainAxisSpacing: isTablet?10:8,
                                              childAspectRatio: isTablet
                                                  ? (isLandscape? 1.20 : 0.48)
                                                  : (isLandscape ? 1.10 : 0.42),
                                            ),
                                            itemCount: videoData.length,
                                            itemBuilder: (context, index) {
                                              final video = videoData[index];
                                          
                                              final preview = video['preview']?.toString()??'';
                                              final selectedIndex = selectedVideos.indexWhere(
                                                    (selected) => selected['url'] == video['url'],
                                              );

                                              final isSelected = selectedIndex != -1;
                                          
                                              return GestureDetector(
                                                onTap: ()async{
                                                  final alreadySelected = selectedVideos.any(
                                                    (selected) => selected['url'] == video['url'],
                                                  );
                                                  if (selectedVideos.length >=totalVideo) {
                                                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                       const SnackBar(         
                                                        backgroundColor: Colors.yellow,
                                                        content: Text('Maximum video reached',style: TextStyle(color: Colors.black),),
                                                        duration: Duration(seconds: 2),
                                                        behavior: SnackBarBehavior.floating,
                                                        margin: EdgeInsets.all(16),
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  if (alreadySelected) {
                                                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        backgroundColor: Colors.yellow,
                                                        content: Text('This video is already selected', style: TextStyle(color: Colors.black)),
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
                                            child: Stack(
                                              children: [
                                                Container(
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
                                                        Text('${video['video_title']}', style: TextStyle(color: Colors.white, fontSize: isTablet ? 15 : 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, maxLines: 2,),
                                                      ],
                                                    ),
                                                  
                                                ),
                                                if (isSelected)
                                                  Positioned(
                                                    top: isTablet ? 10 : 6,
                                                    right: isTablet ? 10 : 6,
                                                    child: Container(
                                                      width: isTablet ? 32 : 24,
                                                      height: isTablet ? 32 : 24,
                                                      decoration: const BoxDecoration(
                                                        color: Color(0xFFFFD600),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      alignment: Alignment.center,
                                                      child: Text(
                                                        '${selectedIndex + 1}',
                                                        style: TextStyle(
                                                          color: Colors.black,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: isTablet ? 14 :11,
                                                        ),
                                                       ),
                                                    ),
                                                  ),
                                              ],
                                            ),

                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),

                                      ],
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ),
                        );
                      },
                ),

              ],
            );
          },
        ),
      ),
    );
  }

Widget _buildSheetArrow(double collapsedSize) {
  return ListenableBuilder(
    listenable: _sheetController,
    builder: (context, _) {
      final size = _sheetController.isAttached
          ? _sheetController.size
          : _sheetOpenSize;
      final isCollapsed = size < (collapsedSize + _sheetOpenSize) / 2;

      return SizedBox(
        height: 44,
        child: Center(
          child: IconButton(
            tooltip: isCollapsed ? 'Show videos' : 'Hide videos',
            icon: Icon(
              isCollapsed
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: Colors.yellow,
              size: 30,
            ),
            onPressed: () {
              _sheetController.animateTo(
                isCollapsed ? _sheetOpenSize : collapsedSize,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
              );
            },
          ),
        ),
      );
    },
  );
}
}

class DecorativeWaveform extends StatelessWidget {
  final Color color;
  final double width;
  final double height;
  final int extraNumberOfAmplitudes;

  const DecorativeWaveform({
    super.key,
    this.color = Colors.yellow,
    this.width = 120,
    this.height = 60,
    this.extraNumberOfAmplitudes=0
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 56, 55, 55),
        border: Border.all(color:Colors.yellow),
        ),
      width: width,
      height: height,
      child: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(10, 10, 10, 10),
        child: CustomPaint(
          painter: DecorativeWaveformPainter(
            color: color,
            extraNumberOfAmplitues: extraNumberOfAmplitudes
          ),
        ),
      ),
    );
  }
}
class DecorativeWaveformPainter extends CustomPainter {
  final Color color;
  final int extraNumberOfAmplitues;

  DecorativeWaveformPainter({
    required this.color,
    required this.extraNumberOfAmplitues
  });
  double randomDoubleInRange(double min, double max) {
    final random = Random();
    return random.nextDouble() * (max - min) + min;
  }
  late List<double> extraAmplitudes=List<double>.generate(extraNumberOfAmplitues, (_)=> randomDoubleInRange(0.2, 0.9),);
   List<double> initialAmplitudes = [
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
    0.75,
    0.45,
    0.30,
    0.40,
  ];
  late List<double> amplitudes=[...initialAmplitudes,...extraAmplitudes];
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