import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabular/services/vocabulary_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VocabularyService', () {
    late VocabularyService service;
    
    setUp(() {
      service = VocabularyService(
        assetBundle: _MockAssetBundle(json.encode(_getMockVocabularyData())),
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
      
      // Validation is exercised through the public loading API.
      expect(
        await service.loadVocabularyFromJsonString(json.encode(_getMockVocabularyData())),
        isTrue,
      );

      final invalidCases = <Map<String, dynamic>>[
        {
          'title': 'Empty',
          'description': 'Empty',
          'supportedLanguages': <String>[],
          'scenes': <Map<String, dynamic>>[],
        },
        {
          'title': 'Empty',
          'description': 'Empty',
          'supportedLanguages': ['en'],
          'scenes': <Map<String, dynamic>>[],
        },
        {
          'title': 'Empty',
          'description': 'Empty',
          'supportedLanguages': ['en'],
          'scenes': [
            {
              'id': 'scene1',
              'name': 'Scene 1',
              'imagePath': '',
              'interactionPoints': [],
            },
          ],
        },
      ];

      for (final invalidData in invalidCases) {
        expect(
          await service.loadVocabularyFromJsonString(json.encode(invalidData)),
          isFalse,
        );
      }
    });
  });
}

class _MockAssetBundle extends CachingAssetBundle {
  _MockAssetBundle(this.contents);

  final String contents;

  @override
  Future<ByteData> load(String key) async {
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(contents)));
  }
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