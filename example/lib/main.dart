// ignore_for_file: dead_code

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:whitecodel_reels/models/video_model.dart';
import 'package:whitecodel_reels/whitecodel_reels.dart';

List<String> videos = [
  "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_1mb.mp4",
  "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_2mb.mp4",
  "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_5mb.mp4",
  "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_10mb.mp4",
  "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_20mb.mp4",
  "https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_30mb.mp4",
  "https://sample-videos.com/video321/mp4/480/big_buck_bunny_480p_1mb.mp4",
  "https://sample-videos.com/video321/mp4/480/big_buck_bunny_480p_2mb.mp4",
  "https://sample-videos.com/video321/mp4/480/big_buck_bunny_480p_5mb.mp4",
  "https://sample-videos.com/video321/mp4/480/big_buck_bunny_480p_10mb.mp4",
  "https://sample-videos.com/video321/mp4/480/big_buck_bunny_480p_20mb.mp4",
  "https://sample-videos.com/video321/mp4/480/big_buck_bunny_480p_30mb.mp4",
  "https://sample-videos.com/video321/mp4/360/big_buck_bunny_360p_1mb.mp4",
  "https://sample-videos.com/video321/mp4/360/big_buck_bunny_360p_2mb.mp4",
  "https://sample-videos.com/video321/mp4/360/big_buck_bunny_360p_5mb.mp4",
  "https://sample-videos.com/video321/mp4/360/big_buck_bunny_360p_10mb.mp4",
  "https://sample-videos.com/video321/mp4/360/big_buck_bunny_360p_20mb.mp4",
  "https://sample-videos.com/video321/mp4/360/big_buck_bunny_360p_30mb.mp4",
  "https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_1mb.mp4",
  "https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_2mb.mp4",
  "https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_5mb.mp4",
  "https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_10mb.mp4",
  "https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_20mb.mp4",
  "https://sample-videos.com/video321/mp4/240/big_buck_bunny_240p_30mb.mp4"
];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.delayed(const Duration(seconds: 1));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'WhiteCodel Reels',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: WhiteCodelReels(
                    key: UniqueKey(),
                    context: context,
                    loader: const Center(
                      child: CircularProgressIndicator(),
                    ),
                    isCaching: true,
                    videoList: List.generate(videos.length,
                        (index) => VideoModel(url: videos[index])),
                    builder: (context, index, child, videoPlayerController,
                        pageController) {
                      bool isReadMore = false;
                      StreamController<double> videoProgressController =
                          StreamController<double>();

                      videoPlayerController.addListener(() {
                        double videoProgress = videoPlayerController
                                .value.position.inMilliseconds /
                            videoPlayerController.value.duration.inMilliseconds;
                        videoProgressController.add(videoProgress);
                      });

                      return Stack(
                        children: [
                          child,
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatefulBuilder(
                                  builder: (context, setState) {
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isReadMore = !isReadMore;
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.black
                                                  .withValues(alpha: 0.0),
                                              Colors.black
                                                  .withValues(alpha: 0.2),
                                              Colors.black
                                                  .withValues(alpha: 0.5),
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              constraints: const BoxConstraints(
                                                maxHeight: 300,
                                              ),
                                              child: SingleChildScrollView(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 50, left: 10),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                                                      maxLines:
                                                          isReadMore ? 100 : 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: GoogleFonts.roboto(
                                                        color: Colors.white,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 50, left: 10),
                                              child: Visibility(
                                                visible: true,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    children: [
                                                      Visibility(
                                                        visible: true,
                                                        child: InkWell(
                                                          onTap: () {},
                                                          child: RichText(
                                                            text: TextSpan(
                                                              children: [
                                                                const TextSpan(
                                                                  text: '1000',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .white70,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                TextSpan(
                                                                  text:
                                                                      " Likes",
                                                                  style:
                                                                      GoogleFonts
                                                                          .roboto(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 30,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 70,
                            right: 10,
                            child: SizedBox(
                              height: 450,
                              // color: Colors.red.withOpacity(0.5),
                              child: Column(
                                children: [
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () {},
                                        icon: const Icon(
                                          true
                                              ? Icons.thumb_up_alt
                                              : Icons.thumb_up_alt_outlined,
                                          color: Color.fromARGB(
                                            255,
                                            214,
                                            183,
                                            8,
                                          ),
                                        ),
                                        color: Colors.white,
                                      ),
                                      InkWell(
                                        onTap: () {},
                                        child: Text(
                                          '10K',
                                          style: GoogleFonts.roboto(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () {},
                                        icon: const Icon(
                                          false
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: Colors.red,
                                        ),
                                        color: Colors.white,
                                      ),
                                      InkWell(
                                        onTap: () {},
                                        child: Text(
                                          '10K',
                                          style: GoogleFonts.roboto(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.comment,
                                          color: Colors.white,
                                        ),
                                        color: Colors.white,
                                      ),
                                      InkWell(
                                        child: Text(
                                          '10K',
                                          style: GoogleFonts.roboto(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.share,
                                          color: Colors.white,
                                        ),
                                        color: Colors.white,
                                      ),
                                      Text(
                                        'Share',
                                        style: GoogleFonts.roboto(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        onPressed: () {},
                                        icon: const Icon(
                                          false
                                              ? Icons.bookmark
                                              : Icons.bookmark_border,
                                          color: Colors.white,
                                        ),
                                        color: Colors.white,
                                      ),
                                      Text(
                                        'Save',
                                        style: GoogleFonts.roboto(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          StreamBuilder(
                            stream: videoProgressController.stream,
                            builder: (context, snapshot) {
                              return Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    thumbShape: SliderComponentShape.noThumb,
                                    overlayShape:
                                        SliderComponentShape.noOverlay,
                                    trackHeight: 2,
                                  ),
                                  child: Slider(
                                    value: (snapshot.data ?? 0).clamp(0.0, 1.0),
                                    min: 0.0,
                                    max: 1.0,
                                    activeColor: Colors.red,
                                    inactiveColor: Colors.white,

                                    onChanged: (value) {
                                      final position = videoPlayerController
                                              .value.duration.inMilliseconds *
                                          value;
                                      videoPlayerController.seekTo(Duration(
                                          milliseconds: position.toInt()));
                                    },
                                    // onChangeEnd: (value) {
                                    //   videoPlayerController.play();
                                    // },
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }),
              ),
              Container(
                color: Colors.black,
                padding: EdgeInsets.only(
                  top: 10,
                  bottom: Platform.isIOS ? 20 : 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.home,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.add_box,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.account_box,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}
