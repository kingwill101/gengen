/// # GenGen Draft Plugin
///
/// This plugin provides comprehensive draft post functionality for GenGen static sites.
/// It handles draft posts that are stored in the `_draft` directory and provides 
/// filtering based on the `publish_drafts` configuration setting.
///
/// ## Features
///
/// - **Draft Directory Support**: Reads posts from the `_draft` directory
/// - **Configuration Control**: Respects the `publish_drafts` setting
/// - **Development Mode**: Easy toggling between draft and production builds
/// - **Draft Metadata**: Automatically marks draft posts with `draft: true`
/// - **Flexible Filtering**: Works with posts marked as draft in any directory
/// - **SEO Safe**: Excludes drafts from production builds by default
///
/// ## Configuration
///
/// Configure draft handling in your `config.yaml`:
///
/// ```yaml
/// # Draft configuration
/// publish_drafts: false        # Set to true to include drafts in build (default: false)
/// draft_dir: "_draft"          # Directory for draft posts (default: "_draft")
/// ```
///
/// ## Usage Scenarios
///
/// ### Development Mode
/// Set `publish_drafts: true` in your development config to preview drafts:
///
/// ```yaml
/// # config.development.yaml
/// publish_drafts: true
/// ```
///
/// ### Production Mode
/// Keep `publish_drafts: false` (default) to exclude drafts from production builds.
///
/// ## Draft Post Methods
///
/// ### Method 1: _draft Directory
/// Place your draft posts in the `_draft` directory:
///
/// ```
/// _draft/
///   - 2024-12-20-my-draft-post.md
///   - 2024-12-21-another-draft.md
/// ```
///
/// These posts will automatically be marked as drafts and handled according
/// to the `publish_drafts` setting.
///
/// ### Method 2: Front Matter Flag
/// Add `draft: true` to any post's front matter:
///
/// ```markdown
/// ---
/// title: My Draft Post
/// date: 2024-12-20
/// draft: true
/// ---
///
/// This post is marked as a draft.
/// ```
///
/// ## Template Integration
///
/// Draft posts are available in templates through the normal `site.posts` collection
/// when `publish_drafts: true`. You can also check if a post is a draft:
///
/// ```liquid
/// {% for post in site.posts %}
///   <article{% if post.draft %} class="draft"{% endif %}>
///     <h2>{{ post.title }}{% if post.draft %} (Draft){% endif %}</h2>
///     <p>{{ post.excerpt }}</p>
///   </article>
/// {% endfor %}
/// ```
///
/// ## Command Line Usage
///
/// ### Preview Drafts During Development
/// ```bash
/// gengen build --config config.development.yaml
/// ```
///
/// ### Production Build (Excludes Drafts)
/// ```bash
/// gengen build
/// ```
///
/// ## How It Works
///
/// 1. **Draft Reading**: During the `afterRead` phase, reads posts from the `_draft` directory
/// 2. **Draft Marking**: Automatically sets `draft: true` for posts in the draft directory
/// 3. **Draft Filtering**: During the `beforeRender` phase, filters drafts based on `publish_drafts` setting
/// 4. **Collection Management**: Manages draft posts in the site's post collection
///
/// ## Security Considerations
///
/// - Draft posts are excluded from production builds by default
/// - No draft content is accidentally published unless explicitly enabled
/// - Draft status is clearly marked in post metadata
///
/// ## Performance Notes
///
/// - Draft filtering happens before rendering, saving processing time
/// - Draft posts are not processed during production builds
/// - Memory usage is optimized by removing drafts early in the pipeline
///
/// ## Compatibility
///
/// This plugin is designed to be compatible with other static site generators:
/// - Uses standard `draft: true` front matter convention
/// - Follows common `_draft` directory naming
/// - Respects `publish_drafts` configuration pattern
///
/// ## See Also
///
/// - [GenGen Configuration](../../docs/configuration.md) - Full configuration options
/// - [Post Creation](../../docs/posts.md) - Guide to creating posts and drafts

import 'dart:async';
import 'package:gengen/fs.dart' as gengen_fs;
import 'package:gengen/models/base.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/readers/post_reader.dart';
import 'package:gengen/site.dart';
import 'package:path/path.dart' as p;

