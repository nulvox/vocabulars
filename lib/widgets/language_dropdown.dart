import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  /// Gets a flag image widget for a language
  Widget _getFlagImage(String code) {
    // Fixed size for flag icons
    const double flagWidth = 24.0;
    const double flagHeight = 16.0;
    
    // Path to the flag image asset
    final String flagPath = 'assets/images/flags/$code.svg';
    
    // Try to load the flag image, but provide a text-based fallback
    return SizedBox(
      width: flagWidth,
      height: flagHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2.0),
        child: _buildFlagWidget(code, flagPath),
      ),
    );
  }
  
  /// Builds the appropriate flag widget based on environment
  Widget _buildFlagWidget(String code, String flagPath) {
    // Check if SVG exists by attempting to load it with error handling
    try {
      return SvgPicture.asset(
        flagPath,
        width: 24.0,
        height: 16.0,
        fit: BoxFit.cover,
        placeholderBuilder: (BuildContext context) {
          // Fallback to text-based representation if SVG fails to load
          return Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: Text(
              code.toUpperCase(),
              style: const TextStyle(
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      );
    } catch (e) {
      // Additional error handling for platforms that don't handle errorBuilder
      return Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Text(
          code.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}