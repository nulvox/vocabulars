import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/vocabulary_model.dart';
import '../models/scenes_model.dart';
import '../services/vocabulary_service.dart';
import '../widgets/language_dropdown.dart';
import '../widgets/scene_view.dart';
import '../widgets/navigation_controls.dart';
import '../widgets/scene_dropdown.dart';
import '../utils/app_constants.dart';
import '../utils/platform_utils.dart';

/// The main screen of the application showing the current scene and controls
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    try {
      // Access the vocabulary model
      final vocabularyModel = Provider.of<VocabularyModel>(context);
      final isMultilingual = vocabularyModel.isMultilingual;
      
      // Safety check for empty scenes
      if (vocabularyModel.sceneCount == 0) {
        return _buildErrorScaffold('No scenes available in vocabulary data');
      }
      
      return _buildMainScaffold(vocabularyModel, isMultilingual);
    } catch (e) {
      print('Error in HomeScreen build: $e');
      return _buildErrorScaffold('Error loading application: $e');
    }
  }
  
  /// Builds the main scaffold with all app content
  Widget _buildMainScaffold(VocabularyModel vocabularyModel, bool isMultilingual) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vocabularyModel.vocabularyData.title),
        actions: [
          // Always show language dropdown (requirements)
          LanguageDropdown(
            selectedLanguage: vocabularyModel.currentLanguage,
            availableLanguages: vocabularyModel.availableLanguages,
            onLanguageChanged: _onLanguageChanged,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'About',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Main content area - Scene display
                Expanded(
                  child: SceneView(
                    scene: vocabularyModel.currentScene,
                    currentLanguage: vocabularyModel.currentLanguage,
                  ),
                ),
                
                // Bottom controls bar
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8.0,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Scene selector dropdown
                      Row(
                        children: [
                          const Text('Scene: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SceneDropdown(
                            selectedSceneIndex: vocabularyModel.currentSceneIndex,
                            availableScenes: vocabularyModel.scenes,
                            onSceneChanged: (index) => vocabularyModel.navigateToScene(index),
                          ),
                        ],
                      ),
                      
                      // Navigation controls
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: vocabularyModel.currentSceneIndex > 0
                                ? () => vocabularyModel.previousScene()
                                : null,
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Previous'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: vocabularyModel.currentSceneIndex > 0
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Scene ${vocabularyModel.currentSceneIndex + 1} of ${vocabularyModel.sceneCount}',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: vocabularyModel.currentSceneIndex < vocabularyModel.sceneCount - 1
                                ? () => vocabularyModel.nextScene()
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Next'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: vocabularyModel.currentSceneIndex < vocabularyModel.sceneCount - 1
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Loading indicator
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Updates the selected language and saves it to preferences
  void _onLanguageChanged(String languageCode) async {
    final vocabularyModel = Provider.of<VocabularyModel>(context, listen: false);
    vocabularyModel.setLanguage(languageCode);
    
    // Save the selected language to preferences
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('selectedLanguage', languageCode);
  }

  /// Shows information about the vocabulary set
  void _showInfoDialog() {
    final vocabularyModel = Provider.of<VocabularyModel>(context, listen: false);
    final vocabularyData = vocabularyModel.vocabularyData;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vocabularyData.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vocabularyData.description),
              const SizedBox(height: 16),
              Text('Supported Languages:'),
              ...vocabularyData.supportedLanguages.map((code) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4),
                  child: Text(AppConstants.languageNames[code] ?? code),
                );
              }),
              const SizedBox(height: 16),
              Text('Number of Scenes: ${vocabularyData.scenes.length}'),
              const SizedBox(height: 8),
              Text('Total Vocabulary Items: ${_countVocabularyItems(vocabularyData)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  

  /// Counts the total number of vocabulary items across all scenes
  int _countVocabularyItems(VocabularyData data) {
    int count = 0;
    for (var scene in data.scenes) {
      count += scene.interactionPoints.length;
    }
    return count;
  }
  
  /// Builds an error scaffold when something goes wrong
  Widget _buildErrorScaffold(String errorMessage) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabular - Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}