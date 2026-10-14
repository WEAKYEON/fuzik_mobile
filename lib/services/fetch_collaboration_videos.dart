import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fuzik_mobile/services/fetch_videos.dart';

class CollaborationVideos{
  final List<Map<String, dynamic>> videos;
  final String error;

  CollaborationVideos({this.videos=const [], this.error=''});
  bool get hasError=>error.isNotEmpty;
}
  

  Future<CollaborationVideos> fetchCollaborationVideos({String query=''}) async{
    final encodedQuery = Uri.encodeComponent(query);
    final url=Uri.parse('https://engine01.fuzikapp.com/jam2s/?q=$encodedQuery');
    
    bool isOnline=await hasNetwork();
    if(!isOnline){
      return  CollaborationVideos(
        error: 'No internet connection. Turn on Wi-Fi or mobile data.'
      );
    }
    try{
      final response= await http.get(url, headers: {'Referer': 'https://fuzikapp.com'});
      if(response.statusCode==500){
        return CollaborationVideos(
          error: 'Server error occurred while loading videos',
        );
      }
      if(response.statusCode!=200){
        return CollaborationVideos(
          error: "Couldn't load the videos. Please try again later."
        );
      }
      final data=response.body;
      return CollaborationVideos(
        videos: List<Map<String, dynamic>>.from(jsonDecode(data))
      );
    }catch (error){
      return CollaborationVideos(error: 'Something went wrong while loading videos.');
    }
  }
