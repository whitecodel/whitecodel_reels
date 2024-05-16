# WhiteCodel Reels

## Introduction
This package allows you to implement Instagram-like reels widgets in your Flutter application with minimal code. With `whitecodel_reels`, you can quickly add a reels widget featuring video content with interactive elements.

## Features
- **Caching**: The reels widget caches the video content to improve performance and reduce data usage.
- **Customizable**: You can customize the reels widget with your own design and layout.
- **Interactive**: You can add interactive elements to the reels widget.
- **Easy to use**: You can easily integrate the reels widget in your Flutter application with minimal code.

## Installation
To use this package, add `whitecodel_reels` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  whitecodel_reels: ^version_number
```

## Usage Example
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                (index) =>
                    'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
              ),
              builder: (context, index, child) {
                // Widget builder logic
              }),
        ));
  }
}
```

## Future Plans
- **Customizable**: Add more customization options to the reels widget.
- **Caching**: Improve the caching mechanism to reduce data usage and improve performance.
- **Speed Optimization**: Improve the performance of the reels widget by optimizing the video loading speed.

## AUTHOR
This package is created by [Bhawani Shankar](https://medium.com/@BhawaniTechDev).