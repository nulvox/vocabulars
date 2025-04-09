/// Constants used throughout the application
class AppConstants {
  /// Default path to the vocabulary JSON file
  static const String defaultVocabularyPath = 'assets/vocabulary.json';
  
  /// Default language code to use if none is selected
  static const String defaultLanguage = 'en';
  
  /// Minimum width for the language selection dropdown
  static const double languageDropdownWidth = 120.0;
  
  /// Size of interaction point markers on the scene
  static const double interactionPointSize = 30.0;
  
  /// The color of interaction point markers
  static const int interactionPointColor = 0xFF2196F3; // Blue
  
  /// The color of active interaction point markers
  static const int activeInteractionPointColor = 0xFFFF5722; // Deep Orange
  
  /// Duration of animations
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  /// Boundary padding for UI elements
  static const double padding = 16.0;
  
  /// Interaction point tooltip offset
  static const double tooltipOffset = 8.0;
  
  /// Maximum width for the vocabulary card
  static const double maxCardWidth = 300.0;
  
  /// Asset directories
  static const String imageAssetsDir = 'assets/images/';
  static const String audioAssetsDir = 'assets/audio/';
  
  /// Available theme colors
  static const Map<String, int> themeColors = {
    'blue': 0xFF2196F3,
    'green': 0xFF4CAF50,
    'purple': 0xFF9C27B0,
    'orange': 0xFFFF9800,
  };
  
  /// Language name mappings
  static const Map<String, String> languageNames = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ru': 'Русский',
    'zh': '中文',
    'ja': '日本語',
    'ko': '한국어',
  };

  /// Private constructor to prevent instantiation
  AppConstants._();
}