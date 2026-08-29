import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/scenes_model.dart';
import '../utils/app_logger.dart';
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

class _VocabularyCardState extends State<VocabularyCard>
    with SingleTickerProviderStateMixin {
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

  /// Whether the configured pronunciation file exists in the bundled assets.
  bool _audioAssetAvailable = false;

  /// Whether the asset availability check is still in progress.
  bool _checkingAudioAsset = true;

  /// Identifies the latest audio availability check so stale async results
  /// cannot overwrite the state for a newly selected language or item.
  int _audioCheckGeneration = 0;

  @override
  void initState() {
    super.initState();

    // Initialize audio player only if supported on this platform
    if (_isAudioSupported) {
      _audioPlayer = AudioPlayer();

      // Listen for audio player state changes
      _audioPlayer!.playerStateStream.listen(
        (state) {
          if (!_isMounted) return;

          if (state.processingState == ProcessingState.completed ||
              state.processingState == ProcessingState.idle) {
            setState(() {
              _isPlaying = false;
              _playbackProgress = 0.0;
            });
          }
        },
        onError: (error) {
          if (kDebugMode) {
            AppLogger.debug('Audio player error: $error');
          }
          if (_isMounted) {
            setState(() {
              _isPlaying = false;
              _playbackProgress = 0.0;
            });
          }
        },
      );

      // Listen for position updates to track progress
      _audioPlayer!.positionStream.listen((position) {
        if (!_isMounted || !_isPlaying) return;

        final duration = _audioPlayer!.duration;
        if (duration != null && _isMounted) {
          setState(() {
            _playbackProgress =
                position.inMilliseconds / duration.inMilliseconds;
          });
        }
      });
    }

    _checkAudioAsset();

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
  void didUpdateWidget(covariant VocabularyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLanguage != widget.currentLanguage ||
        oldWidget.interactionPoint != widget.interactionPoint) {
      // The player may still contain (or be playing) the previous language's
      // asset. Reset it immediately so changing language cannot leave the
      // popup speaking the old pronunciation.
      _audioCheckGeneration++;
      _audioPlayer?.stop();
      if (_isMounted) {
        setState(() {
          _isPlaying = false;
          _playbackProgress = 0.0;
        });
      }
      _checkAudioAsset();
    }
  }

  /// Check the actual bundled asset instead of trusting the JSON entry.
  /// This lets the UI warn about missing files before the user presses Listen.
  Future<void> _checkAudioAsset() async {
    final checkGeneration = _audioCheckGeneration;
    final audioFile = _getAudioFile();
    if (audioFile == null) {
      if (_isMounted && checkGeneration == _audioCheckGeneration) {
        setState(() {
          _checkingAudioAsset = false;
          _audioAssetAvailable = false;
        });
      }
      return;
    }

    final path = _audioAssetPath(audioFile);
    if (_isMounted && checkGeneration == _audioCheckGeneration) {
      setState(() {
        _checkingAudioAsset = true;
        _audioAssetAvailable = false;
      });
    }

    try {
      await rootBundle.load(path);
      if (_isMounted && checkGeneration == _audioCheckGeneration) {
        setState(() {
          _checkingAudioAsset = false;
          _audioAssetAvailable = true;
        });
      }
    } catch (_) {
      // Some Flutter web asset loaders do not expose binary files through
      // rootBundle consistently until after startup. The generated manifest
      // is bundled alongside the audio files, so use it as a fallback.
      try {
        final manifest = jsonDecode(
          await rootBundle.loadString('assets/audio/manifest.json'),
        ) as Map<String, dynamic>;
        if (_isMounted && checkGeneration == _audioCheckGeneration) {
          setState(() {
            _checkingAudioAsset = false;
            _audioAssetAvailable = manifest.containsKey(audioFile.filePath);
          });
        }
      } catch (_) {
        if (_isMounted && checkGeneration == _audioCheckGeneration) {
          setState(() {
            _checkingAudioAsset = false;
            // The JSON entry is still useful as a last-resort signal when
            // the web asset manifest itself is unavailable. Playback will
            // provide the actionable error if the file is genuinely absent.
            _audioAssetAvailable = audioFile.filePath.isNotEmpty;
          });
        }
      }
    }
  }

  String _audioAssetPath(AudioFile audioFile) {
    return PlatformUtils.isWeb
        ? 'assets/audio/${audioFile.filePath}'
        : '${AppConstants.audioAssetsDir}${audioFile.filePath}';
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
                      child: _buildCurrentWord(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        AppLogger.debug('Close button pressed');
                        widget.onClose();
                        AppLogger.debug('onClose callback executed');
                      },
                      tooltip: 'Close',
                    ),
                  ],
                ),

                const Divider(),

                // Always show pronunciation status so missing files are visible
                // before the user tries to play them.
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _buildAudioSection(context),
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
                            .where(
                              (t) => t.languageCode != widget.currentLanguage,
                            )
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

  Widget _buildCurrentWord() {
    final translation = widget.interactionPoint.translations.firstWhere(
      (t) => t.languageCode == widget.currentLanguage,
      orElse: () => Translation(
        languageCode: widget.currentLanguage,
        text: widget.interactionPoint.label,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          translation.text,
          style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        if (translation.ipa != null && translation.ipa!.isNotEmpty)
          Text(
            'IPA: [${translation.ipa}]',
            style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
          ),
      ],
    );
  }

  /// Builds a translation item for the list
  Widget _buildTranslationItem(Translation translation) {
    final langName =
        AppConstants.languageNames[translation.languageCode] ??
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(translation.text),
                if (translation.ipa != null && translation.ipa!.isNotEmpty)
                  Text(
                    'IPA: [${translation.ipa}]',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSection(BuildContext context) {
    if (_checkingAudioAsset) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.volume_up_outlined),
        title: Text('Checking pronunciation…'),
      );
    }

    if (!_isAudioSupported) {
      return _audioStatus(
        icon: Icons.volume_off_outlined,
        title: 'Pronunciation unavailable on this platform',
        detail: 'Audio playback is not supported on Linux yet.',
        color: Colors.grey,
      );
    }

    if (!_audioAssetAvailable) {
      return _audioStatus(
        icon: Icons.warning_amber_rounded,
        title: 'Pronunciation not available yet',
        detail: 'An audio file has not been bundled for this language.',
        color: Colors.orange.shade800,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tooltip(
          message: _isPlaying ? 'Stop pronunciation' : 'Play pronunciation',
          child: Semantics(
            button: true,
            label: _isPlaying ? 'Stop pronunciation' : 'Play pronunciation',
            child: ElevatedButton.icon(
              onPressed: _playAudio,
              icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up),
              label: Text(_isPlaying ? 'Stop' : 'Listen'),
            ),
          ),
        ),
        if (_isPlaying)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Semantics(
              label: 'Pronunciation playback progress',
              value: '${(_playbackProgress * 100).round()} percent',
              child: LinearProgressIndicator(
                value: _playbackProgress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _audioStatus({
    required IconData icon,
    required String title,
    required String detail,
    required Color color,
  }) {
    return Semantics(
      liveRegion: true,
      label: '$title. $detail',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 3),
                  Text(detail, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
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
          content: const Text(
            'Audio playback is not supported on this platform',
          ),
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
        AppLogger.debug(
          'No audio file available for language: ${widget.currentLanguage}',
        );
      }
      return;
    }

    setState(() {
      _isPlaying = true;
    });

    try {
      // Get the appropriate audio file path based on platform
      final audioPath = _audioAssetPath(audioFile);

      if (kDebugMode) {
        AppLogger.debug('Playing audio from: $audioPath');
        AppLogger.debug(
          'Audio file details: ${audioFile.languageCode}/${audioFile.filePath}',
        );
        AppLogger.debug('Is web platform: ${PlatformUtils.isWeb}');
      }

      // Load the audio
      await _audioPlayer!.setAsset(audioPath);

      // Check if audio loaded successfully
      final duration = _audioPlayer!.duration;
      if (kDebugMode) {
        AppLogger.debug('Audio duration: $duration');
      }

      // Play the audio
      await _audioPlayer!.play();

      // Note: We don't need to wait for completion here anymore
      // as we're handling it in the playerStateStream listener in initState
    } catch (e) {
      if (kDebugMode) {
        AppLogger.debug('Error playing audio: $e');
      }

      // Show error message to user
      if (!mounted) return;
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
