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

/// Represents a single scene with an image and interaction points
@JsonSerializable()
class Scene {
  /// Unique identifier for the scene
  final String id;
  
  /// Display name of the scene
  final String name;
  
  /// Path to the image file for this scene, relative to assets folder
  final String imagePath;
  
  /// List of interaction points in this scene
  final List<InteractionPoint> interactionPoints;

  Scene({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.interactionPoints,
  });

  /// Create a Scene instance from a JSON map
  factory Scene.fromJson(Map<String, dynamic> json) => _$SceneFromJson(json);

  /// Convert this Scene instance to a JSON map
  Map<String, dynamic> toJson() => _$SceneToJson(this);
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