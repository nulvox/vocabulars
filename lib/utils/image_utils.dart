import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Utility class for handling different image types and formats
class ImageUtils {
  /// Supported raster image extensions
  static const List<String> _rasterExtensions = [
    '.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'
  ];
  
  /// Supported vector image extensions
  static const List<String> _vectorExtensions = ['.svg'];
  
  /// All supported image extensions
  static List<String> get supportedExtensions => 
      [..._rasterExtensions, ..._vectorExtensions];
  
  /// Check if a file is a supported raster image
  static bool isRasterImage(String path) {
    final extension = p.extension(path).toLowerCase();
    return _rasterExtensions.contains(extension);
  }
  
  /// Check if a file is a supported vector image
  static bool isVectorImage(String path) {
    final extension = p.extension(path).toLowerCase();
    return _vectorExtensions.contains(extension);
  }
  
  /// Check if a file is a supported image
  static bool isSupportedImage(String path) {
    return isRasterImage(path) || isVectorImage(path);
  }
  
  /// Build the appropriate image widget based on the file extension
  static Widget buildImage({
    required String assetPath,
    required BoxFit fit,
    double? width,
    double? height,
    Color? color,
    BlendMode colorBlendMode = BlendMode.srcIn,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    if (kDebugMode) {
      print('Building image from path: $assetPath');
    }
    
    try {
      if (isVectorImage(assetPath)) {
        // Add placeholder for SVG while it loads
        return SvgPicture.asset(
          assetPath,
          fit: fit,
          width: width,
          height: height,
          colorFilter: color != null ? ColorFilter.mode(color, colorBlendMode) : null,
          placeholderBuilder: (BuildContext context) => Container(
            color: Colors.grey[100],
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            ),
          ),
        );
      } else {
        return Image.asset(
          assetPath,
          fit: fit,
          width: width,
          height: height,
          color: color,
          colorBlendMode: colorBlendMode,
          errorBuilder: errorBuilder ?? _defaultErrorBuilder,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error building image from path $assetPath: $e');
      }
      
      // For any unexpected errors, return a fallback widget
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image, color: Colors.grey),
              if (kDebugMode) Text('Error: $e',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      );
    }
  }
  
  /// Default error builder for image loading failures
  static Widget _defaultErrorBuilder(
    BuildContext context, Object error, StackTrace? stackTrace
  ) {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text('Failed to load image',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF616161))), // Using exact grey700 color value
            if (kDebugMode)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// Load image from assets with full path handling
  static Widget loadAssetImage({
    required String imagePath,
    required String assetsDir,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Color? color,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    // Handle different path formats
    final fullPath = imagePath.startsWith(assetsDir)
        ? imagePath
        : '$assetsDir$imagePath';
    
    if (kDebugMode) {
      print('Loading asset image from path: $fullPath');
      print('Image is vector: ${isVectorImage(fullPath)}');
      print('Image is raster: ${isRasterImage(fullPath)}');
      print('Image is supported: ${isSupportedImage(fullPath)}');
    }
        
    return buildImage(
      assetPath: fullPath,
      fit: fit,
      width: width,
      height: height,
      color: color,
      errorBuilder: errorBuilder,
    );
  }
}