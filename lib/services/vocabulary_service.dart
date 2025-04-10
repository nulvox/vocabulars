import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/scenes_model.dart';
import '../utils/app_constants.dart';
import '../utils/platform_utils.dart';

/// Service responsible for loading and parsing vocabulary data
class VocabularyService {
  /// The parsed vocabulary data
  late VocabularyData vocabularyData;
  
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
      print('Failed to load vocabulary data: $e');
      // Load fallback data if available or create empty data
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
    // Check that we have at least one language
    if (data.supportedLanguages.isEmpty) {
      throw Exception('No supported languages found in vocabulary data');
    }
    
    // Check that we have at least one scene
    if (data.scenes.isEmpty) {
      throw Exception('No scenes found in vocabulary data');
    }
    
    // Verify each scene has a valid image path or layers
    for (var scene in data.scenes) {
      // Scene can have either direct imagePath or imageLayers
      if ((scene.imagePath == null || scene.imagePath!.isEmpty) &&
          (scene.imageLayers == null || scene.imageLayers!.isEmpty)) {
        print('Scene ${scene.id} has neither a valid image path nor image layers');
        throw Exception('Scene ${scene.id} has neither a valid image path nor image layers');
      }
      
      // If using imageLayers, check that each layer has a valid path
      if (scene.imageLayers != null && scene.imageLayers!.isNotEmpty) {
        for (var layer in scene.imageLayers!) {
          if (layer.imagePath.isEmpty) {
            print('Layer ${layer.id} in scene ${scene.id} has an empty image path');
            throw Exception('Layer ${layer.id} in scene ${scene.id} has an empty image path');
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
  
  /// Allows user to pick a vocabulary directory via file picker
  /// Returns true if successful
  Future<bool> pickAndLoadVocabularyDirectory() async {
    if (PlatformUtils.isWeb) {
      // Web doesn't support directory picking in the same way
      // Instead, we could allow picking a JSON file
      final jsonString = await PlatformUtils.pickJsonFile();
      if (jsonString != null) {
        return await loadVocabularyFromJsonString(jsonString);
      }
      return false;
    }
    
    // Desktop and Android: pick a directory
    final directoryPath = await PlatformUtils.pickDirectory();
    if (directoryPath != null) {
      return await loadVocabularyFromDirectory(directoryPath);
    }
    return false;
  }
}