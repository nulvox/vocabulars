import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../models/scenes_model.dart';
import '../models/vocabulary_model.dart';
import '../utils/app_constants.dart';
import '../utils/platform_utils.dart';
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
        // Scene image as background
        Positioned.fill(
          child: _buildSceneImage(scene.imagePath),
        ),
        
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
  
  /// Builds the scene image with appropriate loading based on platform
  Widget _buildSceneImage(String imagePath) {
    // The image path in the JSON already includes the filename,
    // but we need to ensure it's pointing to the right directory
    final fullPath = 'assets/images/$imagePath';
    
    print('Loading image from: $fullPath'); // Debug message
    
    // Try using Image with AssetImage instead of Image.asset for better error handling
    return Image(
      image: AssetImage(fullPath),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $error');
        print('Attempted path: $fullPath');
        
        // Fallback placeholder if image fails to load
        return Container(
          color: Colors.grey[300],
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Failed to load image: $fullPath',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}