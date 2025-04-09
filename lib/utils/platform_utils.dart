import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
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

  /// Allows the user to pick a JSON file from their filesystem
  /// Returns the content of the selected file or null if canceled
  static Future<String?> pickJsonFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      
      if (result != null) {
        if (kIsWeb) {
          // Web platform - read bytes
          final bytes = result.files.single.bytes;
          if (bytes != null) {
            return utf8.decode(bytes);
          }
        } else {
          // Desktop/Mobile platform - read file path
          final path = result.files.single.path;
          if (path != null) {
            final file = File(path);
            return await file.readAsString();
          }
        }
      }
      return null; // User canceled the picker
    } catch (e) {
      print('Error picking JSON file: $e');
      return null;
    }
  }

  /// Allows the user to pick a folder containing vocabulary data
  /// Returns the selected directory path or null if canceled
  static Future<String?> pickDirectory() async {
    if (kIsWeb) {
      // Web doesn't support directory picking in the same way
      // Consider using a different approach for web
      return null;
    }
    
    try {
      String? directoryPath = await FilePicker.platform.getDirectoryPath();
      return directoryPath;
    } catch (e) {
      print('Error picking directory: $e');
      return null;
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