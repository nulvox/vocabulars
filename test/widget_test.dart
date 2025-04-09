import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vocabular/models/vocabulary_model.dart';
import 'package:vocabular/models/scenes_model.dart';
import 'package:vocabular/widgets/language_dropdown.dart';
import 'package:vocabular/widgets/navigation_controls.dart';
import 'package:vocabular/widgets/scene_view.dart';
import 'package:vocabular/widgets/vocabulary_card.dart';

void main() {
  testWidgets('LanguageDropdown displays language options correctly', 
      (WidgetTester tester) async {
    bool languageChanged = false;
    String? selectedLanguage;
    
    // Build our widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LanguageDropdown(
          selectedLanguage: 'en',
          availableLanguages: const ['en', 'es', 'fr'],
          onLanguageChanged: (String lang) {
            languageChanged = true;
            selectedLanguage = lang;
          },
        ),
      ),
    ));

    // Tap the dropdown button
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    // Verify all language options are displayed
    expect(find.text('English'), findsWidgets);
    expect(find.text('Español'), findsWidgets);
    expect(find.text('Français'), findsWidgets);
    
    // Select a different language
    await tester.tap(find.text('Español').last);
    await tester.pumpAndSettle();
    
    // Verify callback was triggered with correct language
    expect(languageChanged, true);
    expect(selectedLanguage, 'es');
  });

  testWidgets('NavigationControls displays correctly', 
      (WidgetTester tester) async {
    bool nextPressed = false;
    bool previousPressed = false;
    
    // Build our widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: NavigationControls(
          currentIndex: 1,
          totalScenes: 3,
          onPrevious: () {
            previousPressed = true;
          },
          onNext: () {
            nextPressed = true;
          },
        ),
      ),
    ));

    // Verify the scene counter text is displayed correctly
    expect(find.text('Scene 2 of 3'), findsOneWidget);
    
    // Tap the previous button
    await tester.tap(find.text('Previous'));
    await tester.pump();
    expect(previousPressed, true);
    
    // Tap the next button
    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(nextPressed, true);
  });

  testWidgets('VocabularyCard displays word and translations', 
      (WidgetTester tester) async {
    bool closePressed = false;
    
    // Create a test interaction point
    final interactionPoint = InteractionPoint(
      id: 'test',
      label: 'Test Item',
      x: 0.5,
      y: 0.5,
      audioFiles: [
        AudioFile(
          languageCode: 'en',
          filePath: 'en/test.mp3',
        ),
      ],
      translations: [
        Translation(
          languageCode: 'en',
          text: 'Test Item',
        ),
        Translation(
          languageCode: 'es',
          text: 'Artículo de Prueba',
        ),
        Translation(
          languageCode: 'fr',
          text: 'Article de Test',
        ),
      ],
    );
    
    // Build our widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: VocabularyCard(
          interactionPoint: interactionPoint,
          currentLanguage: 'en',
          onClose: () {
            print('onClose callback triggered in test');
            closePressed = true;
            print('closePressed set to true: $closePressed');
          },
        ),
      ),
    ));

    // Verify the word is displayed
    expect(find.text('Test Item'), findsOneWidget);
    
    // Verify translations are shown
    expect(find.text('Translations:'), findsOneWidget);
    expect(find.text('Español:'), findsOneWidget);
    expect(find.text('Artículo de Prueba'), findsOneWidget);
    expect(find.text('Français:'), findsOneWidget);
    expect(find.text('Article de Test'), findsOneWidget);
    
    // Tap the close button - use a more specific finder combining icon and tooltip
    final closeButton = find.byWidgetPredicate((widget) =>
      widget is IconButton &&
      widget.tooltip == 'Close' &&
      widget.onPressed != null
    );
    
    expect(closeButton, findsOneWidget);
    await tester.tap(closeButton);
    await tester.pumpAndSettle(); // Use pumpAndSettle to complete animations
    
    expect(closePressed, true);
  });

  testWidgets('SceneView displays scene with interaction points', 
      (WidgetTester tester) async {
    // Create a test scene
    final scene = Scene(
      id: 'test-scene',
      name: 'Test Scene',
      imagePath: 'test-scene.jpg',
      interactionPoints: [
        InteractionPoint(
          id: 'point1',
          label: 'Point 1',
          x: 0.3,
          y: 0.3,
          audioFiles: [],
          translations: [
            Translation(
              languageCode: 'en',
              text: 'Point 1',
            ),
          ],
        ),
        InteractionPoint(
          id: 'point2',
          label: 'Point 2',
          x: 0.7,
          y: 0.7,
          audioFiles: [],
          translations: [
            Translation(
              languageCode: 'en',
              text: 'Point 2',
            ),
          ],
        ),
      ],
    );
    
    // Create a model with the test scene
    final vocabularyData = VocabularyData(
      title: 'Test',
      description: 'Test',
      supportedLanguages: ['en'],
      scenes: [scene],
    );
    
    final model = VocabularyModel(
      vocabularyData: vocabularyData,
      initialLanguage: 'en',
    );
    
    // Build our widget
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<VocabularyModel>.value(
          value: model,
          child: SceneView(
            scene: scene,
            currentLanguage: 'en',
          ),
        ),
      ),
    ));

    // Verify interaction points are displayed (by looking for the icons)
    expect(find.byIcon(Icons.touch_app), findsNWidgets(2));
    
    // Tap on the first interaction point
    await tester.tap(find.byIcon(Icons.touch_app).first);
    await tester.pumpAndSettle();
    
    // Verify that point is now active
    expect(model.activeInteractionPoint, scene.interactionPoints[0]);
    
    // Verify that the vocabulary card is now displayed
    expect(find.byType(VocabularyCard), findsOneWidget);
  });

  testWidgets('Basic IconButton test', (WidgetTester tester) async {
    bool buttonPressed = false;
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Test Button',
            onPressed: () {
              print('Basic button pressed');
              buttonPressed = true;
            },
          ),
        ),
      ),
    ));
    
    // Verify button is found
    final buttonFinder = find.byType(IconButton);
    expect(buttonFinder, findsOneWidget);
    
    // Tap the button
    await tester.tap(buttonFinder);
    await tester.pump(); // Process the tap event
    
    // Verify callback was triggered
    expect(buttonPressed, true);
  });
}