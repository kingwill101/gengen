/// # GenGen Exception Classes
///
/// This file defines custom exception classes used throughout the GenGen library
/// to provide meaningful error messages and enable proper error handling.
library;

/// Base exception class for all GenGen-specific errors.
class GenGenException implements Exception {
  final String message;
  final dynamic cause;
  final StackTrace? stackTrace;

  const GenGenException(this.message, [this.cause, this.stackTrace]);

  @override
  String toString() {
    if (cause != null) {
      return 'GenGenException: $message\nCaused by: $cause';
    }
    return 'GenGenException: $message';
  }
}

/// Exception thrown when site initialization fails.
class SiteInitializationException extends GenGenException {
  const SiteInitializationException(
    super.message, [
    super.cause,
    super.stackTrace,
  ]);
}

/// Exception thrown when site building/generation fails.
class SiteBuildException extends GenGenException {
  const SiteBuildException(super.message, [super.cause, super.stackTrace]);
}

/// Exception thrown when configuration is invalid.
class ConfigurationException extends GenGenException {
  const ConfigurationException(super.message, [super.cause, super.stackTrace]);
}

/// Exception thrown when plugin operations fail.
class PluginException extends GenGenException {
  const PluginException(super.message, [super.cause, super.stackTrace]);
}

/// Exception thrown when template rendering fails.
class TemplateException extends GenGenException {
  const TemplateException(super.message, [super.cause, super.stackTrace]);
}

/// Exception thrown when file system operations fail.
class FileSystemException extends GenGenException {
  const FileSystemException(super.message, [super.cause, super.stackTrace]);
}

/// Exception thrown when module operations fail.
class ModuleException extends GenGenException {
  const ModuleException(super.message, [super.cause, super.stackTrace]);

  @override
  String toString() {
    if (cause != null) {
      return 'ModuleException: $message\nCaused by: $cause';
    }
    return 'ModuleException: $message';
  }
}

/// Exception thrown when version parsing or constraint matching fails.
class VersionException extends ModuleException {
  final String? version;
  final String? constraint;

  VersionException(
    String message, {
    this.version,
    this.constraint,
    dynamic cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  @override
  String toString() {
    final parts = <String>['VersionException: $message'];
    if (version != null) parts.add('  Version: $version');
    if (constraint != null) parts.add('  Constraint: $constraint');
    if (cause != null) parts.add('  Caused by: $cause');
    return parts.join('\n');
  }
}

/// Exception thrown when module resolution fails.
class ModuleResolutionException extends ModuleException {
  final String modulePath;

  ModuleResolutionException(
    String message, {
    required this.modulePath,
    dynamic cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  @override
  String toString() {
    final parts = <String>['ModuleResolutionException: $message'];
    parts.add('  Module: $modulePath');
    if (cause != null) parts.add('  Caused by: $cause');
    return parts.join('\n');
  }
}

/// Exception thrown when module fetching fails.
class ModuleFetchException extends ModuleException {
  final String modulePath;
  final String? source;

  ModuleFetchException(
    String message, {
    required this.modulePath,
    this.source,
    dynamic cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  @override
  String toString() {
    final parts = <String>['ModuleFetchException: $message'];
    parts.add('  Module: $modulePath');
    if (source != null) parts.add('  Source: $source');
    if (cause != null) parts.add('  Caused by: $cause');
    return parts.join('\n');
  }
}

/// Exception thrown when lockfile operations fail.
class LockfileException extends ModuleException {
  final String? lockfilePath;

  LockfileException(
    String message, {
    this.lockfilePath,
    dynamic cause,
    StackTrace? stackTrace,
  }) : super(message, cause, stackTrace);

  @override
  String toString() {
    final parts = <String>['LockfileException: $message'];
    if (lockfilePath != null) parts.add('  Lockfile: $lockfilePath');
    if (cause != null) parts.add('  Caused by: $cause');
    return parts.join('\n');
  }
}
