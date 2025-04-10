import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../models/scenes_model.dart';
import '../models/vocabulary_model.dart';
import '../utils/app_constants.dart';
import '../utils/platform_utils.dart';
import '../utils/image_utils.dart';
import 'vocabulary_card.dart';

/// Widget that displays a scene with interactive points
class SceneView extends StatelessWidget {
  /// The scene to display
  final Scene scene;
  
  /// Current language code for translations
  final String currentLanguage;

  const SceneView({
    super.key,
    required this.scene,
    required this.currentLanguage,
  });

  @override
  Widget build(BuildContext context) {
    final vocabularyModel = Provider.of<VocabularyModel>(context);
    final activePoint = vocabularyModel.activeInteractionPoint;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Scene images (multiple layers)
        ..._buildSceneLayers(context, scene),
        
        // Overlay all interaction points on the scene
        ...scene.interactionPoints.map((point) => 
          _buildInteractionPoint(context, point, point.id == activePoint?.id)
        ),

        // Display vocabulary card for the active interaction point
        if (activePoint != null)
          Positioned(
            bottom: AppConstants.padding,
            left: 0,
            right: 0,
            child: Center(
              child: VocabularyCard(
                interactionPoint: activePoint,
                currentLanguage: currentLanguage,
                onClose: () => vocabularyModel.setActiveInteractionPoint(null),
              ),
            ),
          ),
      ],
    );
  }

  /// Builds an interaction point marker at the specified coordinates
  Widget _buildInteractionPoint(
    BuildContext context, 
    InteractionPoint point, 
    bool isActive
  ) {
    // Calculate position based on relative coordinates
    return Positioned(
      left: point.x * MediaQuery.of(context).size.width - 
          (AppConstants.interactionPointSize / 2),
      top: point.y * MediaQuery.of(context).size.height - 
          (AppConstants.interactionPointSize / 2),
      child: GestureDetector(
        onTap: () {
          final vocabularyModel = Provider.of<VocabularyModel>(
            context, 
            listen: false
          );
          
          // Toggle active state
          if (isActive) {
            vocabularyModel.setActiveInteractionPoint(null);
          } else {
            vocabularyModel.setActiveInteractionPoint(point);
          }
        },
        child: Container(
          width: AppConstants.interactionPointSize,
          height: AppConstants.interactionPointSize,
          decoration: BoxDecoration(
            color: Color(isActive 
                ? AppConstants.activeInteractionPointColor 
                : AppConstants.interactionPointColor
            ).withOpacity(0.7),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Tooltip(
            message: point.getTranslation(currentLanguage),
            child: Icon(
              Icons.touch_app,
              color: Colors.white,
              size: AppConstants.interactionPointSize * 0.6,
            ),
          ),
        ),
      ),
    );
  }
  
  /// Builds all image layers for a scene
  List<Widget> _buildSceneLayers(BuildContext context, Scene scene) {
    final layers = scene.getImageLayers();
    
    // Sort layers by zIndex if specified, otherwise use the list order
    final sortedLayers = [...layers]..sort((a, b) {
      // If both have zIndex, compare them
      if (a.zIndex != null && b.zIndex != null) {
        return a.zIndex!.compareTo(b.zIndex!);
      }
      // If only a has zIndex, it goes on top
      else if (a.zIndex != null) {
        return 1;
      }
      // If only b has zIndex, it goes on top
      else if (b.zIndex != null) {
        return -1;
      }
      // Otherwise maintain original order
      return 0;
    });
    
    try {
      return sortedLayers.map((layer) {
        if (kDebugMode) {
          print('Building layer: ${layer.id} with path: ${layer.imagePath}');
        }
        
        return Positioned.fill(
          child: Opacity(
            opacity: layer.opacity,
            child: Transform.scale(
              scale: layer.scale,
              child: FractionalTranslation(
                translation: Offset(layer.x, layer.y),
                child: _buildLayerImage(layer.imagePath),
              ),
            ),
          ),
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error building scene layers: $e');
      }
      // Return a fallback empty list in case of error
      return [
        Positioned.fill(
          child: Container(
            color: Colors.grey[200],
            child: const Center(
              child: Text('Error loading scene layers',
                style: TextStyle(color: Colors.grey)),
            ),
          ),
        )
      ];
    }
  }
  
  /// Builds a single image layer with appropriate format handling
  Widget _buildLayerImage(String imagePath) {
    // The image path in the JSON already includes the filename
    final fullPath = 'assets/images/$imagePath';
    
    if (kDebugMode) {
      print('Loading image from: $fullPath');
      print('Image extension: ${p.extension(imagePath).toLowerCase()}');
    }
    
    try {
      // Use ImageUtils to handle different image formats (SVG, PNG, JPG, WEBP, etc.)
      return ImageUtils.loadAssetImage(
        imagePath: imagePath,
        assetsDir: AppConstants.imageAssetsDir,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            print('Error loading image: $error');
            print('Attempted path: $fullPath');
          }
          
          // Fallback placeholder if image fails to load - simple gray background
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text('Unable to load image',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error building image: $e');
      }
      
      // Last resort fallback for any unexpected errors
      return Container(
        color: Colors.grey[100],
        child: const Center(
          child: Text('Image unavailable',
                 style: TextStyle(color: Colors.grey)),
        ),
      );
    }
  }
}