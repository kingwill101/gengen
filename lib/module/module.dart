/// Module versioning system for GenGen themes and plugins
///
/// Provides Hugo-style module management with support for:
/// - Local path modules
/// - Git repository modules
/// - pub.dev package modules
/// - Version constraints and lockfiles
library;

export 'module_cache.dart';
export 'module_import.dart';
export 'module_lockfile.dart';
export 'module_manifest.dart';
export 'module_resolver.dart';
export 'module_source.dart';
export 'sources.dart';
export 'version_constraint.dart';
