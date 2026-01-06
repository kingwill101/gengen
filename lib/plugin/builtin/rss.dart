import 'package:gengen/configuration.dart';
import 'package:gengen/models/base.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/site.dart';
import 'package:gengen/fs.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

/// RSS Feed Generator Plugin for GenGen
///
/// Generates an RSS 2.0 feed from the site's posts, making it easy for users
/// to subscribe to content updates. The feed includes post titles, descriptions,
/// publication dates, and links.
class RssPlugin extends BasePlugin {
  /// The output file path for the RSS feed
  final String outputPath;

  /// Maximum number of posts to include in the feed
  final int maxPosts;

  /// Whether to include the full post content or just excerpts
  final bool includeFullContent;

  RssPlugin({
    this.outputPath = "feed.xml",
    this.maxPosts = 20,
    this.includeFullContent = false,
  });

  @override
  PluginMetadata get metadata => PluginMetadata(
    name: 'RssPlugin',
    version: '1.0.0',
    description: 'Generates RSS 2.0 feed from site posts',
  );

  @override
  Future<void> afterRender() async {
    try {
      logger.info('(${metadata.name}) Generating RSS feed');

      final site = Site.instance;
      final config = site.config;

      // Get posts to include in RSS feed
      final posts =
          site.posts.where((post) => post.isPost && !post.isDraft()).toList()
            ..sort((a, b) => b.date.compareTo(a.date));

      final postsToInclude = posts.take(maxPosts).toList();

      if (postsToInclude.isEmpty) {
        logger.warning('(${metadata.name}) No posts found for RSS feed');
        return;
      }

      // Generate RSS XML
      final rssXml = _generateRssXml(config, postsToInclude);

      // Write RSS feed to output directory
      final outputFile = fs.file(p.join(config.destination, outputPath));
      await outputFile.create(recursive: true);
      await outputFile.writeAsString(rssXml);

      logger.info('(${metadata.name}) RSS feed generated at $outputPath');
    } catch (e, stackTrace) {
      logger.severe('(${metadata.name}) Failed to generate RSS feed: $e');
      logger.severe('Stack trace: $stackTrace');
    }
  }

  /// Generates RSS 2.0 compliant XML
  String _generateRssXml(Configuration config, List<Base> posts) {
    final siteTitle = config.get<String>('title') ?? 'GenGen Site';
    final siteDescription =
        config.get<String>('description') ?? 'A GenGen powered site';
    final siteUrl = config.get<String>('url') ?? 'http://localhost:4000';

    final buffer = StringBuffer();

    // XML declaration and RSS opening
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">',
    );
    buffer.writeln('  <channel>');

    // Channel metadata
    buffer.writeln('    <title>${_escapeXml(siteTitle)}</title>');
    buffer.writeln(
      '    <description>${_escapeXml(siteDescription)}</description>',
    );
    buffer.writeln('    <link>$siteUrl</link>');
    buffer.writeln(
      '    <atom:link href="$siteUrl/$outputPath" rel="self" type="application/rss+xml" />',
    );
    buffer.writeln('    <generator>GenGen Static Site Generator</generator>');
    buffer.writeln('    <language>en</language>');
    buffer.writeln('    <pubDate>${_formatRssDate(DateTime.now())}</pubDate>');
    buffer.writeln(
      '    <lastBuildDate>${_formatRssDate(DateTime.now())}</lastBuildDate>',
    );

    // Add items
    for (final post in posts) {
      buffer.writeln('    <item>');
      final postConfig = post.config;
      final title = postConfig['title']?.toString() ?? 'Untitled';
      buffer.writeln('      <title>${_escapeXml(title)}</title>');

      final postUrl = '$siteUrl${post.link()}';
      buffer.writeln('      <link>$postUrl</link>');
      buffer.writeln('      <guid isPermaLink="true">$postUrl</guid>');

      // Description (content or excerpt)
      String? description;
      if (includeFullContent && post.content.isNotEmpty) {
        description = post.content;
      } else {
        final excerpt = postConfig['excerpt']?.toString();
        if (excerpt != null && excerpt.isNotEmpty) {
          description = excerpt;
        } else if (post.content.isNotEmpty) {
          description = _generateExcerpt(post.content);
        }
      }

      if (description != null && description.isNotEmpty) {
        buffer.writeln(
          '      <description>${_escapeXml(description)}</description>',
        );
      }

      // Publication date
      buffer.writeln('      <pubDate>${_formatRssDate(post.date)}</pubDate>');

      // Author
      final author = postConfig['author']?.toString();
      if (author != null && author.isNotEmpty) {
        buffer.writeln('      <author>${_escapeXml(author)}</author>');
      }

      // Categories
      final categories = postConfig['categories'];
      if (categories is List) {
        for (final category in categories.cast<Object?>()) {
          buffer.writeln(
            '      <category>${_escapeXml(category.toString())}</category>',
          );
        }
      }

      buffer.writeln('    </item>');
    }

    // Close RSS
    buffer.writeln('  </channel>');
    buffer.writeln('</rss>');

    return buffer.toString();
  }

  /// Formats a DateTime for RSS pubDate format (RFC 822)
  String _formatRssDate(DateTime dateTime) {
    // RSS uses RFC 822 date format: "Wed, 02 Oct 2002 15:00:00 +0000"
    final formatter = DateFormat('EEE, dd MMM yyyy HH:mm:ss');
    return '${formatter.format(dateTime.toUtc())} +0000';
  }

  /// Escapes XML special characters
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Generates an excerpt from content
  String _generateExcerpt(String content, {int maxLength = 200}) {
    // Remove HTML tags and markdown formatting
    final cleaned = content
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[#*_`\[\]()]'), '') // Remove markdown characters
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();

    if (cleaned.length <= maxLength) return cleaned;

    final truncated = cleaned.substring(0, maxLength);
    final lastSpace = truncated.lastIndexOf(' ');
    return lastSpace > 0
        ? '${truncated.substring(0, lastSpace)}...'
        : '$truncated...';
  }
}
