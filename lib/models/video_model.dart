import 'package:video_player/video_player.dart';

/// Model class representing a video to be played in the reels.
///
/// Contains all the necessary information to load and play a video,
/// including the URL and optional configuration parameters.
class VideoModel {
  /// The URL of the video to be played.
  final String url;

  /// Optional HTTP headers to use when opening the video.
  ///
  /// These headers can be used for authentication or other purposes
  /// when fetching the video from a server.
  final Map<String, String>? httpHeaders;

  /// Optional video player options to customize playback behavior.
  ///
  /// Allows configuration of various aspects of the video playback,
  /// such as mixing with other audio sources.
  final VideoPlayerOptions? videoPlayerOptions;

  /// Creates a new [VideoModel] instance.
  ///
  /// [url] is required and must point to a valid video resource.
  /// [httpHeaders] and [videoPlayerOptions] are optional parameters
  /// to customize how the video is loaded and played.
  VideoModel({required this.url, this.httpHeaders, this.videoPlayerOptions});
}
