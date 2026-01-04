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
  const SiteInitializationException(super.message, [super.cause, super.stackTrace]);
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
