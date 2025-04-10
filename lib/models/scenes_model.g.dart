// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scenes_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VocabularyData _$VocabularyDataFromJson(Map<String, dynamic> json) =>
    VocabularyData(
      title: json['title'] as String,
      description: json['description'] as String,
      supportedLanguages: (json['supportedLanguages'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      scenes: (json['scenes'] as List<dynamic>)
          .map((e) => Scene.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$VocabularyDataToJson(VocabularyData instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'supportedLanguages': instance.supportedLanguages,
      'scenes': instance.scenes,
    };

Scene _$SceneFromJson(Map<String, dynamic> json) => Scene(
      id: json['id'] as String,
      name: json['name'] as String,
      imagePath: json['imagePath'] as String?,
      imageLayers: (json['imageLayers'] as List<dynamic>?)
          ?.map((e) => ImageLayer.fromJson(e as Map<String, dynamic>))
          .toList(),
      interactionPoints: (json['interactionPoints'] as List<dynamic>)
          .map((e) => InteractionPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SceneToJson(Scene instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'imagePath': instance.imagePath,
      'imageLayers': instance.imageLayers,
      'interactionPoints': instance.interactionPoints,
    };

ImageLayer _$ImageLayerFromJson(Map<String, dynamic> json) => ImageLayer(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      zIndex: (json['zIndex'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ImageLayerToJson(ImageLayer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'imagePath': instance.imagePath,
      'opacity': instance.opacity,
      'x': instance.x,
      'y': instance.y,
      'scale': instance.scale,
      'zIndex': instance.zIndex,
    };

InteractionPoint _$InteractionPointFromJson(Map<String, dynamic> json) =>
    InteractionPoint(
      id: json['id'] as String,
      label: json['label'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      audioFiles: (json['audioFiles'] as List<dynamic>)
          .map((e) => AudioFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      translations: (json['translations'] as List<dynamic>)
          .map((e) => Translation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$InteractionPointToJson(InteractionPoint instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'x': instance.x,
      'y': instance.y,
      'audioFiles': instance.audioFiles,
      'translations': instance.translations,
    };

AudioFile _$AudioFileFromJson(Map<String, dynamic> json) => AudioFile(
      languageCode: json['languageCode'] as String,
      filePath: json['filePath'] as String,
    );

Map<String, dynamic> _$AudioFileToJson(AudioFile instance) => <String, dynamic>{
      'languageCode': instance.languageCode,
      'filePath': instance.filePath,
    };

Translation _$TranslationFromJson(Map<String, dynamic> json) => Translation(
      languageCode: json['languageCode'] as String,
      text: json['text'] as String,
    );

Map<String, dynamic> _$TranslationToJson(Translation instance) =>
    <String, dynamic>{
      'languageCode': instance.languageCode,
      'text': instance.text,
    };
