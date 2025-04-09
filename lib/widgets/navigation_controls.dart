import 'package:flutter/material.dart';

/// Widget that displays navigation controls for moving between scenes
class NavigationControls extends StatelessWidget {
  /// Current scene index
  final int currentIndex;
  
  /// Total number of scenes
  final int totalScenes;
  
  /// Callback for previous button
  final VoidCallback? onPrevious;
  
  /// Callback for next button
  final VoidCallback? onNext;

  const NavigationControls({
    super.key,
    required this.currentIndex,
    required this.totalScenes,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous button
          ElevatedButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: onPrevious == null
                  ? Colors.grey
                  : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          
          // Scene counter
          Text(
            'Scene ${currentIndex + 1} of $totalScenes',
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Next button
          ElevatedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: onNext == null
                  ? Colors.grey
                  : Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}