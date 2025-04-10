import 'package:json_annotation/json_annotation.dart';

part 'scenes_model.g.dart';

/// The main data class that contains all vocabulary information
@JsonSerializable()
class VocabularyData {
  /// Title of the vocabulary set
  final String title;
  
  /// Description of the vocabulary set
  final String description;
  
  /// List of language codes supported by this vocabulary set
  final List<String> supportedLanguages;
  
  /// List of all scenes in this vocabulary set
  final List<Scene> scenes;

  VocabularyData({
    required this.title,
    required this.description,
    required this.supportedLanguages,
    required this.scenes,
  });

  /// Create a VocabularyData instance from a JSON map
  factory VocabularyData.fromJson(Map<String, dynamic> json) => 
      _$VocabularyDataFromJson(json);

  /// Convert this VocabularyData instance to a JSON map
  Map<String, dynamic> toJson() => _$VocabularyDataToJson(this);
}

/// Represents a single scene with image layers and interaction points
@JsonSerializable()
class Scene {
  /// Unique identifier for the scene
  final String id;
  
  /// Display name of the scene
  final String name;
  
  /// Path to the background image file for this scene, relative to assets folder
  /// @deprecated - Use imageLayers instead
  final String? imagePath;
  
  /// List of image layers that compose this scene (back to front order)
  final List<ImageLayer>? imageLayers;
  
  /// List of interaction points in this scene
  final List<InteractionPoint> interactionPoints;

  Scene({
    required this.id,
    required this.name,
    this.imagePath,
    this.imageLayers,
    required this.interactionPoints,
  }) : assert(imagePath != null || (imageLayers != null && imageLayers.isNotEmpty),
             'Either imagePath or imageLayers must be provided');

  /// Create a Scene instance from a JSON map
  factory Scene.fromJson(Map<String, dynamic> json) => _$SceneFromJson(json);

  /// Convert this Scene instance to a JSON map
  Map<String, dynamic> toJson() => _$SceneToJson(this);
  
  /// Gets the image layers for rendering
  /// If imageLayers is provided, returns that
  /// If only imagePath is provided, creates a single layer from it
  List<ImageLayer> getImageLayers() {
    if (imageLayers != null && imageLayers!.isNotEmpty) {
      return imageLayers!;
    }
    // Fallback to legacy imagePath
    if (imagePath != null) {
      return [ImageLayer(
        id: 'background',
        imagePath: imagePath!,
        opacity: 1.0,
        x: 0.0,
        y: 0.0,
        scale: 1.0,
      )];
    }
    return [];
  }
}

/// Represents a single image layer in a scene
@JsonSerializable()
class ImageLayer {
  /// Unique identifier for the layer
  final String id;
  
  /// Path to the image file, relative to assets folder
  final String imagePath;
  
  /// Opacity of the layer (0.0 to 1.0)
  final double opacity;
  
  /// X-coordinate of the layer (0.0 is left, relative to scene width)
  final double x;
  
  /// Y-coordinate of the layer (0.0 is top, relative to scene height)
  final double y;
  
  /// Scale factor of the layer (1.0 is original size)
  final double scale;
  
  /// Z-index for manual ordering override (higher numbers show on top)
  final int? zIndex;

  ImageLayer({
    required this.id,
    required this.imagePath,
    this.opacity = 1.0,
    this.x = 0.0,
    this.y = 0.0,
    this.scale = 1.0,
    this.zIndex,
  });

  /// Create an ImageLayer instance from a JSON map
  factory ImageLayer.fromJson(Map<String, dynamic> json) =>
      _$ImageLayerFromJson(json);

  /// Convert this ImageLayer instance to a JSON map
  Map<String, dynamic> toJson() => _$ImageLayerToJson(this);
}

/// Represents a point of interaction within a scene
@JsonSerializable()
class InteractionPoint {
  /// Unique identifier for the interaction point
  final String id;
  
  /// Primary label for the interaction point
  final String label;
  
  /// X-coordinate of the interaction point (0.0 to 1.0, relative to image width)
  final double x;
  
  /// Y-coordinate of the interaction point (0.0 to 1.0, relative to image height)
  final double y;
  
  /// Audio files for pronunciation in different languages
  final List<AudioFile> audioFiles;
  
  /// Translations of the label in different languages
  final List<Translation> translations;

  InteractionPoint({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.audioFiles,
    required this.translations,
  });

  /// Create an InteractionPoint instance from a JSON map
  factory InteractionPoint.fromJson(Map<String, dynamic> json) => 
      _$InteractionPointFromJson(json);

  /// Convert this InteractionPoint instance to a JSON map
  Map<String, dynamic> toJson() => _$InteractionPointToJson(this);

  /// Get translation for a specific language
  String getTranslation(String languageCode) {
    final translation = translations.firstWhere(
      (t) => t.languageCode == languageCode,
      orElse: () => Translation(languageCode: languageCode, text: label),
    );
    return translation.text;
  }

  /// Get audio file for a specific language
  AudioFile? getAudioForLanguage(String languageCode) {
    try {
      return audioFiles.firstWhere((a) => a.languageCode == languageCode);
    } catch (e) {
      return audioFiles.isNotEmpty ? audioFiles.first : null;
    }
  }
}

/// Represents an audio file for word pronunciation
@JsonSerializable()
class AudioFile {
  /// Language code this audio is for (e.g., "en", "es")
  final String languageCode;
  
  /// Path to the audio file, relative to the assets folder
  final String filePath;

  AudioFile({
    required this.languageCode,
    required this.filePath,
  });

  /// Create an AudioFile instance from a JSON map
  factory AudioFile.fromJson(Map<String, dynamic> json) => 
      _$AudioFileFromJson(json);

  /// Convert this AudioFile instance to a JSON map
  Map<String, dynamic> toJson() => _$AudioFileToJson(this);
}

/// Represents a translation of a label
@JsonSerializable()
class Translation {
  /// Language code this translation is for (e.g., "en", "es")
  final String languageCode;
  
  /// Translated text
  final String text;

  Translation({
    required this.languageCode,
    required this.text,
  });

  /// Create a Translation instance from a JSON map
  factory Translation.fromJson(Map<String, dynamic> json) => 
      _$TranslationFromJson(json);

  /// Convert this Translation instance to a JSON map
  Map<String, dynamic> toJson() => _$TranslationToJson(this);
}