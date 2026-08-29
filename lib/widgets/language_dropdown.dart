import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

/// A dropdown widget for selecting the current language
class LanguageDropdown extends StatelessWidget {
  /// The currently selected language code
  final String selectedLanguage;
  
  /// List of available language codes
  final List<String> availableLanguages;
  
  /// Callback function when a language is selected
  final Function(String) onLanguageChanged;

  const LanguageDropdown({
    super.key,
    required this.selectedLanguage,
    required this.availableLanguages,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButton<String>(
        value: selectedLanguage,
        onChanged: (String? newValue) {
          if (newValue != null) {
            onLanguageChanged(newValue);
          }
        },
        underline: Container(
          height: 2,
          color: Theme.of(context).primaryColor,
        ),
        items: availableLanguages.map<DropdownMenuItem<String>>((String code) {
          return DropdownMenuItem<String>(
            value: code,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display language flag image if available
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _getFlagImage(code),
                ),
                // Display language name
                Container(
                  constraints: const BoxConstraints(
                    minWidth: AppConstants.languageDropdownWidth,
                  ),
                  child: Text(
                    AppConstants.languageNames[code] ?? code,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Returns a platform-independent flag emoji for the language.
  ///
  /// Language codes are not necessarily country codes, so keep this mapping
  /// explicit rather than deriving a flag from the first two letters.
  Widget _getFlagImage(String code) {
    const flags = {
      'en': '🇬🇧',
      'es': '🇪🇸',
      'fr': '🇫🇷',
      'ja': '🇯🇵',
      'ru': '🇷🇺',
      'de': '🇩🇪',
    };
    final flag = flags[code.toLowerCase()];

    return SizedBox(
      width: 24.0,
      height: 20.0,
      child: Center(
        child: Text(
          flag ?? '🌐',
          textScaler: const TextScaler.linear(0.9),
          semanticsLabel: flag == null ? 'Language' : '$code flag',
        ),
      ),
    );
  }
}