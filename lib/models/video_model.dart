import 'package:video_player/video_player.dart';

class VideoModel {
  /// The URL of the video
  final String url;

  /// Optional HTTP headers to use when opening the video
  final Map<String, String>? httpHeaders;

  /// Optional video player options
  final VideoPlayerOptions? videoPlayerOptions;

  /// Constructor for VideoModel
  VideoModel({required this.url, this.httpHeaders, this.videoPlayerOptions});
}
