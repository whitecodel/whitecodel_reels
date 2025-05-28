// Importing necessary packages
import 'dart:async'; // For asynchronous operations
import 'dart:developer'; // For logging

import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // For caching files
import 'package:video_player/video_player.dart'; // For video playback

import 'models/video_model.dart'; // For video model

/// A service that provides methods to obtain video player controllers.
///
/// This abstract class defines the contract for services that manage
/// the creation and configuration of video player controllers.
abstract class VideoControllerService {
  /// Gets a VideoPlayerController for a given video model.
  ///
  /// [videoModel] contains the video URL and additional configuration options.
  /// [isCaching] determines whether the video should be cached for future use.
  ///
  /// Returns a [VideoPlayerController] configured for the given video.
  Future<VideoPlayerController> getControllerForVideo(
    VideoModel videoModel,
    bool isCaching,
  );
}

/// An implementation of [VideoControllerService] that supports video caching.
///
/// This service uses a [BaseCacheManager] to store and retrieve videos,
/// improving performance by reducing network requests for previously viewed videos.
class CachedVideoControllerService extends VideoControllerService {
  /// The cache manager used to store and retrieve video files.
  final BaseCacheManager _cacheManager;

  /// Creates a new [CachedVideoControllerService] with the provided cache manager.
  ///
  /// [_cacheManager] is responsible for handling the caching operations.
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
