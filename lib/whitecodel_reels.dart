import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'models/video_model.dart';
import 'whitecodel_reels_controller.dart';

/// A widget that displays a scrollable list of video reels.
///
/// This widget uses [GetX] for state management and provides a TikTok-like
/// experience with vertical scrolling between videos.
class WhiteCodelReels extends StatelessWidget {
  /// The build context of the widget.
  final BuildContext context;

  /// List of video models to be displayed in the reels.
  final List<VideoModel>? videoList;

  /// Widget to be displayed while the video is loading.
  final Widget? loader;

  /// Whether to cache videos for faster future playback.
  final bool isCaching;

  /// The initial index to start playing videos from.
  final int startIndex;

  /// The tag of the controller to be used.
  final String? controllerTag;

  /// An optional builder function to customize the appearance of each video item.
  ///
  /// If provided, this function will be called for each video item, allowing
  /// custom UI to be built around the video player.
  final Widget Function(
    BuildContext context,
    int index,
    Widget child,
    VideoPlayerController videoPlayerController,
    PageController pageController,
  )? builder;

  /// Creates a new [WhiteCodelReels] widget.
  ///
  /// [context] is required to build the widget tree.
  /// [videoList] contains the list of videos to display.
  /// [loader] is an optional custom loading indicator.
  /// [isCaching] determines whether videos should be cached.
  /// [builder] is an optional function to customize video item appearance.
  /// [startIndex] is the initial video index to display (defaults to 0).
  const WhiteCodelReels({
    Key? key,
    required this.context,
    this.videoList,
    this.loader,
    this.isCaching = false,
    this.builder,
    this.startIndex = 0,
    this.controllerTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tag = controllerTag ?? 'reels_controller';

    if (!Get.isRegistered<WhiteCodelReelsController>(tag: tag)) {
      Get.lazyPut(
        () => WhiteCodelReelsController(
          reelsVideoList: videoList ?? [],
          isCaching: isCaching,
          startIndex: startIndex,
        ),
        tag: tag,
      );
    }

    final controller = Get.find<WhiteCodelReelsController>(tag: tag);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        return PageView.builder(
          controller: controller.pageController,
          itemCount: controller.pageCount.value,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
            return buildTile(index, controller);
          },
        );
      }),
    );
  }

  /// Builds a video tile with visibility detection.
  ///
  /// This method creates a visibility detector that manages video playback
  /// based on whether the video is currently visible to the user.
  VisibilityDetector buildTile(
      int index, WhiteCodelReelsController controller) {
    return VisibilityDetector(
      key: Key(index.toString()),
      onVisibilityChanged: (visibilityInfo) {
        if (visibilityInfo.visibleFraction < 0.5) {
          controller.videoPlayerControllerList[index].seekTo(Duration.zero);
          controller.videoPlayerControllerList[index].pause();
          controller.refreshView();
          controller.animationController.stop();
        } else {
          controller.listenEvents(index);
          controller.videoPlayerControllerList[index].play();
          controller.refreshView();
          controller.animationController.repeat();
          controller.initNearByVideos(index);

          // The proxy server handles caching automatically
          // We just need to mark this URL for tracking purposes
          if (!controller.caching.contains(controller.videoList[index].url)) {
            controller.cacheVideo(index);
          }

          controller.visible.value = false;
        }
      },
      child: GestureDetector(
        onTap: () {
          if (controller.videoPlayerControllerList[index].value.isPlaying) {
            controller.videoPlayerControllerList[index].pause();
            controller.visible.value = true;
            controller.refreshView();
            controller.animationController.stop();
          } else {
            controller.videoPlayerControllerList[index].play();
            controller.visible.value = true;
            Future.delayed(const Duration(milliseconds: 500), () {
              controller.visible.value = false;
            });

            controller.refreshView();
            controller.animationController.repeat();
          }
        },
        child: Obx(() {
          if (controller.loading.value ||
              !controller
                  .videoPlayerControllerList[index]
                  .value
                  .isInitialized) {
            return loader ??
                const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                );
          }

          return builder == null
              ? VideoFullScreenPage(
                  videoPlayerController:
                      controller.videoPlayerControllerList[index],
                  controllerTag: controllerTag ?? "reels_controller",
                )
              : builder!(
                  context,
                  index,
                  VideoFullScreenPage(
                    videoPlayerController:
                        controller.videoPlayerControllerList[index],
                    controllerTag: controllerTag ?? "reels_controller",
                  ),
                  controller.videoPlayerControllerList[index],
                  controller.pageController,
                );
        }),
      ),
    );
  }
}

/// A widget that displays a full-screen video with play/pause controls.
///
/// This widget takes a [VideoPlayerController] and displays the video
/// with a centered play/pause button that appears when the user
/// interacts with the video.
class VideoFullScreenPage extends StatelessWidget {
  /// The controller for the video being displayed.
  final VideoPlayerController videoPlayerController;
  final String? controllerTag;

  /// Creates a new [VideoFullScreenPage] widget.
  ///
  /// [videoPlayerController] is required and must be initialized before use.
  const VideoFullScreenPage(
      {super.key,
      required this.videoPlayerController,
      required this.controllerTag});

  @override
  Widget build(BuildContext context) {
    WhiteCodelReelsController controller = Get.find<WhiteCodelReelsController>(
        tag: controllerTag ?? "reels_controller");

    return Stack(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: MediaQuery.of(context).size.height *
                  videoPlayerController.value.aspectRatio,
              height: MediaQuery.of(context).size.height,
              child: VideoPlayer(videoPlayerController),
            ),
          ),
        ),
        Positioned(
          child: Center(
            child: Obx(
              () => Opacity(
                opacity: .5,
                child: AnimatedOpacity(
                  opacity: controller.visible.value ? 1 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    alignment: Alignment.center,
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.black38,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 1),
                      ),
                    ),
                    child: videoPlayerController.value.isPlaying
                        ? const Icon(Icons.pause, color: Colors.white, size: 40)
                        : const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 40,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
