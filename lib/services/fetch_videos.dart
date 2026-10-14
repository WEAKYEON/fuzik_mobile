import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FetchVideos {
  final List<Map<String, dynamic>> landscape;
  final List<Map<String, dynamic>> portrait;
  final String error;

  const FetchVideos({
    this.landscape = const [],
    this.portrait = const [],
    this.error = '',
  });

  bool get hasError => error.isNotEmpty;
}

/// Reusable network check. Other screens can call this too.
Future<bool> hasNetwork() async {
  final results = await Connectivity().checkConnectivity();
  return !results.every((r) => r == ConnectivityResult.none);
}

//Fetch Solo videos
Future<FetchVideos> fetchVideos({String query = ''}) async {
  if (!await hasNetwork()) {
    return const FetchVideos(
      error: 'No internet connection. Turn on Wi-Fi or mobile data.',
    );
  }

  try {
    final encodedQuery = Uri.encodeComponent(query);
    const headers = {'Referer': 'https://fuzikapp.com'};

    final responses = await Future.wait([
      http.get(
        Uri.parse('https://engine01.fuzikapp.com/play2s_l/?q=$encodedQuery'),
        headers: headers,
      ),
      http.get(
        Uri.parse('https://engine01.fuzikapp.com/play2s_p/?q=$encodedQuery'),
        headers: headers,
      ),
    ]).timeout(const Duration(seconds: 15));

    final lResponse = responses[0];
    final pResponse = responses[1];

    if (lResponse.statusCode >= 500 || pResponse.statusCode >= 500) {
      return const FetchVideos(
        error: 'Server error occurred while loading videos',
      );
    }
    if (lResponse.statusCode != 200 || pResponse.statusCode != 200) {
      return const FetchVideos(error: 'Failed to load videos');
    }

    return FetchVideos(
      landscape: List<Map<String, dynamic>>.from(jsonDecode(lResponse.body)),
      portrait: List<Map<String, dynamic>>.from(jsonDecode(pResponse.body)),
    );
  } on TimeoutException {
    return const FetchVideos(error: 'The connection is too slow. Please try again.');
  } on SocketException {
    return const FetchVideos(error: 'Could not reach the server. Check your connection.');
  } on FormatException {
    return const FetchVideos(error: 'Received an unexpected response from the server.');
  } catch (e) {
    debugPrint('Error fetching videos: $e');
    return const FetchVideos(error: 'Something went wrong while loading videos.');
  }
}