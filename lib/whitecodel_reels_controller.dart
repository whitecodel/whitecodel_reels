import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'models/video_model.dart';
import 'video_controller_service.dart';

// Controller class for managing the reels in the app
class WhiteCodelReelsController extends GetxController
    with GetTickerProviderStateMixin, WidgetsBindingObserver {
  // Page controller for managing pages of videos
  PageController pageController = PageController(viewportFraction: 0.99999);

  // List of video player controllers
  RxList<VideoPlayerController> videoPlayerControllerList =
      <VideoPlayerController>[].obs;

  // Service for managing cached video controllers
  CachedVideoControllerService videoControllerService =
      CachedVideoControllerService(DefaultCacheManager());

  // Observable for loading state
  final loading = true.obs;

  // Observable for visibility state
  final visible = false.obs;

  // Animation controller for animating
  late AnimationController animationController;

  // Animation object
  late Animation animation;

  // Current page index
  int page = 1;

  // Limit for loading videos
  int limit = 10;

  // List of video models
  final List<VideoModel> reelsVideoList;

  // isCaching
  bool isCaching;

  // Observable list of video models
  RxList<VideoModel> videoList = <VideoModel>[].obs;

  // Limit for loading nearby videos
  int loadLimit = 4;

  // Flag for initialization
  bool init = false;

  // Timer for periodic tasks
  Timer? timer;

  // Index of the last video
  int? lastIndex;

  // Already listened list
  List<int> alreadyListened = [];

  // Caching video at index
  List<String> caching = [];

  // pageCount
  RxInt pageCount = 0.obs;

  final int startIndex;

  // Constructor
  WhiteCodelReelsController({
    required this.reelsVideoList,
    required this.isCaching,
    this.startIndex = 0,
  });

  // Lifecycle method for handling app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // Pause all video players when the app is paused
      for (var i = 0; i < videoPlayerControllerList.length; i++) {
        videoPlayerControllerList[i].pause();
      }
    }
  }

  // Lifecycle method called when the controller is initialized
  @override
  void onInit() {
    super.onInit();
    initialLog();
    videoList.addAll(reelsVideoList);
    // Initialize animation controller
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeIn,
    );
    // Initialize service and start timer
    initService(startIndex: startIndex);
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (lastIndex != null) {
        initNearByVideos(lastIndex!);
      }
    });
  }

  // Lifecycle method called when the controller is closed
  @override
  void onClose() {
    animationController.dispose();
    // Pause and dispose all video players
    for (var i = 0; i < videoPlayerControllerList.length; i++) {
      videoPlayerControllerList[i].pause();
      videoPlayerControllerList[i].dispose();
    }
    timer?.cancel();
    super.onClose();
  }

  // Initialize video service and load videos
  Future<void> initService({int startIndex = 0}) async {
    await addVideosController();
    int myindex = startIndex;

    try {
      if (!videoPlayerControllerList[myindex].value.isInitialized) {
        cacheVideo(myindex);
        await videoPlayerControllerList[myindex].initialize();
        increasePage(myindex + 1);
      }
    } catch (e) {
      log('Error initializing video at index $myindex: $e');
    }

    animationController.repeat();
    videoPlayerControllerList[myindex].play();
    refreshView();
    // listenEvents(myindex);
    await initNearByVideos(myindex);
    loading.value = false;

    Future.delayed(Duration.zero, () {
      pageController.jumpToPage(myindex);
    });
  }

  void initialLog() {
    debugPrint('''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✨ Thank You for using WhiteCodel Reels! ✨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔍 **Found a bug?**  
Report issues here:  
👉 https://github.com/whitecodel/whitecodel_reels/issues

🔧 **Want to contribute?**  
Submit a pull request:  
👉 https://github.com/whitecodel/whitecodel_reels

💡 **Learn more about WhiteCodel Reels:**  
Medium article:  
👉 https://medium.com/whitecodel/how-to-implement-instagram-like-reels-in-your-flutter-app-2d4f53d3f899

👨‍💻 **Crafted with ❤️ by Bhawani Shankar**

📬 **Connect with me:**  
LinkedIn:   https://www.linkedin.com/in/bhawanitechdev/  
Twitter:    https://twitter.com/bhawanitechdev  
Instagram:  https://www.instagram.com/bhawani_tech_dev
GitHub:     https://github.com/whitecodel  
Medium:     https://medium.com/@BhawaniTechDev

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
  }

  // Refresh loading state
  void refreshView() {
    loading.value = true;
    loading.value = false;
  }

  // Add video controllers
  Future<void> addVideosController() async {
    for (var i = 0; i < videoList.length; i++) {
      VideoModel videoModel = videoList[i];
      final controller = await videoControllerService.getControllerForVideo(
        videoModel,
        isCaching,
      );
      videoPlayerControllerList.add(controller);
    }
  }

  // Initialize nearby videos
  Future<void> initNearByVideos(int index) async {
    if (init) {
      lastIndex = index;
      return;
    }
    lastIndex = null;
    init = true;
    if (loading.value) return;
    disposeNearByOldVideoControllers(index);
    await tryInit(index);
    try {
      var currentPage = index;
      var maxPage = currentPage + loadLimit;
      List<VideoModel> videoFiles = videoList;

      for (var i = currentPage; i < maxPage; i++) {
        if (videoFiles.asMap().containsKey(i)) {
          var controller = videoPlayerControllerList[i];
          if (!controller.value.isInitialized) {
            cacheVideo(i);
            await controller.initialize();
            increasePage(i + 1);
            refreshView();
            // listenEvents(i);
          }
        }
      }
      for (var i = index - 1; i > index - loadLimit; i--) {
        if (videoList.asMap().containsKey(i)) {
          var controller = videoPlayerControllerList[i];
          if (!controller.value.isInitialized) {
            if (!caching.contains(videoList[index].url)) {
              cacheVideo(index);
            }

            await controller.initialize();
            increasePage(i + 1);
            refreshView();
            // listenEvents(i);
          }
        }
      }

      refreshView();
      loading.value = false;
    } catch (e) {
      loading.value = false;
    } finally {
      loading.value = false;
    }
    init = false;
  }

  // Try initializing video at index
  Future<void> tryInit(int index) async {
    var oldVideoPlayerController = videoPlayerControllerList[index];
    if (oldVideoPlayerController.value.isInitialized) {
      oldVideoPlayerController.play();
      refresh();
      return;
    }
    VideoPlayerController videoPlayerControllerTmp =
        await videoControllerService.getControllerForVideo(
          videoList[index],
          isCaching,
        );
    videoPlayerControllerList[index] = videoPlayerControllerTmp;
    await oldVideoPlayerController.dispose();
    refreshView();
    if (!caching.contains(videoList[index].url)) {
      cacheVideo(index);
    }
    await videoPlayerControllerTmp.initialize().catchError((e) {}).then((
      value,
    ) {
      videoPlayerControllerTmp.play();
      refresh();
    });
  }

  // Dispose nearby old video controllers
  Future<void> disposeNearByOldVideoControllers(int index) async {
    loading.value = false;
    for (var i = index - loadLimit; i > 0; i--) {
      if (videoPlayerControllerList.asMap().containsKey(i)) {
        var oldVideoPlayerController = videoPlayerControllerList[i];
        VideoPlayerController videoPlayerControllerTmp =
            await videoControllerService.getControllerForVideo(
              videoList[i],
              isCaching,
            );
        videoPlayerControllerList[i] = videoPlayerControllerTmp;
        alreadyListened.remove(i);
        await oldVideoPlayerController.dispose();
        refreshView();
      }
    }

    for (var i = index + loadLimit; i < videoPlayerControllerList.length; i++) {
      if (videoPlayerControllerList.asMap().containsKey(i)) {
        var oldVideoPlayerController = videoPlayerControllerList[i];
        VideoPlayerController videoPlayerControllerTmp =
            await videoControllerService.getControllerForVideo(
              videoList[i],
              isCaching,
            );
        videoPlayerControllerList[i] = videoPlayerControllerTmp;
        alreadyListened.remove(i);
        await oldVideoPlayerController.dispose();
        refreshView();
      }
    }
  }

  // Listen to video events
  void listenEvents(int i, {bool force = false}) {
    if (alreadyListened.contains(i) && !force) return;
    alreadyListened.add(i);
    var videoPlayerController = videoPlayerControllerList[i];

    videoPlayerController.addListener(() {
      if (videoPlayerController.value.position ==
              videoPlayerController.value.duration &&
          videoPlayerController.value.duration != Duration.zero) {
        videoPlayerController.seekTo(Duration.zero);
        videoPlayerController.play();
      }
    });
  }

  // Listen to page events
  // pageEventsListen(path) {
  //   pageController.addListener(() {
  //     visible.value = false;
  //     Future.delayed(const Duration(milliseconds: 500), () {
  //       loading.value = false;
  //     });
  //     refreshView();
  //   });
  // }

  Future<void> cacheVideo(int index) async {
    if (!isCaching) return;
    String url = videoList[index].url;
    if (caching.contains(url)) return;
    caching.add(url);

    // No need for explicit caching here anymore
    // The proxy server handles caching while streaming

    // Just mark this URL as being handled
    log('Video being cached through proxy: $index');
  }

  void increasePage(int v) {
    if (pageCount.value == videoList.length) return;
    if (pageCount.value >= v) return;
    pageCount.value = v;
  }
}