/// The main draft plugin that provides comprehensive draft post functionality.
///
/// This plugin handles both posts in the `_draft` directory and posts marked
/// with `draft: true` in their front matter. It provides filtering based on
/// the `publish_drafts` configuration setting.
///
/// ## Key Features:
/// - Reads draft posts from the configured draft directory
/// - Automatically marks draft directory posts as drafts
/// - Filters drafts based on configuration
/// - Integrates seamlessly with the existing post system
/// - Supports development and production modes
class DraftPlugin extends BasePlugin {
  /// List to track posts that were read from the draft directory
  final List<Base> _draftPosts = [];

  @override
  PluginMetadata get metadata => PluginMetadata(
    name: 'DraftPlugin',
    version: '1.0.0',
    description: 'Handles draft post functionality including reading from _draft directory and filtering',
  );

  /// Hook that runs after all content has been read.
  ///
  /// This method reads posts from the draft directory and adds them to the
  /// site's post collection with the appropriate draft metadata.
  @override
  Future<void> afterRead() async {
    logger.info('(${metadata.name}) Reading draft posts');

    final draftDir = site.config.get<String>('draft_dir', defaultValue: '_draft')!;
    
    // Check if draft directory exists
    final draftPath = site.inSourceDir(draftDir);
    if (!gengen_fs.fs.directory(draftPath).existsSync()) {
      logger.info('(${metadata.name}) No draft directory found at $draftPath');
      return;
    }

    // Read draft posts using the existing PostReader
    final postReader = PostReader();
    final draftPosts = postReader.readPosts(draftPath);
    
    if (draftPosts.isEmpty) {
      logger.info('(${metadata.name}) No draft posts found');
      return;
    }

    logger.info('(${metadata.name}) Found ${draftPosts.length} draft posts');

    // Mark all posts from draft directory as drafts
    for (final post in draftPosts) {
      // Set draft flag in front matter
      post.frontMatter['draft'] = true;
      
      // Add to our tracking list
      _draftPosts.add(post);
      
      logger.info('(${metadata.name}) Marked draft post: ${p.basename(post.source)}');
    }

    // Add draft posts to the existing posts collection
    final currentPosts = site.posts.toList(); // Get current posts
    currentPosts.addAll(draftPosts); // Add draft posts
    site.posts = currentPosts; // Set the combined list

    logger.info('(${metadata.name}) Draft reading complete');
  }

  /// Hook that runs before rendering begins.
  ///
  /// This method filters out draft posts if `publish_drafts` is false.
  /// It checks both posts from the draft directory and posts marked
  /// with `draft: true` in their front matter.
  @override
  Future<void> beforeRender() async {
    final publishDrafts = site.config.get<bool>('publish_drafts', defaultValue: false)!;
    
    if (publishDrafts) {
      logger.info('(${metadata.name}) Publishing drafts is enabled - keeping all draft posts');
      return;
    }

    logger.info('(${metadata.name}) Filtering out draft posts');

    // Count drafts before filtering
    final allDrafts = site.posts.where((post) => post.isDraft()).toList();
    final draftCount = allDrafts.length;

    if (draftCount == 0) {
      logger.info('(${metadata.name}) No draft posts to filter');
      return;
    }

    // Remove all draft posts from the site collection
    site.posts.removeWhere((post) => post.isDraft());

    logger.info('(${metadata.name}) Filtered out $draftCount draft posts');
    
    // Log which drafts were filtered for debugging
    for (final draft in allDrafts) {
      logger.info('(${metadata.name}) Filtered draft: ${p.basename(draft.source)}');
    }
  }

  /// Helper method to check if a post is considered a draft.
  ///
  /// A post is considered a draft if:
  /// 1. It has `draft: true` in its front matter, OR
  /// 2. It was read from the draft directory
  ///
  /// This method provides a centralized way to determine draft status.
  bool isPostDraft(Base post) {
    // Check front matter first
    if (post.isDraft()) {
      return true;
    }

    // Check if it's in our draft posts list
    return _draftPosts.contains(post);
  }

  /// Get the count of draft posts currently in the system.
  ///
  /// This includes both posts from the draft directory and posts
  /// marked with `draft: true` in their front matter.
  int get draftCount => site.posts.where((post) => post.isDraft()).length;

  /// Get all draft posts currently in the system.
  ///
  /// Returns a list of all posts that are considered drafts,
  /// regardless of their source (draft directory or front matter).
  List<Base> get drafts => site.posts.where((post) => post.isDraft()).toList();

  /// Reset the plugin's internal state.
  ///
  /// This method clears the internal tracking list of draft posts.
  /// Useful for testing and when reinitializing the site.
  void reset() {
    _draftPosts.clear();
  }
} 