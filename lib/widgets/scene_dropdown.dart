import 'package:flutter/material.dart';
import '../models/scenes_model.dart';

/// A dropdown widget for selecting the current scene
class SceneDropdown extends StatelessWidget {
  /// The currently selected scene index
  final int selectedSceneIndex;
  
  /// List of available scenes
  final List<Scene> availableScenes;
  
  /// Callback function when a scene is selected
  final Function(int) onSceneChanged;

  const SceneDropdown({
    super.key,
    required this.selectedSceneIndex,
    required this.availableScenes,
    required this.onSceneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButton<int>(
        value: selectedSceneIndex,
        onChanged: (int? newValue) {
          if (newValue != null) {
            onSceneChanged(newValue);
          }
        },
        underline: Container(
          height: 2,
          color: Theme.of(context).primaryColor,
        ),
        items: _buildSceneItems(),
      ),
    );
  }

  /// Builds dropdown items for each scene
  List<DropdownMenuItem<int>> _buildSceneItems() {
    return List.generate(
      availableScenes.length,
      (index) => DropdownMenuItem<int>(
        value: index,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library),
            const SizedBox(width: 8),
            Text(availableScenes[index].name),
          ],
        ),
      ),
    );
  }
}