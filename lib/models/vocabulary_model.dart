import 'package:flutter/foundation.dart';

import '../utils/app_logger.dart';
import '../utils/app_constants.dart';
import 'scenes_model.dart';

/// The main model class that holds and manages the vocabulary application state.
class VocabularyModel extends ChangeNotifier {
  /// The complete vocabulary data loaded from JSON
  VocabularyData vocabularyData;

  /// The currently selected language code
  String _currentLanguage;

  /// The index of the currently displayed scene
  int _currentSceneIndex = 0;

  /// The ID of the initial scene to display
  static const String initialSceneId = 'bedroom';

  /// The currently active interaction point, if any
  InteractionPoint? _activeInteractionPoint;

  /// A user-facing error from the most recent data load, if any.
  String? _errorMessage;

  /// Constructor that initializes the model with vocabulary data and language
  VocabularyModel({
    required this.vocabularyData,
    required String initialLanguage,
    String? errorMessage,
  }) : _errorMessage = errorMessage,
       _currentLanguage =
           vocabularyData.supportedLanguages.contains(initialLanguage)
           ? initialLanguage
           : (vocabularyData.supportedLanguages.isNotEmpty
                 ? vocabularyData.supportedLanguages.first
                 : AppConstants.defaultLanguage) {
    // Set initial scene to bedroom
    _setInitialScene();
  }

  /// Sets the initial scene to the bedroom scene
  void _setInitialScene() {
    // Safety check - ensure we have scenes
    if (vocabularyData.scenes.isEmpty) {
      AppLogger.debug('ERROR: No scenes found in vocabulary data');
      return;
    }

    AppLogger.debug(
      'Setting initial scene. Available scenes: ${vocabularyData.scenes.length}',
    );
    AppLogger.debug(
      'Scene IDs: ${vocabularyData.scenes.map((s) => s.id).join(', ')}',
    );

    // Try to find the bedroom scene
    final bedroomIndex = vocabularyData.scenes.indexWhere(
      (scene) => scene.id == initialSceneId,
    );
    AppLogger.debug('Bedroom scene index: $bedroomIndex');

    if (bedroomIndex != -1) {
      _currentSceneIndex = bedroomIndex;
      AppLogger.debug(
        'Set current scene index to $bedroomIndex (${vocabularyData.scenes[bedroomIndex].name})',
      );
    } else {
      // If bedroom scene not found, default to first scene
      _currentSceneIndex = 0;
      AppLogger.debug(
        'Bedroom scene not found, defaulting to scene 0 (${vocabularyData.scenes[0].name})',
      );
    }
  }

  /// Gets the current language code
  String get currentLanguage => _currentLanguage;

  /// Gets the current scene
  Scene get currentScene => vocabularyData.scenes.isNotEmpty
      ? vocabularyData.scenes[_currentSceneIndex]
      : throw Exception('No scenes available in vocabulary data');

  /// Gets all available scenes
  List<Scene> get scenes => vocabularyData.scenes;

  /// Gets the total number of scenes
  int get sceneCount => vocabularyData.scenes.length;

  /// Gets the currently active interaction point
  InteractionPoint? get activeInteractionPoint => _activeInteractionPoint;

  /// Gets the current scene index
  int get currentSceneIndex => _currentSceneIndex;

  /// Gets the most recent loading error, if any.
  String? get errorMessage => _errorMessage;

  /// Gets whether the vocabulary app supports multiple languages
  bool get isMultilingual => vocabularyData.supportedLanguages.length > 1;

  /// Gets the list of available languages
  List<String> get availableLanguages => vocabularyData.supportedLanguages;

  /// Replaces the current vocabulary data after a reload.
  void replaceVocabularyData(VocabularyData data, {String? errorMessage}) {
    vocabularyData = data;
    _errorMessage = errorMessage;
    _activeInteractionPoint = null;
    if (!vocabularyData.supportedLanguages.contains(_currentLanguage)) {
      _currentLanguage = vocabularyData.supportedLanguages.isNotEmpty
          ? vocabularyData.supportedLanguages.first
          : AppConstants.defaultLanguage;
    }
    _setInitialScene();
    notifyListeners();
  }

  /// Changes the current scene to the given index
  void navigateToScene(int index) {
    if (index >= 0 && index < vocabularyData.scenes.length) {
      _currentSceneIndex = index;
      _activeInteractionPoint = null;
      notifyListeners();
    }
  }

  /// Moves to the next scene if available
  void nextScene() {
    if (_currentSceneIndex < vocabularyData.scenes.length - 1) {
      _currentSceneIndex++;
      _activeInteractionPoint = null;
      notifyListeners();
    }
  }

  /// Moves to the previous scene if available
  void previousScene() {
    if (_currentSceneIndex > 0) {
      _currentSceneIndex--;
      _activeInteractionPoint = null;
      notifyListeners();
    }
  }

  /// Sets the active interaction point
  void setActiveInteractionPoint(InteractionPoint? point) {
    _activeInteractionPoint = point;
    notifyListeners();
  }

  /// Changes the current language
  void setLanguage(String languageCode) {
    if (vocabularyData.supportedLanguages.contains(languageCode)) {
      _currentLanguage = languageCode;
      notifyListeners();
    }
  }
}
