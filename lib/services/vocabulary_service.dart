import 'dart:convert';
import 'dart:math';
import '../models/scenes_model.dart';
import '../utils/app_constants.dart';
import '../utils/platform_utils.dart';

/// Service responsible for loading and parsing vocabulary data
class VocabularyService {
  /// The parsed vocabulary data
  late VocabularyData vocabularyData;

  /// Error from the most recent initialization attempt, if any.
  String? _errorMessage;

  String? get errorMessage => _errorMessage;
  
  /// Path to the vocabulary JSON file
  final String _jsonPath;
  
  /// Flag indicating if the data is loaded from an external source
  bool _isExternalData = false;
  
  /// Path to the external directory containing vocabulary data
  String? _externalDirectoryPath;
  
  /// Flag indicating whether the vocabulary set is multilingual
  bool get isExternalData => _isExternalData;
  
  /// Get the external directory path if available
  String? get externalDirectoryPath => _externalDirectoryPath;
  
  /// Constructor that accepts an optional JSON file path
  VocabularyService({String? jsonPath}) 
      : _jsonPath = jsonPath ?? AppConstants.defaultVocabularyPath;

  /// Initialize the service by loading vocabulary data
  Future<void> initialize() async {
    _errorMessage = null;
    try {
      print('Initializing vocabulary service from $_jsonPath');
      String jsonString;
      
      // Load the JSON file based on platform
      if (PlatformUtils.isWeb) {
        // For web, always load from assets
        jsonString = await PlatformUtils.loadAssetFile(_jsonPath);
      } else if (_isExternalData && _externalDirectoryPath != null) {
        // For external data on desktop or mobile
        final jsonFilePath = '$_externalDirectoryPath/vocabulary.json';
        print('Loading external data from: $jsonFilePath');
        if (PlatformUtils.isDesktop || PlatformUtils.isAndroid) {
          print('Using filesystem loading method');
          jsonString = await PlatformUtils.loadFileFromFilesystem(jsonFilePath);
        } else {
          // Fallback to assets for other platforms
          jsonString = await PlatformUtils.loadAssetFile(_jsonPath);
        }
      } else {
        // Default: load from bundled assets
        print('Loading bundled asset from: $_jsonPath');
        jsonString = await PlatformUtils.loadAssetFile(_jsonPath);
        print('Asset content length: ${jsonString.length}');
        print('First 100 chars: ${jsonString.substring(0, min(100, jsonString.length))}');
      }
      
      print('Loading vocabulary data from: $_jsonPath');
      
      // Debug the raw JSON content
      print('Raw JSON content (first 200 chars): ${jsonString.substring(0, min(200, jsonString.length))}');
      
      vocabularyData = await _parseVocabularyData(jsonString);
      print('Loaded scenes: ${vocabularyData.scenes.length}');
      
      // Debug each scene
      for (var scene in vocabularyData.scenes) {
        print('Scene ID: ${scene.id}, Name: ${scene.name}');
        if (scene.imagePath != null) {
          print('  Image path: ${scene.imagePath}');
        }
        if (scene.imageLayers != null) {
          print('  Image layers: ${scene.imageLayers!.length}');
          for (var layer in scene.imageLayers!) {
            print('    Layer: ${layer.id}, Path: ${layer.imagePath}');
          }
        }
      }
      
      // Verify that the data is valid
      _validateVocabularyData();
    } catch (e) {
      _errorMessage = 'Could not load vocabulary data. Check the app assets and try again.';
      print('Failed to load vocabulary data: $e');
      // Keep the app renderable while exposing the failure to the UI.
      vocabularyData = _createEmptyVocabularyData();
    }
  }

  /// Parse the JSON string into VocabularyData object
  Future<VocabularyData> _parseVocabularyData(String jsonString) async {
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return VocabularyData.fromJson(jsonMap);
  }
  
  /// Allows loading a vocabulary file selected by the user
  /// Returns true if successful, false otherwise
  Future<bool> loadVocabularyFromJsonString(String jsonString) async {
    try {
      final newVocabularyData = await _parseVocabularyData(jsonString);
      
      // Validate before assigning
      _validateVocabularyDataObject(newVocabularyData);
      
      // If valid, update the current data
      vocabularyData = newVocabularyData;
      _isExternalData = true;
      
      return true;
    } catch (e) {
      print('Error loading vocabulary from JSON string: $e');
      return false;
    }
  }

  /// Validate that the vocabulary data is properly formatted
  /// Validates the vocabulary data structure
  void _validateVocabularyData() {
    _validateVocabularyDataObject(vocabularyData);
  }
  
