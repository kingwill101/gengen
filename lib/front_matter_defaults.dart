import 'package:gengen/site.dart';
import 'package:gengen/utilities.dart';
import 'package:glob/glob.dart';

class FrontMatterDefaults {
  FrontMatterDefaults(List<dynamic>? defaults)
    : _defaults = _normalize(defaults);

  final List<Map<String, dynamic>> _defaults;

  Map<String, dynamic> resolve({required List<String> paths, String? type}) {
    Map<String, dynamic> resolved = {};
    final normalizedPaths = paths.map(_normalizePath).toList();

    for (final entry in _defaults) {
      final scope = _asMap(entry['scope']);
      final values = _asMap(entry['values']);
      if (values.isEmpty) continue;

      final scopeType = scope['type']?.toString();
      if (scopeType != null && scopeType.isNotEmpty) {
        if (type == null || scopeType != type) {
          continue;
        }
      }

      final scopePath = scope['path']?.toString() ?? '';
      if (!_matchesPath(scopePath, normalizedPaths)) continue;

      resolved = deepMerge(resolved, values);
    }

    return resolved;
  }

  static List<Map<String, dynamic>> _normalize(List<dynamic>? defaults) {
    if (defaults == null) return <Map<String, dynamic>>[];

    final normalized = <Map<String, dynamic>>[];
    for (final entry in defaults) {
      if (entry is Map) {
        normalized.add(Map<String, dynamic>.from(entry));
      }
    }
    return normalized;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String _normalizePath(String path) {
    var normalized = path.replaceAll('\\', '/');
    if (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }

  static bool _matchesPath(String scopePath, List<String> paths) {
    final normalizedScope = _stripCollectionsDir(_normalizePath(scopePath));
    if (normalizedScope.isEmpty || normalizedScope == '.') {
      return true;
    }

    if (normalizedScope.contains('*')) {
      final glob = Glob(normalizedScope);
      for (final candidate in paths) {
        if (glob.matches(candidate)) {
          return true;
        }
      }
      return false;
    }

    for (final candidate in paths) {
      if (candidate == normalizedScope) return true;
      if (candidate.startsWith('$normalizedScope/')) return true;
    }

    return false;
  }

  static String _stripCollectionsDir(String path) {
    final collectionsDir =
        site.config.get<String>('collections_dir', defaultValue: '') ?? '';
    if (collectionsDir.isEmpty) return path;
    if (path.startsWith('$collectionsDir/')) {
      return path.substring(collectionsDir.length + 1);
    }
    return path;
  }
}
