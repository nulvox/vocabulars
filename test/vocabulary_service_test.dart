import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabular/models/scenes_model.dart';
import 'package:vocabular/services/vocabulary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VocabularyService', () {
    late VocabularyService service;
    
    setUp(() {
      service = VocabularyService();
      
      // Mock asset bundle
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        MethodChannel('flutter/assets'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getAssetAsString') {
            if (methodCall.arguments == 'assets/vocabulary.json') {
              return json.encode(_getMockVocabularyData());
            }
          }
          return null;
        }
      );
    });

    test('initialize should load vocabulary data', () async {
      await service.initialize();
      
      expect(service.vocabularyData, isNotNull);
      expect(service.vocabularyData.title, 'Test Vocabulary');
      expect(service.vocabularyData.supportedLanguages, ['en', 'es']);
      expect(service.vocabularyData.scenes.length, 2);
    });
    
    test('validate checks for required data', () async {
      // This test makes sure the validation logic is working
      
      // First with valid data
      service.vocabularyData = VocabularyData.fromJson(_getMockVocabularyData());
      expect(() => service._validateVocabularyData(), returnsNormally);
      
      // Then with invalid data
      service.vocabularyData = VocabularyData(
        title: 'Empty',
        description: 'Empty',
        supportedLanguages: [],  // Empty languages - should fail
        scenes: [
          Scene(
            id: 'scene1',
            name: 'Scene 1',
            imagePath: 'scene1.jpg',
            interactionPoints: [],
          ),
        ],
      );
      
      expect(() => service._validateVocabularyData(), throwsException);
      
      // Test with empty scenes
      service.vocabularyData = VocabularyData(
        title: 'Empty',
        description: 'Empty',
        supportedLanguages: ['en'],
        scenes: [],  // Empty scenes - should fail
      );
      
      expect(() => service._validateVocabularyData(), throwsException);
      
      // Test with invalid image path
      service.vocabularyData = VocabularyData(
        title: 'Empty',
        description: 'Empty',
        supportedLanguages: ['en'],
        scenes: [
          Scene(
            id: 'scene1',
            name: 'Scene 1',
            imagePath: '',  // Empty image path - should fail
            interactionPoints: [],
          ),
        ],
      );
      
      expect(() => service._validateVocabularyData(), throwsException);
    });
    
    test('createEmptyVocabularyData returns valid data structure', () {
      final emptyData = service._createEmptyVocabularyData();
      
      expect(emptyData.title, 'Empty Vocabulary');
      expect(emptyData.supportedLanguages, ['en']);
      expect(emptyData.scenes, isEmpty);
    });
  });
}

/// Creates a mock vocabulary data structure for testing
Map<String, dynamic> _getMockVocabularyData() {
  return {
    "title": "Test Vocabulary",
    "description": "Test Description",
    "supportedLanguages": ["en", "es"],
    "scenes": [
      {
        "id": "scene1",
        "name": "Scene 1",
        "imagePath": "scene1.jpg",
        "interactionPoints": [
          {
            "id": "point1",
            "label": "Item 1",
            "x": 0.5,
            "y": 0.5,
            "audioFiles": [
              {
                "languageCode": "en",
                "filePath": "en/item1.mp3"
              }
            ],
            "translations": [
              {
                "languageCode": "en",
                "text": "Item 1"
              },
              {
                "languageCode": "es",
                "text": "Artículo 1"
              }
            ]
          }
        ]
      },
      {
        "id": "scene2",
        "name": "Scene 2",
        "imagePath": "scene2.jpg",
        "interactionPoints": []
      }
    ]
  };
}