import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import '../models/scenes_model.dart';
import '../utils/app_constants.dart';
import '../utils/platform_utils.dart';

/// Widget that displays vocabulary information for an interaction point
class VocabularyCard extends StatefulWidget {
  /// The interaction point to display
  final InteractionPoint interactionPoint;
  
  /// Current language code
  final String currentLanguage;
  
  /// Callback when the card is closed
  final VoidCallback onClose;

  const VocabularyCard({
    super.key,
    required this.interactionPoint,
    required this.currentLanguage,
    required this.onClose,
  });

  @override
  State<VocabularyCard> createState() => _VocabularyCardState();
}

class _VocabularyCardState extends State<VocabularyCard> with SingleTickerProviderStateMixin {
  /// Audio player for pronunciations
  late AudioPlayer _audioPlayer;
  
  /// Animation controller for card entry
  late AnimationController _animationController;
  
  /// Animation for card entry
  late Animation<double> _scaleAnimation;
  
  /// Track if audio is currently playing
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize audio player
    _audioPlayer = AudioPlayer();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: AppConstants.animationDuration,
    );
    
    // Create scale animation
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    
    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        margin: const EdgeInsets.all(AppConstants.padding),
        elevation: 8.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: AppConstants.maxCardWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card header with word and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.interactionPoint.getTranslation(widget.currentLanguage),
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        print('Close button pressed');
                        widget.onClose();
                        print('onClose callback executed');
                      },
                      tooltip: 'Close',
                    ),
                  ],
                ),
                
                const Divider(),
                
                // Audio pronunciation button
                if (_getAudioFile() != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: _playAudio,
                      icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up),
                      label: Text(_isPlaying ? 'Stop' : 'Listen'),
                    ),
                  ),
                
                // Display all translations
                if (widget.interactionPoint.translations.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Translations:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        ...widget.interactionPoint.translations
                            .where((t) => t.languageCode != widget.currentLanguage)
                            .map(_buildTranslationItem),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a translation item for the list
  Widget _buildTranslationItem(Translation translation) {
    final langName = AppConstants.languageNames[translation.languageCode] ?? 
                    translation.languageCode;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.0,
            child: Text(
              '$langName:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(translation.text),
          ),
        ],
      ),
    );
  }

  /// Gets the appropriate audio file for the current language
  AudioFile? _getAudioFile() {
    return widget.interactionPoint.getAudioForLanguage(widget.currentLanguage);
  }

  /// Plays the audio pronunciation
  Future<void> _playAudio() async {
    final audioFile = _getAudioFile();
    if (audioFile == null) return;
    
    setState(() {
      _isPlaying = true;
    });
    try {
      // Get the appropriate audio file path based on platform
      final audioPath = PlatformUtils.isWeb
          ? 'assets/${AppConstants.audioAssetsDir}${audioFile.filePath}'
          : '${AppConstants.audioAssetsDir}${audioFile.filePath}';
      
      // Load and play the audio
      await _audioPlayer.setAsset(audioPath);
      await _audioPlayer.play();
      
      
      // Wait until audio completes
      await _audioPlayer.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed
      );
    } catch (e) {
      print('Error playing audio: $e');
    } finally {
      setState(() {
        _isPlaying = false;
      });
    }
  }
}