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
  AudioPlayer? _audioPlayer;
  
  /// Whether audio playback is supported on this platform
  final bool _isAudioSupported = PlatformUtils.isAudioSupported;
  
  /// Animation controller for card entry
  late AnimationController _animationController;
  
  /// Animation for card entry
  late Animation<double> _scaleAnimation;
  
  /// Track if audio is currently playing
  bool _isPlaying = false;
  
  /// Track audio playback progress (0.0 to 1.0)
  double _playbackProgress = 0.0;
  
  /// Track if this widget is still mounted
  bool _isMounted = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize audio player only if supported on this platform
    if (_isAudioSupported) {
      _audioPlayer = AudioPlayer();
      
      // Listen for audio player state changes
      _audioPlayer!.playerStateStream.listen((state) {
        if (!_isMounted) return;
        
        if (state.processingState == ProcessingState.completed ||
            state.processingState == ProcessingState.idle) {
          setState(() {
            _isPlaying = false;
            _playbackProgress = 0.0;
          });
        }
      }, onError: (error) {
        if (kDebugMode) {
          print('Audio player error: $error');
        }
        if (_isMounted) {
          setState(() {
            _isPlaying = false;
            _playbackProgress = 0.0;
          });
        }
      });
      
      // Listen for position updates to track progress
      _audioPlayer!.positionStream.listen((position) {
        if (!_isMounted || !_isPlaying) return;
        
        final duration = _audioPlayer!.duration;
        if (duration != null && _isMounted) {
          setState(() {
            _playbackProgress = position.inMilliseconds / duration.inMilliseconds;
          });
        }
      });
    }
    
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
    _isMounted = false;
    if (_audioPlayer != null) {
      _audioPlayer!.stop();
      _audioPlayer!.dispose();
    }
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
                
                // Audio pronunciation button and progress - always show if audio file exists
                if (_getAudioFile() != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _playAudio,
                          icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up),
                          label: Text(_isPlaying ? 'Stop' : 'Listen'),
                          // Use a slightly different color if audio isn't supported
                          style: _isAudioSupported
                              ? null
                              : ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[400],
                                ),
                        ),
                        // Show progress bar when audio is playing
                        if (_isPlaying)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: LinearProgressIndicator(
                              value: _playbackProgress,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor
                              ),
                            ),
                          ),
                        
                        // Show platform compatibility notice if needed
                        if (!_isAudioSupported)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Audio playback not supported on this platform',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
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
    // If audio is not supported on this platform, show a message and return
    if (!_isAudioSupported || _audioPlayer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Audio playback is not supported on this platform'),
          backgroundColor: Colors.amber[700],
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      return;
    }
  
    if (_isPlaying) {
      // Stop currently playing audio
      await _audioPlayer!.stop();
      setState(() {
        _isPlaying = false;
      });
      return;
    }
    
    final audioFile = _getAudioFile();
    if (audioFile == null) {
      if (kDebugMode) {
        print('No audio file available for language: ${widget.currentLanguage}');
      }
      return;
    }
    
    setState(() {
      _isPlaying = true;
    });
    
    try {
      // Get the appropriate audio file path based on platform
      final audioPath = PlatformUtils.isWeb
          ? 'assets/audio/${audioFile.filePath}'
          : '${AppConstants.audioAssetsDir}${audioFile.filePath}';
      
      if (kDebugMode) {
        print('Playing audio from: $audioPath');
        print('Audio file details: ${audioFile.languageCode}/${audioFile.filePath}');
        print('Is web platform: ${PlatformUtils.isWeb}');
      }
      
      // Load the audio
      await _audioPlayer!.setAsset(audioPath);
      
      // Check if audio loaded successfully
      final duration = await _audioPlayer!.duration;
      if (kDebugMode) {
        print('Audio duration: $duration');
      }
      
      // Play the audio
      await _audioPlayer!.play();
      
      // Note: We don't need to wait for completion here anymore
      // as we're handling it in the playerStateStream listener in initState
    } catch (e) {
      if (kDebugMode) {
        print('Error playing audio: $e');
      }
      
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not play audio: ${e.toString().split('\n')[0]}'),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      
      if (_isMounted) {
        setState(() {
          _isPlaying = false;
          _playbackProgress = 0.0;
        });
      }
    }
  }
}