import 'package:flutter/material.dart';
import 'dart:async';

class ImagePreloader {
  static final ImagePreloader _instance = ImagePreloader._internal();
  static ImagePreloader get instance => _instance;

  ImagePreloader._internal();

  final Map<String, bool> _preloadedImages = {};
  bool _preloadingComplete = false;

  // List of all critical images - onboarding images removed
  final List<String> _criticalImages = [
    'assets/images/logo.png',
    'assets/images/browse_vehicle.png',
    'assets/images/request_vehicle.png',
    'assets/images/login_background.jpg',
    'assets/images/signup_background.jpg',
    'assets/images/main_sample.jpg',
    'assets/images/front_sample.jpg',
    'assets/images/rear_sample.jpg',
    'assets/images/side_sample.jpg',
    'assets/images/dashboard_sample.jpg',
    'assets/images/additional_sample.jpg',
  ];

  // Check if preloading has completed
  bool get isPreloadingComplete => _preloadingComplete;

  // Method to force preload completion (useful for timeouts)
  void forceCompletePreloading() {
    _preloadingComplete = true;
  }

  // Initialize image preloading
  Future<void> preloadImages(BuildContext context) async {
    if (_preloadingComplete) return;

    final Completer<void> completer = Completer<void>();
    int totalImages = _criticalImages.length;
    int loadedCount = 0;

    // Add a timeout to ensure we don't block navigation forever
    Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        debugPrint('Image preloading timed out - proceeding anyway');
        _preloadingComplete = true;
        completer.complete();
      }
    });

    try {
      await Future.wait(
        _criticalImages.map((String imagePath) {
          return _preloadSingleImage(imagePath, context).then((_) {
            loadedCount++;
            debugPrint(' Preloaded: $imagePath ($loadedCount/$totalImages)');
          });
        }),
      );

      _preloadingComplete = true;
      if (!completer.isCompleted) {
        completer.complete();
      }
    } catch (e) {
      debugPrint('⚠️ Error during preloading: $e');
      _preloadingComplete = true;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    return completer.future;
  }

  Future<void> _preloadSingleImage(String path, BuildContext context) async {
    if (_preloadedImages[path] == true) return;

    try {
      final completer = Completer<void>();
      final ImageProvider provider = AssetImage(path);

      final ImageStream stream = provider.resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener(
        (info, _) {
          _preloadedImages[path] = true;
          completer.complete();
        },
        onError: (exception, stackTrace) {
          debugPrint(' Failed to preload: $path - $exception');
          _preloadedImages[path] = false;
          completer.complete(); // Complete anyway to avoid hanging
        },
      );

      stream.addListener(listener);
      return completer.future;
    } catch (e) {
      debugPrint(' Error preloading: $path - $e');
      _preloadedImages[path] = false;
    }
  }
}
