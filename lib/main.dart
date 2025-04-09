import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'models/vocabulary_model.dart';
import 'utils/platform_utils.dart';
import 'screens/home_screen.dart';
import 'services/vocabulary_service.dart';
import 'utils/app_constants.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set orientation based on platform
  if (!kIsWeb && !PlatformUtils.isDesktop) {
    // Force landscape orientation on mobile devices only
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  
  // Load shared preferences for language settings
  final prefs = await SharedPreferences.getInstance();
  String? currentLanguage = prefs.getString('selectedLanguage');
  
  // Load vocabulary data
  final vocabularyService = VocabularyService();
  await vocabularyService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        // Provide the vocabulary service
        Provider.value(value: vocabularyService),
        // Provide the vocabulary model
        ChangeNotifierProvider(create: (_) => VocabularyModel(
          vocabularyData: vocabularyService.vocabularyData,
          initialLanguage: currentLanguage ?? AppConstants.defaultLanguage,
        )),
      ],
      child: const VocabularApp(),
    ),
  );
}

class VocabularApp extends StatelessWidget {
  const VocabularApp({super.key});

  @override
  Widget build(BuildContext context) {
    final vocabularyModel = Provider.of<VocabularyModel>(context);
    
    return MaterialApp(
      title: 'Vocabular',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      // Platform-specific settings
      supportedLocales: vocabularyModel.isMultilingual
          ? vocabularyModel.availableLanguages.map((code) => Locale(code))
          : [const Locale('en')],
      // Support for multiple languages if available
      locale: vocabularyModel.isMultilingual
          ? Locale(vocabularyModel.currentLanguage)
          : null,
    );
  }
}