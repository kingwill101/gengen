# RSS & Sitemap Demo

This example demonstrates the automatic RSS feed and XML sitemap generation capabilities of GenGen.

## Features Demonstrated

### RSS Feed Generation (`RssPlugin`)
- **Output**: `/feed.xml`
- **Content**: RSS 2.0 feed with the 20 most recent posts
- **Metadata**: Includes titles, excerpts, publication dates, authors, and categories
- **Standards**: Follows RSS 2.0 specification for maximum compatibility

### Sitemap Generation (`SitemapPlugin`)
- **Output**: `/sitemap.xml`
- **Content**: XML sitemap listing all pages and posts
- **SEO Optimized**: Includes change frequencies, priorities, and last modified dates
- **Standards**: Follows sitemap.org protocol

## Files Overview

- `config.yaml` - Site configuration showing plugin usage
- `_posts/` - Sample blog posts that appear in RSS feed and sitemap
- `about.md` - Sample page with custom sitemap settings
- `index.html` - Homepage demonstrating content listing
- `_layouts/default.html` - Layout with RSS feed link in `<head>`

## Building the Demo

```bash
# From the GenGen root directory
cd examples/rss-sitemap-demo
gengen build
```

After building, check the `public/` directory for:
- `feed.xml` - The generated RSS feed
- `sitemap.xml` - The generated XML sitemap

## Generated Files

### RSS Feed Structure
```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>RSS & Sitemap Demo</title>
    <description>A demo site showcasing RSS feed and sitemap generation with GenGen</description>
    <link>https://example.com</link>
    <generator>GenGen</generator>
    <item>
      <title>RSS Feeds and Sitemaps Made Easy</title>
      <description>Discover how GenGen automatically generates RSS feeds...</description>
      <link>https://example.com/features/2024/01/20/rss-and-sitemap.html</link>
      <guid>https://example.com/features/2024/01/20/rss-and-sitemap.html</guid>
    </item>
    <!-- More items... -->
  </channel>
</rss>
```

### Sitemap Structure
```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <changefreq>daily</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://example.com/features/2024/01/20/rss-and-sitemap.html</loc>
    <changefreq>weekly</changefreq>
    <priority>0.7</priority>
  </url>
  <!-- More URLs... -->
</urlset>
```

## Customization Options

### RSS Plugin
```dart
RssPlugin(
  outputPath: 'my-feed.xml',  // Custom output path
  maxPosts: 50,               // Number of posts to include
)
```

### Sitemap Plugin
```dart
SitemapPlugin(
  outputPath: 'my-sitemap.xml',  // Custom output path
)
```

### Per-Page Sitemap Settings
Add to page front matter:
```yaml
---
title: My Page
sitemap_priority: 0.8      # Priority (0.0 to 1.0)
sitemap_changefreq: weekly # Change frequency
---
```

## SEO Benefits

Both plugins provide important SEO benefits:

1. **RSS Feeds**: Enable content syndication and user subscriptions
2. **XML Sitemaps**: Help search engines discover and index content efficiently
3. **Automatic Updates**: Both files update automatically when content changes
4. **Standards Compliance**: Follow established protocols for maximum compatibility

## Integration

Both plugins are enabled by default in GenGen and require no configuration for basic usage. They automatically:

- Scan your content after rendering
- Generate properly formatted XML files
- Include appropriate metadata and structure
- Handle edge cases like drafts and empty content gracefully 