  /// Validates a vocabulary data object
  void _validateVocabularyDataObject(VocabularyData data) {
    // Check that we have at least one language and no duplicates.
    if (data.supportedLanguages.isEmpty) {
      throw Exception('No supported languages found in vocabulary data');
    }
    if (data.supportedLanguages.any((language) => language.trim().isEmpty) ||
        data.supportedLanguages.toSet().length != data.supportedLanguages.length) {
      throw Exception('Supported languages must be non-empty and unique');
    }

    // Check that we have at least one scene.
    if (data.scenes.isEmpty) {
      throw Exception('No scenes found in vocabulary data');
    }
    final sceneIds = <String>{};

    // Verify each scene has a valid image path or layers
    for (var scene in data.scenes) {
      if (scene.id.trim().isEmpty || scene.name.trim().isEmpty ||
          !sceneIds.add(scene.id)) {
        throw Exception('Scene IDs and names must be non-empty and scene IDs unique');
      }

      // Scene can have either direct imagePath or imageLayers
      if ((scene.imagePath == null || scene.imagePath!.isEmpty) &&
          (scene.imageLayers == null || scene.imageLayers!.isEmpty)) {
        print('Scene ${scene.id} has neither a valid image path nor image layers');
        throw Exception('Scene ${scene.id} has neither a valid image path nor image layers');
      }
      
      // Validate interaction points and their localized resources.
      final pointIds = <String>{};
      for (final point in scene.interactionPoints) {
        if (point.id.trim().isEmpty || point.label.trim().isEmpty ||
            !pointIds.add(point.id)) {
          throw Exception('Interaction point IDs and labels in scene ${scene.id} must be non-empty and unique');
        }
        if (point.x < 0 || point.x > 1 || point.y < 0 || point.y > 1) {
          throw Exception('Interaction point ${point.id} in scene ${scene.id} has coordinates outside 0..1');
        }
        for (final translation in point.translations) {
          if (!data.supportedLanguages.contains(translation.languageCode) ||
              translation.text.trim().isEmpty) {
            throw Exception('Invalid translation for ${point.id} in scene ${scene.id}');
          }
        }
        for (final audio in point.audioFiles) {
          if (!data.supportedLanguages.contains(audio.languageCode) ||
              audio.filePath.trim().isEmpty) {
            throw Exception('Invalid audio file for ${point.id} in scene ${scene.id}');
          }
        }
      }

      // If using imageLayers, check that each layer has a valid path.
      if (scene.imageLayers != null && scene.imageLayers!.isNotEmpty) {
        for (var layer in scene.imageLayers!) {
          if (layer.id.trim().isEmpty || layer.imagePath.trim().isEmpty) {
            throw Exception('Layers in scene ${scene.id} require IDs and image paths');
          }
          if (layer.opacity < 0 || layer.opacity > 1 || layer.scale <= 0) {
            throw Exception('Layer ${layer.id} in scene ${scene.id} has invalid opacity or scale');
          }
        }
      }
    }
  }

  /// Create empty vocabulary data as a fallback
  VocabularyData _createEmptyVocabularyData() {
    return VocabularyData(
      title: 'Empty Vocabulary',
      description: 'No vocabulary data available',
      supportedLanguages: ['en'],
      scenes: [],
    );
  }

  /// Load vocabulary from a custom directory at runtime
  /// This would be used if the app needs to load vocabulary files
  /// from a directory that is specified at build time
  /// Load vocabulary data from a directory selected by the user
  /// Works on desktop and Android platforms
  Future<bool> loadVocabularyFromDirectory(String directoryPath) async {
    if (PlatformUtils.isWeb) {
      // Web platform doesn't support directory access in the same way
      return false;
    }
    
    try {
      _externalDirectoryPath = directoryPath;
      
      // Find the JSON file in the directory
      final jsonFilePath = '$directoryPath/vocabulary.json';
      
      // Use platform-specific file loading
      String jsonString;
      if (PlatformUtils.isDesktop || PlatformUtils.isAndroid) {
        jsonString = await PlatformUtils.loadFileFromFilesystem(jsonFilePath);
      } else {
        // Other platforms - should not happen given the check above
        return false;
      }
      
      // Parse the JSON data
      vocabularyData = await _parseVocabularyData(jsonString);
      
      // Validate the data
      _validateVocabularyData();
      
      // Set external data flag
      _isExternalData = true;
      
      return true;
    } catch (e) {
      print('Failed to load vocabulary from directory: $e');
      _externalDirectoryPath = null;
      _isExternalData = false;
      return false;
    }
  }
  
}