# WhiteCodel Reels

## Introduction

This package allows you to implement Instagram-like reels widgets in your Flutter application with minimal code. With `whitecodel_reels`, you can quickly add a reels widget featuring video content with interactive elements.

## Features

- **Caching**: The reels widget caches the video content to improve performance and reduce data usage.
- **Customizable**: You can customize the reels widget with your own design and layout.
- **Interactive**: You can add interactive elements to the reels widget.
- **Easy to use**: You can easily integrate the reels widget in your Flutter application with minimal code.
- **Multiscreen Support**: Use the `controllerTag` parameter to create multiple independent reels widgets on different screens or pages.

## Installation

To use this package, add `whitecodel_reels` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
  whitecodel_reels: ^0.0.9+4
```

## Android Configuration

For caching to work properly on Android, you need to add the following permissions to your `AndroidManifest.xml` file:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Also, ensure your application has the following configuration set:

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...
    >
```

And create a network security configuration file at `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
  <base-config cleartextTrafficPermitted="true">
    <trust-anchors>
      <certificates src="system" />
    </trust-anchors>
  </base-config>

  <domain-config cleartextTrafficPermitted="true">
    <domain includeSubdomains="true">localhost</domain>
    <domain includeSubdomains="true">127.0.0.1</domain>
  </domain-config>
</network-security-config>
```

## Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:whitecodel_reels/models/video_model.dart';
import 'package:whitecodel_reels/whitecodel_reels.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
              controllerTag: "home_reels", // Use a unique tag for each screen
              builder: (context, index, child, videoPlayerController,
                  pageController) {
                // Widget builder logic
                return child;
              }),
        ));
  }
}
```

## Multiscreen Support

You can use multiple `WhiteCodelReels` widgets on different screens or pages by providing a unique `controllerTag` for each instance. This ensures each reels widget maintains its own state and playback independently.

```dart
// Example: Using different controllerTag for different screens
WhiteCodelReels(
  controllerTag: "home_reels",
  // ...other params...
);

WhiteCodelReels(
  controllerTag: "profile_reels",
  // ...other params...
);
```

## Future Plans

- **Customizable**: Add more customization options to the reels widget.
- **Speed Optimization**: Improve the performance of the reels widget by optimizing the video loading speed.

## AUTHOR

[Bhawani Shankar](https://medium.com/@BhawaniTechDev)
