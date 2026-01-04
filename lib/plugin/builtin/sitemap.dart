import 'package:gengen/models/base.dart';
import 'package:gengen/plugin/plugin.dart';
import 'package:gengen/plugin/plugin_metadata.dart';
import 'package:gengen/site.dart';
import 'package:gengen/fs.dart';
import 'package:path/path.dart' as p;

/// Sitemap Generator Plugin for GenGen
///
/// Generates an XML sitemap following the sitemap.org protocol.
/// Includes all pages and posts with their URLs, last modified dates,
/// change frequencies, and priorities.
class SitemapPlugin extends BasePlugin {
  /// The output file path for the sitemap
  final String outputPath;
  
  /// Default change frequency for posts
  final String defaultPostChangeFreq;
  
  /// Default change frequency for pages
  final String defaultPageChangeFreq;
  
  /// Default priority for posts
  final double defaultPostPriority;
  
  /// Default priority for pages
  final double defaultPagePriority;

  SitemapPlugin({
    this.outputPath = "sitemap.xml",
    this.defaultPostChangeFreq = "weekly",
    this.defaultPageChangeFreq = "monthly",
    this.defaultPostPriority = 0.7,
    this.defaultPagePriority = 0.5,
  });

  @override
  PluginMetadata get metadata => PluginMetadata(
        name: 'SitemapPlugin',
        version: '1.0.0',
        description: 'Generates XML sitemap for all site content',
      );

  @override
  Future<void> afterRender() async {
    try {
      logger.info('(${metadata.name}) Generating sitemap');
      
      final site = Site.instance;
      
      // Collect all content: posts and pages (exclude drafts)
      final allContent = <Base>[];
      
      // Add posts (exclude drafts and index pages)
      allContent.addAll(
        site.posts.where((post) => !post.isDraft() && !post.isIndex)
      );
      
      // Add pages (exclude index pages that are just post listings)
      allContent.addAll(
        site.pages.where((page) => !page.isDraft())
      );

      if (allContent.isEmpty) {
        logger.info('(${metadata.name}) No content found for sitemap');
        return;
      }

      // Generate sitemap XML
      final sitemapContent = _generateSitemapXml(site, allContent);
      
      // Write sitemap file
      final outputFile = p.join(site.destination.path, outputPath);
      final file = await fs.file(outputFile).create(recursive: true);
      await file.writeAsString(sitemapContent);
      
      logger.info('(${metadata.name}) Sitemap generated at $outputPath with ${allContent.length} entries');
    } catch (e) {
      logger.severe('(${metadata.name}) Failed to generate sitemap: $e');
    }
  }

  String _generateSitemapXml(Site site, List<Base> content) {
    final config = site.config;
    final siteUrl = config.get<String>('url') ?? 'http://localhost:4000';
    
    final buffer = StringBuffer();
    
    // XML declaration and urlset opening
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">');
    
    // Add home page entry
    buffer.writeln('  <url>');
    buffer.writeln('    <loc>$siteUrl/</loc>');
    buffer.writeln('    <changefreq>daily</changefreq>');
    buffer.writeln('    <priority>1.0</priority>');
    buffer.writeln('  </url>');
    
    // Add entries for each piece of content
    for (final item in content) {
      final loc = '$siteUrl/${item.link()}';
      final changefreq =
          item.isPost ? defaultPostChangeFreq : defaultPageChangeFreq;
      final priority =
          item.isPost ? defaultPostPriority : defaultPagePriority;
      
      buffer.writeln('  <url>');
      buffer.writeln('    <loc>${_escapeXml(loc)}</loc>');
      buffer.writeln('    <changefreq>${_escapeXml(changefreq)}</changefreq>');
      buffer.writeln('    <priority>${priority.toStringAsFixed(1)}</priority>');
      buffer.writeln('  </url>');
    }
    
    // Close urlset
    buffer.writeln('</urlset>');
    
    return buffer.toString();
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
} 
