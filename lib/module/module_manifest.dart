import 'package:gengen/module/module_import.dart';

/// Parses and represents the `module` section from gengen.yaml
class ModuleManifest {
  final List<ModuleImport> imports;
  final List<ModuleReplacement> replacements;

  const ModuleManifest({this.imports = const [], this.replacements = const []});

  factory ModuleManifest.parse(Map<String, dynamic>? moduleSection) {
    if (moduleSection == null) {
      return const ModuleManifest();
    }

    final rawImports = moduleSection['imports'] as List<dynamic>? ?? [];
    final rawReplacements =
        moduleSection['replacements'] as List<dynamic>? ?? [];

    final imports = rawImports
        .whereType<Map<String, dynamic>>()
        .map(ModuleImport.parse)
        .toList();

    final replacements = rawReplacements
        .whereType<Map<String, dynamic>>()
        .map(ModuleReplacement.parse)
        .toList();

    return ModuleManifest(imports: imports, replacements: replacements);
  }

  /// Check if a module path has a replacement defined
  String? getReplacementFor(String path) {
    for (final replacement in replacements) {
      if (replacement.path == path) {
        return replacement.local;
      }
    }
    return null;
  }

  /// Check if manifest has any module imports
  bool get hasImports => imports.isNotEmpty;

  /// Check if manifest is empty (no imports or replacements)
  bool get isEmpty => imports.isEmpty && replacements.isEmpty;

  Map<String, dynamic> toJson() => {
    'imports': imports.map((i) => i.toJson()).toList(),
    'replacements': replacements.map((r) => r.toJson()).toList(),
  };
}
