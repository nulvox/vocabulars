import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:universal_platform/universal_platform.dart';

/// Utility class for handling platform-specific operations
class PlatformUtils {
  /// Checks if the app is running on web
  static bool get isWeb => kIsWeb;
  
  /// Checks if the app is running on desktop (Windows, macOS, Linux)
  static bool get isDesktop => 
      !kIsWeb && (UniversalPlatform.isWindows || 
                 UniversalPlatform.isMacOS || 
                 UniversalPlatform.isLinux);
  
  /// Checks if the app is running on mobile (Android, iOS)
  static bool get isMobile =>
      !kIsWeb && (UniversalPlatform.isAndroid || UniversalPlatform.isIOS);
  
  /// Checks if the app is running on Android
  static bool get isAndroid => !kIsWeb && UniversalPlatform.isAndroid;

  /// Checks if the app is running on Linux
  static bool get isLinux => !kIsWeb && UniversalPlatform.isLinux;

  /// Checks if audio playback is supported on this platform
  static bool get isAudioSupported {
    final supported = !isLinux;
    if (kDebugMode) {
      print('Audio support check: isLinux=$isLinux, isAudioSupported=$supported');
    }
    return supported; // Currently Linux doesn't support just_audio
  }

  /// Loads a file from the asset bundle (used for bundled assets)
  static Future<String> loadAssetFile(String path) async {
    return await rootBundle.loadString(path);
  }

  /// Loads a file from the filesystem (used for desktop platforms)
  static Future<String> loadFileFromFilesystem(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsString();
      } else {
        throw Exception('File not found: $path');
      }
    } catch (e) {
      throw Exception('Error reading file: $e');
    }
  }

  
  /// Creates platform-appropriate paths for assets
  static String getAssetPath(String basePath, String fileName) {
    if (isWeb) {
      // Web assets typically have a different path structure
      return 'assets/$basePath/$fileName';
    } else {
      // Mobile and desktop can use the standard asset path
      return '$basePath/$fileName';
    }
  }
  
  /// Gets the appropriate image asset path based on platform
  static String getImageAssetPath(String fileName) {
    return getAssetPath('images', fileName);
  }
  
  /// Gets the appropriate audio asset path based on platform
  static String getAudioAssetPath(String languageCode, String fileName) {
    return getAssetPath('audio/$languageCode', fileName);
  }
}