// Importing necessary packages
import 'dart:async'; // For asynchronous operations
import 'dart:developer'; // For logging

import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // For caching files
import 'package:video_player/video_player.dart'; // For video playback

import 'models/video_model.dart'; // For video model

// Abstract class defining a service for obtaining video controllers
abstract class VideoControllerService {
  // Method to get a VideoPlayerController for a given video model
  Future<VideoPlayerController> getControllerForVideo(
    VideoModel videoModel,
    bool isCaching,
  );
}

// Implementation of VideoControllerService that uses caching
class CachedVideoControllerService extends VideoControllerService {
  final BaseCacheManager _cacheManager; // Cache manager instance

  // Constructor requiring a cache manager instance
  CachedVideoControllerService(this._cacheManager);

  @override
  Future<VideoPlayerController> getControllerForVideo(
    VideoModel videoModel,
    bool isCaching,
  ) async {
    final url = videoModel.url;

    if (isCaching) {
      FileInfo?
      fileInfo; // Variable to store file info if video is found in cache

      try {
        // Attempt to retrieve video file from cache
        fileInfo = await _cacheManager.getFileFromCache(url);
      } catch (e) {
        // Log error if encountered while getting video from cache
        log('Error getting video from cache: $e');
      }

      // Check if video file was found in cache
      if (fileInfo != null) {
        // Return VideoPlayerController for the cached file with additional options
        return VideoPlayerController.file(
          fileInfo.file,
          videoPlayerOptions: videoModel.videoPlayerOptions,
        );
      }

      try {
        // If video is not found in cache, attempt to download it
        _cacheManager.downloadFile(url);
      } catch (e) {
        // Log error if encountered while downloading video
        log('Error downloading video: $e');
      }
    }

    // Return VideoPlayerController for the video from the network with additional options
    return VideoPlayerController.networkUrl(
      Uri.parse(url),
      httpHeaders: videoModel.httpHeaders ?? {},
      videoPlayerOptions: videoModel.videoPlayerOptions,
    );
  }
}
