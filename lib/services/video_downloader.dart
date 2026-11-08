import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads a video and saves it to the phone's gallery.
///
/// Usage:
///   final downloader = VideoDownloader();
///   final result = await downloader.downloadToGallery(
///     url: videoUrl,
///     fileName: 'fuzik_$code',
///     album: 'Fuzik',                       // optional
///     onProgress: (p) { ... },              // 0.0 - 1.0, or null if the size is unknown
///   );
///   if (result.isSuccess) { ... } else { show result.message }
///
/// Needs dio, gal and path_provider in pubspec.yaml.
/// iOS: add NSPhotoLibraryAddUsageDescription to Info.plist
/// (and NSPhotoLibraryUsageDescription if you save into an album).

enum DownloadStatus { success, permissionDenied, cancelled, failed }

class DownloadResult {
  final DownloadStatus status;
  final String? message;

  const DownloadResult(this.status, [this.message]);

  bool get isSuccess => status == DownloadStatus.success;
}

class VideoDownloader {
  VideoDownloader({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));

  static const String _referer = 'https://fuzikapp.com';

  final Dio _dio;
  CancelToken? _cancelToken;

  /// True while a download is running. One download at a time per instance.
  bool get isDownloading => _cancelToken != null;

  /// Stops the running download (its result will be DownloadStatus.cancelled).
  void cancel() => _cancelToken?.cancel('Cancelled by user');

  Future<DownloadResult> downloadToGallery({
    required String url,
    required String fileName,
    String? album,
    void Function(double? progress)? onProgress,
  }) async {
    if (isDownloading) {
      return const DownloadResult(
        DownloadStatus.failed,
        'A download is already running.',
      );
    }

    // 1. Gallery permission
    final toAlbum = album != null;
    try {
      if (!await Gal.hasAccess(toAlbum: toAlbum)) {
        final granted = await Gal.requestAccess(toAlbum: toAlbum);
        if (!granted) {
          return const DownloadResult(
            DownloadStatus.permissionDenied,
            'Permission to save to the gallery was denied.',
          );
        }
      }
    } on GalException catch (e) {
      return DownloadResult(DownloadStatus.permissionDenied, e.type.message);
    }

    final cancelToken = _cancelToken = CancelToken();
    final dir = await getTemporaryDirectory();
    final base = _safeName(fileName);
    final partFile = File('${dir.path}/$base.mp4.part');
    final videoFile = File('${dir.path}/$base.mp4');

    try {
      // 2. Download to a .part file, so a half-finished file is never saved
      final response = await _dio.download(
        url,
        partFile.path,
        cancelToken: cancelToken,
        options: Options(
          headers: {'Referer': _referer},
          // stops if no data arrives for this long
          receiveTimeout: const Duration(seconds: 60),
        ),
        onReceiveProgress: (received, total) {
          onProgress?.call(total > 0 ? received / total : null);
        },
      );

      // 3. Make sure we really got a video, not an error page
      final type =
          (response.headers.value(Headers.contentTypeHeader) ?? '').toLowerCase();
      final size = await partFile.length();
      if (size < 1024 || type.startsWith('text/') || type.contains('json')) {
        final bytes = <int>[];
        await for (final chunk in partFile.openRead(0, 200)) {
          bytes.addAll(chunk);
        }
        debugPrint('Download is not a video ($type, $size bytes): '
            '${String.fromCharCodes(bytes)}');
        return const DownloadResult(
          DownloadStatus.failed,
          'The server did not return a valid video.',
        );
      }

      // 4. Give it the .mp4 name and save it to the gallery
      if (await videoFile.exists()) await videoFile.delete();
      await partFile.rename(videoFile.path);
      await Gal.putVideo(videoFile.path, album: album);

      return const DownloadResult(DownloadStatus.success);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        return const DownloadResult(DownloadStatus.cancelled);
      }
      debugPrint('Download error: $e');
      return DownloadResult(DownloadStatus.failed, _dioMessage(e));
    } on GalException catch (e) {
      return DownloadResult(
        e.type == GalExceptionType.accessDenied
            ? DownloadStatus.permissionDenied
            : DownloadStatus.failed,
        e.type.message,
      );
    } catch (e) {
      debugPrint('Download error: $e');
      return DownloadResult(
        DownloadStatus.failed,
        'Could not save the video: $e',
      );
    } finally {
      _cancelToken = null;
      // The gallery keeps its own copy, so remove our temporary files
      for (final f in [partFile, videoFile]) {
        try {
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
    }
  }

  String _safeName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'\.mp4$', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^A-Za-z0-9_\- ]'), '_')
        .trim();
    return cleaned.isEmpty ? 'fuzik_video' : cleaned;
  }

  String _dioMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Your connection is too slow. Please try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Check your connection.';
      case DioExceptionType.badResponse:
        return 'The server returned an error (${e.response?.statusCode}).';
      default:
        return 'The download failed. Please try again.';
    }
  }
}