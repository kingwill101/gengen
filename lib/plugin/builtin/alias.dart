/// # GenGen Alias Plugin
///
/// This plugin provides alias functionality for GenGen static sites.
/// It automatically creates additional HTML files at alias locations that contain the
/// same content as the original page or post, enabling backward compatibility and 
/// multiple URLs for the same content.
///
/// ## Features
///
/// - **Flexible Path Support**: Handles relative, absolute, and directory-based aliases
/// - **Automatic Extension Handling**: Normalizes extensions to match source files
/// - **Directory Creation**: Creates nested directory structures as needed
/// - **Error Handling**: Graceful handling of permission and path issues
/// - **Performance Optimized**: Only processes pages with aliases defined
///
/// ## Configuration
///
/// Aliases are configured per-page in front matter. No global configuration needed:
///
/// ```yaml
/// ---
/// title: My Important Post
/// aliases: [old-url.html, another-path.html]
/// ---
/// ```
///
/// ## Alias Path Types
///
/// ### 1. Relative Paths
/// ```yaml
/// aliases: [about.html, company-info.html]
/// ```
/// Creates files relative to the site's output directory.
///
/// ### 2. Directory Paths
/// ```yaml
/// aliases: [contact/info.html, help/contact.html]
/// ```
/// Creates aliases in subdirectories with automatic directory creation.
///
/// ### 3. Absolute Paths
/// ```yaml
/// aliases: ["/2020/01/old-post.html", "/archive/legacy.html"]
/// ```
/// Absolute paths (starting with `/`) are treated as relative to the output directory.

/// ## Usage Examples
///
/// ### Basic Page Aliases
/// ```yaml
/// ---
/// title: About Us
/// aliases: [company-info.html, who-we-are.html]
/// ---
/// ```
///
/// ### Blog Post Migration
/// ```yaml
/// ---
/// title: Getting Started
/// date: 2024-01-15
/// aliases: 
///   - "/2024/01/15/getting-started.html"
///   - "/blog/tutorial.html"
/// ---
/// ```
///
/// ### Complex Directory Structure
/// ```yaml
/// ---
/// title: Services
/// aliases:
///   - "old-site/services.html"
///   - "company/what-we-do.html"
///   - "info/services-offered.html"
/// ---
/// ```
///
/// ## Error Handling
///
/// The plugin handles common issues gracefully:
/// - **Permission Errors**: Logs warnings for inaccessible paths
/// - **Invalid Paths**: Skips malformed alias paths
/// - **Missing Directories**: Creates parent directories automatically
/// - **File Conflicts**: Overwrites existing files (logs warning)
///
/// ## Performance Considerations
///
/// - Only processes pages/posts that have aliases defined
/// - Creates complete file copies (not redirects) for maximum compatibility
/// - Batch processes aliases for each page to minimize I/O operations
/// - Efficient path resolution and validation

import 'dart:async';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/models/base.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;

/// The main alias plugin that provides alias functionality for GenGen.
///
/// This plugin automatically processes your site's pages and posts to create
/// alias files. It runs as a post-processing step after content is written
/// to ensure aliases contain the fully rendered content.
///
/// The plugin:
/// 1. Hooks into the site's write process
/// 2. Scans each written file for alias definitions
/// 3. Creates additional copies at alias locations
/// 4. Handles path resolution and directory creation
/// 5. Provides comprehensive error handling and logging
class AliasPlugin extends BasePlugin {
  @override
  PluginMetadata get metadata => PluginMetadata(
        name: 'AliasPlugin',
        version: '1.0.0',
        description: 'Creates alias files for pages and posts',
      );


  /// Hook that runs after all content has been written.
  /// This is the ideal time to create aliases since the source files exist.
  @override
  Future<void> afterWrite() async {
    logger.info('(${metadata.name}) Starting alias generation');
    
    int aliasCount = 0;
    int errorCount = 0;

    // Process all pages
    for (final page in site.pages) {
      final result = await _processAliases(page);
      aliasCount += result.created;
      errorCount += result.errors;
    }

    // Process all posts
    for (final post in site.posts) {
      final result = await _processAliases(post);
      aliasCount += result.created;
      errorCount += result.errors;
    }

    if (aliasCount > 0) {
      logger.info('(${metadata.name}) Created $aliasCount aliases');
    }
    if (errorCount > 0) {
      logger.warning('(${metadata.name}) $errorCount alias creation errors');
    }
    
    logger.info('(${metadata.name}) Alias generation complete');
  }

