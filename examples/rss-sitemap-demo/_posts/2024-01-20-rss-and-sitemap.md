---
title: "RSS Feeds and Sitemaps Made Easy"
date: 2024-01-20
author: "GenGen Team"
categories: [features, seo]
tags: [rss, sitemap, xml, seo]
excerpt: "Discover how GenGen automatically generates RSS feeds and XML sitemaps to improve your site's discoverability."
---

# RSS Feeds and Sitemaps Made Easy

One of the great features of GenGen is the automatic generation of RSS feeds and XML sitemaps. These are essential for:

## RSS Feeds

RSS feeds allow users to subscribe to your content updates. GenGen automatically:

- Creates a `/feed.xml` file
- Includes your 20 most recent posts
- Preserves post metadata like author, categories, and publication dates
- Generates proper XML structure following RSS 2.0 standards

## XML Sitemaps

Sitemaps help search engines discover and index your content. GenGen generates:

- A `/sitemap.xml` file listing all pages and posts
- Proper change frequency hints (weekly for posts, monthly for pages)
- Priority indicators for search engines
- Last modified dates when available

## Customization

Both plugins are fully customizable:

```dart
// Custom RSS configuration
RssPlugin(
  outputPath: 'my-feed.xml',
  maxPosts: 50,
)

// Custom sitemap configuration  
SitemapPlugin(
  outputPath: 'my-sitemap.xml',
)
```

No configuration needed for basic usage - they work out of the box! 