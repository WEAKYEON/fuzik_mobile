import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VideoLayouts{
  final String error;
  final List<dynamic> layouts;

  const VideoLayouts({this.error= '',this.layouts=const []});
  bool get hasError=>error.isNotEmpty;

}

  Future<bool> online() async{
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.hasConnectivity) {
      return true;
    }
    return false;
  }


  Future<VideoLayouts> fetchLayouts() async {
    if(!await online()){
      return VideoLayouts(error:'No internet connection. Turn on Wi-Fi or mobile data.');
    }
    try {
      final response = await http.get(Uri.parse('https://engine01.fuzikapp.com/layouts?q=a')).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> layouts = json.decode(response.body);
        return VideoLayouts(layouts: layouts); 
      }
      if(response.statusCode==500){
        return VideoLayouts(error: 'Server error occurred while loading videos');
      }
      return VideoLayouts(error:'Cannot fetch the layouts. Please try again later.');
    }on TimeoutException{
      return VideoLayouts(error: 'Your connection is too slow. Please try again later.');
    }
    on SocketException {
    return  VideoLayouts(error: 'Could not reach the server. Check your connection.');
    } on FormatException {
    return  VideoLayouts(error: 'Received an unexpected response from the server.');
    }
    catch (e) {
      return VideoLayouts(error: 'There is an error while fetching the layouts. Please try again later. Error: $e');
    }
  }