import 'package:flutter/material.dart';
import 'package:fuzik_mobile/services/fetch_layouts.dart';
import 'choose_video2.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CollaborationContent extends StatefulWidget {
  final bool showBackButton; 

  const CollaborationContent({super.key, this.showBackButton = false});

  @override
  State<CollaborationContent> createState() => _CollaborationContentState();
}

class _CollaborationContentState extends State<CollaborationContent> {
  late Future<VideoLayouts> _layoutsFuture;

  Future<void> _refresh()async{
    final freshLayouts= fetchLayouts();
    setState(() {
      _layoutsFuture=freshLayouts;
    });
    await freshLayouts;
  }

  @override
  void initState() {
    super.initState();
    _layoutsFuture = fetchLayouts();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int columns = screenWidth < 400 ? 1 : (screenWidth < 800 ? 2 : 4);
    double padding = screenWidth < 600 ? 16.0 : 40.0;

    return Scaffold(
        backgroundColor: Colors.black,    
        body: RefreshIndicator(
          onRefresh: _refresh,
          backgroundColor: Colors.yellow,
          color:Colors.black,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: 
            Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Collaboration Layout',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a template to merge your videos together.',
            style: TextStyle(color: Colors.white.withValues(alpha:0.6), fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          FutureBuilder<VideoLayouts>(
            future: _layoutsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFD600),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'No layouts found',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }

              final layoutsList = snapshot.data!;

              if (layoutsList.hasError) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Error: ${layoutsList.error}. Swipe down to refresh.',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              if (layoutsList.layouts.isEmpty) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'No layouts found',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: layoutsList.layouts.length,
                itemBuilder: (context, index) {
                  final layoutData = layoutsList.layouts[index];

                  final String imagePath = layoutData['layout_file_location'];
                  final String imageUrl =
                      'https://media05.fuzikapp.com/$imagePath';

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChooseVideo2(layoutData: layoutData),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFD600),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          widget.showBackButton? 
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5
                  )
                  ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                  foregroundColor: Colors.black
                ),
                onPressed: (){
                Navigator.pop(context);
              }, child: Text('Back')
              ),
            ),
          ) 
          :Container()
        ],
      ),
    )
    )
    ),
      );
  }
}