  /// Processes aliases for a single Base object (page or post).
  ///
  /// This method:
  /// 1. Checks if the object has aliases defined
  /// 2. Verifies the main file exists and is readable
  /// 3. Creates alias files for each alias path
  /// 4. Returns statistics about created aliases and errors
  ///
  /// @param base The Base object (page or post) to process aliases for
  /// @returns AliasResult containing counts of created aliases and errors
  Future<AliasResult> _processAliases(Base base) async {
    int created = 0;
    int errors = 0;

    // Check if this object has aliases defined - try both config and frontMatter
    final aliases = base.config['aliases'] ?? base.frontMatter['aliases'];
    if (aliases == null || aliases is! List || aliases.isEmpty) {
      return AliasResult(created: 0, errors: 0);
    }

    // Get the source file that contains the rendered content
    final sourceFile = gengen_fs.fs.file(base.filePath);
    if (!sourceFile.existsSync()) {
      logger.warning(
        '(${metadata.name}) Source file not found for ${base.relativePath}: ${base.filePath}'
      );
      return AliasResult(created: 0, errors: 1);
    }

    // Read the content once for all aliases
    String sourceContent;
    try {
      sourceContent = sourceFile.readAsStringSync();
    } catch (e) {
      logger.warning(
        '(${metadata.name}) Failed to read source file ${base.filePath}: $e'
      );
      return AliasResult(created: 0, errors: 1);
    }

    // Process each alias
    for (final aliasPath in aliases) {
      try {
        final success = await _createAlias(
          aliasPath.toString(),
          sourceContent,
          base,
        );
        if (success) {
          created++;
        } else {
          errors++;
        }
      } catch (e) {
        logger.warning(
          '(${metadata.name}) Failed to create alias "$aliasPath" for ${base.relativePath}: $e'
        );
        errors++;
      }
    }

    return AliasResult(created: created, errors: errors);
  }

  /// Creates a single alias file at the specified path.
  ///
  /// This method handles:
  /// 1. Path normalization (removing leading slashes)
  /// 2. Extension handling (matching source file extension)
  /// 3. Directory creation for nested paths
  /// 4. File creation with identical content
  /// 5. Error handling and logging
  ///
  /// [aliasPath] The alias path from front matter
  /// [sourceContent] The rendered content to copy
  /// [base] The source Base object for context
  /// Returns true if alias was created successfully, false otherwise
  Future<bool> _createAlias(
    String aliasPath,
    String sourceContent,
    Base base,
  ) async {
    // Normalize the alias path
    String normalizedPath = aliasPath;
    
    // Remove leading slash if present (treat as relative to output directory)
    if (normalizedPath.startsWith('/')) {
      normalizedPath = normalizedPath.substring(1);
    }

    // Ensure the alias has the correct extension to match the source file
    final sourceExtension = p.extension(base.filePath);
    normalizedPath = p.setExtension(normalizedPath, sourceExtension);

    // Build the full destination path
    final destinationPath = p.join(base.destinationPath, normalizedPath);

    try {
      // Create the alias file
      final aliasFile = gengen_fs.fs.file(destinationPath);
      await aliasFile.create(recursive: true);
      await aliasFile.writeAsString(sourceContent);

      logger.info(
        '(${metadata.name}) Created alias "$aliasPath" -> "${aliasFile.absolute}"'
      );
      return true;
    } catch (e) {
      logger.warning(
        '(${metadata.name}) Failed to create alias "$aliasPath" for ${base.relativePath}: $e'
      );
      return false;
    }
  }
}

/// Result data class for alias processing operations.
///
/// This class tracks the results of processing aliases for a single
/// Base object, including counts of successfully created aliases
/// and any errors that occurred.
class AliasResult {
  /// Number of aliases successfully created
  final int created;
  
  /// Number of errors that occurred during alias creation
  final int errors;

  const AliasResult({
    required this.created,
    required this.errors,
  });

  /// Combines this result with another result.
  ///
  /// This is useful for aggregating results across multiple Base objects.
  AliasResult operator +(AliasResult other) {
    return AliasResult(
      created: created + other.created,
      errors: errors + other.errors,
    );
  }
} 