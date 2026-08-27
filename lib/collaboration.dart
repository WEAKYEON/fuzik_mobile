import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'choose_video2.dart';

class CollaborationContent extends StatefulWidget {
  final bool showBackButton; 

  const CollaborationContent({super.key, this.showBackButton = false});

  @override
  State<CollaborationContent> createState() => _CollaborationContentState();
}

class _CollaborationContentState extends State<CollaborationContent> {
  late Future<List<dynamic>> _layoutsFuture;

  @override
  void initState() {
    super.initState();
    _layoutsFuture = fetchLayouts();
  }

  Future<List<dynamic>> fetchLayouts() async {
    try {
      final response = await http.get(Uri.parse('https://engine01.fuzikapp.com/layouts?q=a'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data; 
      } else {
        throw Exception('Failed to load layouts');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int columns = screenWidth < 400 ? 1 : (screenWidth < 800 ? 2 : 4);
    double padding = screenWidth < 600 ? 16.0 : 40.0;

    Widget content = Padding(
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
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _layoutsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD600)));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No layouts found', style: TextStyle(color: Colors.white)));
                }

                final layoutsList = snapshot.data!;

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: layoutsList.length,
                  itemBuilder: (context, index) {
                    final layoutData = layoutsList[index];
                    
                    final String imagePath = layoutData['layout_file_location'];
                    final String imageUrl = 'https://media05.fuzikapp.com/$imagePath';
                    final String layoutName = layoutData['layout_name'];

                    return InkWell(
                      onTap: () {
                        print('You are viewing $layoutName');
                        print("This is the layout data: $layoutData");
                        print("Layout: $layoutsList");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChooseVideo2(layoutData: layoutData),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white, 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40));
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );

    if (widget.showBackButton) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: content,
      );
    }

    return content;
  }
}