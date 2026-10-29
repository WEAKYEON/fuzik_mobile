import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const WebVideoPlayer({
    super.key,
    required this.videoUrl,
  });

  @override
  State<WebVideoPlayer> createState() => _WebVideoPlayerState();
}

class _WebVideoPlayerState extends State<WebVideoPlayer> {
  late WebViewController _controller;
  
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  @override
  void didUpdateWidget(covariant WebVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoUrl != widget.videoUrl) {
      _initializeWebView();
    }
  }

  Future<void> _initializeWebView() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    late final PlatformWebViewControllerCreationParams params;

  if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    params = WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const {},
    );
  } else {
    params = const PlatformWebViewControllerCreationParams();
  }

  final controller = WebViewController.fromPlatformCreationParams(params)
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.black);

  _controller = controller;

    final html = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport"
                content="width=device-width, initial-scale=1.0">
          <style>
            html, body {
              margin: 0;
              padding: 0;
              width: 100%;
              height: 100%;
              background: black;
              overflow: hidden;
            }

            video {
              width: 100%;
              height: 100%;
              object-fit: contain;
            }
          </style>
        </head>
        <body>
          <video controls playsinline preload="metadata">
            <source src="${widget.videoUrl}" type="video/mp4">
            Your browser cannot play this video.
          </video>
        </body>
      </html>
    ''';

    try {
      await _controller.loadHtmlString(
        html,
        baseUrl: 'https://fuzikapp.com',
      );

      if (!mounted) return;
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load video: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        WebViewWidget(controller: _controller),
        if (isLoading)
          const CircularProgressIndicator(
            color: Colors.yellow,
          ),
      ],
    );
  }
}