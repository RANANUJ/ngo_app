import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class VideoCacheManager {
  static final CacheManager _instance = CacheManager(
    Config(
      'videoCacheKey',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 50,
    ),
  );

  /// Check if the video is already fully cached. Returns the File if cached, else null.
  static Future<File?> getCachedFile(String url) async {
    try {
      final fileInfo = await _instance.getFileFromCache(url);
      if (fileInfo != null && fileInfo.file.existsSync()) {
        return fileInfo.file;
      }
      return null;
    } catch (e) {
      debugPrint("VideoCacheManager: Error checking cache for $url: $e");
      return null;
    }
  }

  /// Prefetch a video file into local storage in the background.
  static void prefetchVideo(String url) {
    if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return;
    }
    _instance.downloadFile(url).then((_) {
      debugPrint("VideoCacheManager: Successfully prefetched $url");
    }).catchError((e) {
      debugPrint("VideoCacheManager: Prefetch failed for $url: $e");
    });
  }
}
