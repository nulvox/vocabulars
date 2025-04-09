import 'package:flutter_test/flutter_test.dart';
import 'package:vocabular/models/vocabulary_model.dart';
import 'package:vocabular/models/scenes_model.dart';

void main() {
  late VocabularyModel vocabularyModel;
  late VocabularyData testData;

  setUp(() {
    // Create test vocabulary data
    testData = VocabularyData(
      title: 'Test Vocabulary',
      description: 'Test Description',
      supportedLanguages: ['en', 'es', 'fr'],
      scenes: [
        Scene(
          id: 'scene1',
          name: 'Test Scene 1',
          imagePath: 'test_scene1.jpg',
          interactionPoints: [
            InteractionPoint(
              id: 'point1',
              label: 'Point 1',
              x: 0.5,
              y: 0.5,
              audioFiles: [
                AudioFile(
                  languageCode: 'en',
                  filePath: 'en/point1.mp3',
                ),
                AudioFile(
                  languageCode: 'es',
                  filePath: 'es/point1.mp3',
                ),
              ],
              translations: [
                Translation(
                  languageCode: 'en',
                  text: 'Point 1',
                ),
                Translation(
                  languageCode: 'es',
                  text: 'Punto 1',
                ),
                Translation(
                  languageCode: 'fr',
                  text: 'Point 1',
                ),
              ],
            ),
          ],
        ),
        Scene(
          id: 'scene2',
          name: 'Test Scene 2',
          imagePath: 'test_scene2.jpg',
          interactionPoints: [],
        ),
      ],
    );

    // Initialize model with test data
    vocabularyModel = VocabularyModel(
      vocabularyData: testData,
      initialLanguage: 'en',
    );
  });

  group('VocabularyModel initialization', () {
    test('should have correct initial values', () {
      expect(vocabularyModel.currentLanguage, 'en');
      expect(vocabularyModel.currentSceneIndex, 0);
      expect(vocabularyModel.sceneCount, 2);
      expect(vocabularyModel.currentScene, testData.scenes[0]);
      expect(vocabularyModel.activeInteractionPoint, null);
    });

    test('should indicate multilingual status correctly', () {
      expect(vocabularyModel.isMultilingual, true);
      expect(vocabularyModel.availableLanguages, ['en', 'es', 'fr']);
    });
  });

  group('VocabularyModel scene navigation', () {
    test('should navigate to next scene', () {
      vocabularyModel.nextScene();
      expect(vocabularyModel.currentSceneIndex, 1);
      expect(vocabularyModel.currentScene, testData.scenes[1]);
    });

    test('should not go beyond last scene', () {
      vocabularyModel.nextScene();
      expect(vocabularyModel.currentSceneIndex, 1);
      
      vocabularyModel.nextScene();
      expect(vocabularyModel.currentSceneIndex, 1); // Should remain at 1
    });

    test('should navigate to previous scene', () {
      vocabularyModel.nextScene();
      expect(vocabularyModel.currentSceneIndex, 1);
      
      vocabularyModel.previousScene();
      expect(vocabularyModel.currentSceneIndex, 0);
    });

    test('should not go before first scene', () {
      expect(vocabularyModel.currentSceneIndex, 0);
      
      vocabularyModel.previousScene();
      expect(vocabularyModel.currentSceneIndex, 0); // Should remain at 0
    });

    test('should navigate to specific scene index', () {
      vocabularyModel.navigateToScene(1);
      expect(vocabularyModel.currentSceneIndex, 1);
    });

    test('should ignore invalid scene indices', () {
      vocabularyModel.navigateToScene(-1);
      expect(vocabularyModel.currentSceneIndex, 0); // Should remain at 0
      
      vocabularyModel.navigateToScene(999);
      expect(vocabularyModel.currentSceneIndex, 0); // Should remain at 0
    });
  });

  group('VocabularyModel interaction points', () {
    test('should set active interaction point', () {
      final point = testData.scenes[0].interactionPoints[0];
      vocabularyModel.setActiveInteractionPoint(point);
      expect(vocabularyModel.activeInteractionPoint, point);
    });

    test('should clear active interaction point', () {
      final point = testData.scenes[0].interactionPoints[0];
      vocabularyModel.setActiveInteractionPoint(point);
      expect(vocabularyModel.activeInteractionPoint, point);
      
      vocabularyModel.setActiveInteractionPoint(null);
      expect(vocabularyModel.activeInteractionPoint, null);
    });
  });

  group('VocabularyModel language selection', () {
    test('should change language', () {
      vocabularyModel.setLanguage('es');
      expect(vocabularyModel.currentLanguage, 'es');
    });

    test('should ignore invalid language codes', () {
      vocabularyModel.setLanguage('invalid');
      expect(vocabularyModel.currentLanguage, 'en'); // Should remain as 'en'
    });
  });
}