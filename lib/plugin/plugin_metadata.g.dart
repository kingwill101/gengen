// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PluginMetadataImpl _$$PluginMetadataImplFromJson(Map<String, dynamic> json) =>
    _$PluginMetadataImpl(
      name: json['name'] as String,
      entrypoint: json['entrypoint'] as String? ?? "plugin:Plugin",
      url: json['url'] as String?,
      path: json['path'] as String?,
      description: json['description'] as String?,
      author: json['author'] as String?,
      authorUrl: json['authorUrl'] as String?,
      license: json['license'] as String?,
      version: json['version'] as String?,
      include:
          (json['include'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      files:
          (json['files'] as List<dynamic>?)
              ?.map((e) => PluginAsset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$PluginMetadataImplToJson(
  _$PluginMetadataImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'entrypoint': instance.entrypoint,
  'url': instance.url,
  'path': instance.path,
  'description': instance.description,
  'author': instance.author,
  'authorUrl': instance.authorUrl,
  'license': instance.license,
  'version': instance.version,
  'include': instance.include,
  'files': instance.files,
};

_$PluginAssetImpl _$$PluginAssetImplFromJson(Map<String, dynamic> json) =>
    _$PluginAssetImpl(
      name: json['name'] as String,
      path: json['path'] as String,
    );

Map<String, dynamic> _$$PluginAssetImplToJson(_$PluginAssetImpl instance) =>
    <String, dynamic>{'name': instance.name, 'path': instance.path};
