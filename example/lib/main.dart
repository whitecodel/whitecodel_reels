import 'package:flutter/material.dart';
import 'package:whitecodel_reels/models/video_model.dart';
import 'package:whitecodel_reels/whitecodel_reels.dart';

void main() async {
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
          body: WhiteCodelReels(
              key: UniqueKey(),
              context: context,
              loader: const Center(
                child: CircularProgressIndicator(),
              ),
              videoList: List.generate(
                10,
                (index) => VideoModel(
                    url:
                        'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4'),
              ),
              isCaching: true,
              builder: (context, index, child, videoPlayerController,
                  pageController) {
                // Widget builder logic
                return Container();
              }),
        ));
  }
}
