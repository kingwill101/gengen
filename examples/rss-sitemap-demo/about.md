---
title: "About This Demo"
layout: default
sitemap_priority: 0.8
sitemap_changefreq: monthly
---

# About This Demo

This demo site showcases the RSS feed and sitemap generation capabilities of GenGen.

## What You'll Find Here

This site automatically generates:

### RSS Feed (`/feed.xml`)
- Contains the 20 most recent posts
- Includes post titles, excerpts, and metadata
- Follows RSS 2.0 specification
- Updates automatically when you add new posts

### XML Sitemap (`/sitemap.xml`)
- Lists all pages and posts on the site
- Includes change frequency hints for search engines
- Sets appropriate priorities (homepage = 1.0, posts = 0.7, pages = 0.5)
- Updates automatically when you add new content

## Custom Sitemap Settings

This page demonstrates custom sitemap settings:
- **Priority**: 0.8 (higher than default page priority)
- **Change Frequency**: monthly (instead of default)

You can customize these settings in any page's front matter using:
- `sitemap_priority`: number between 0.0 and 1.0
- `sitemap_changefreq`: always, hourly, daily, weekly, monthly, yearly, never

## SEO Benefits

Having both RSS feeds and sitemaps helps with:
- **Content Discovery**: Search engines can find your content faster
- **User Engagement**: Readers can subscribe to updates
- **Indexing**: Better search engine indexing of your site structure
- **Performance**: Search engines crawl more efficiently 