import 'package:freezed_annotation/freezed_annotation.dart';
part 'plugin_metadata.freezed.dart';
part 'plugin_metadata.g.dart';

@freezed
abstract class PluginMetadata with _$PluginMetadata {
  const factory PluginMetadata({
    required String name,
    @Default("plugin:Plugin") String entrypoint,
    String? url,
    String? path,
    String? description,
    String? author,
    String? authorUrl,
    String? license,
    String? version,
    @Default([]) List<String> include,
    @Default([]) List<PluginAsset> files,
  }) = _PluginMetadata;

  factory PluginMetadata.fromJson(Map<String, Object?> json) =>
      _$PluginMetadataFromJson(json);
}

@freezed
abstract class PluginAsset with _$PluginAsset {
  const factory PluginAsset({required String name, required String path}) =
      _PluginAsset;

  factory PluginAsset.fromJson(Map<String, Object?> json) =>
      _$PluginAssetFromJson(json);
}
