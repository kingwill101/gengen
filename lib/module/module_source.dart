import 'package:gengen/module/module_import.dart';

/// Represents a resolved module ready to be used
class ResolvedModule {
  final ModuleImport import_;
  final String resolvedPath;
  final String resolvedVersion;
  final String? sha;
  final ModuleSource source;

  const ResolvedModule({
    required this.import_,
    required this.resolvedPath,
    required this.resolvedVersion,
    this.sha,
    required this.source,
  });

  /// The module path (original import path)
  String get path => import_.path;

  /// The module name
  String get name => import_.name;

  /// The module type
  ModuleType get type => import_.type;

  @override
  String toString() =>
      'ResolvedModule($path@$resolvedVersion -> $resolvedPath)';
}

/// Indicates the source type of a resolved module
enum ModuleSource { local, gitCache, pubCache, replacement }

/// Base class for module source handlers
abstract class ModuleSourceHandler {
  /// Check if this handler can resolve the given import
  bool canHandle(ModuleImport import_);

  /// Resolve the module and return its local path
  Future<ResolvedModule?> resolve(
    ModuleImport import_, {
    String? lockVersion,
    String? lockSha,
  });

  /// Fetch/update the module to the cache
  Future<ResolvedModule?> fetch(ModuleImport import_);

  /// List available versions for the module
  Future<List<String>> listVersions(ModuleImport import_);
}
