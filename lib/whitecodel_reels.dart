import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'models/video_model.dart';
import 'whitecodel_reels_controller.dart';

class WhiteCodelReels extends GetView<WhiteCodelReelsController> {
  final BuildContext context;
  final List<VideoModel>? videoList;
  final Widget? loader;
  final bool isCaching;
  final int startIndex;
  final Widget Function(
    BuildContext context,
    int index,
    Widget child,
    VideoPlayerController videoPlayerController,
    PageController pageController,
  )?
  builder;

  const WhiteCodelReels({
    super.key,
    required this.context,
    this.videoList,
    this.loader,
    this.isCaching = false,
    this.builder,
    this.startIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    Get.delete<WhiteCodelReelsController>();
    Get.lazyPut<WhiteCodelReelsController>(
      () => WhiteCodelReelsController(
        reelsVideoList: videoList ?? [],
        isCaching: isCaching,
        startIndex: startIndex,
      ),
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(
        () => PageView.builder(
          controller: controller.pageController,
          itemCount: controller.pageCount.value,
          scrollDirection: Axis.vertical,
          itemBuilder: (context, index) {
            return buildTile(index);
          },
        ),
      ),
    );
  }

  VisibilityDetector buildTile(int index) {
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
          // controller.visible.value = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            // controller.visible.value = false;
          });
          controller.refreshView();
          controller.animationController.repeat();
          controller.initNearByVideos(index);
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
                )
              : builder!(
                  context,
                  index,
                  VideoFullScreenPage(
                    videoPlayerController:
                        controller.videoPlayerControllerList[index],
                  ),
                  controller.videoPlayerControllerList[index],
                  controller.pageController,
                );
        }),
      ),
    );
  }
}

class VideoFullScreenPage extends StatelessWidget {
  final VideoPlayerController videoPlayerController;

  const VideoFullScreenPage({super.key, required this.videoPlayerController});

  @override
  Widget build(BuildContext context) {
    WhiteCodelReelsController controller =
        Get.find<WhiteCodelReelsController>();
    return Stack(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width:
                  MediaQuery.of(context).size.height *
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
