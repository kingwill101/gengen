---
title: "Permalinks"
layout: default
permalink: /permalinks/
description: "URL structure and permalink configuration in GenGen"
nav_section: "URL Structure"
nav_order: 1
---

# Permalinks in GenGen

Permalinks define the URL structure for your pages and posts in GenGen. This guide covers everything you need to know about configuring permalinks for clean, SEO-friendly URLs.

## What are Permalinks?

Permalinks are the permanent URLs to your individual pages and posts. They determine how your content is accessed on the web and play a crucial role in SEO and user experience.

## Directory Structure

GenGen creates directory structures when permalinks end with `/` or have no file extension.

### How Directory Structure Works

```yaml
---
title: About Us
permalink: /about/
---
```

**Results in:**
- **Directory**: `public/about/`
- **File**: `public/about/index.html`

### Permalink Rules

| Permalink Pattern | Generated Path |
|-------------------|---------------|
| `/about/` | `about/index.html` |
| `/about` | `about/index.html` |
| `/about.html` | `about.html` |
| `/services/web-design/` | `services/web-design/index.html` |

## Built-in Permalink Structures

GenGen provides several built-in permalink structures:

### `none` (Default for Pages)
Uses the file path as-is relative to the source directory.

```yaml
permalink: none
```

**Example**: `about.md` → `/about.html`

### `date` (Default for Posts)
Uses date-based structure for blog posts.

```yaml
permalink: date
```

**Example**: `my-post.md` with front matter `date: 2024-01-15` → `/2024/01/15/my-post.html`

### `pretty`
Creates directory structures by removing file extensions.

```yaml
permalink: pretty
```

**Example**: `about.md` → `about/index.html`

## Custom Permalink Patterns

Create custom URL structures using tokens:

### Available Tokens

| Token | Description | Example |
|-------|-------------|---------|
| `:title` | Slugified page/post title | `my-awesome-post` |
| `:basename` | Filename without extension | `2024-01-15-post` |
| `:path` | Relative directory path | `blog/tech` for `blog/tech/post.md` |
| `:categories` | Categories joined with `/` | `tech/web-development` |
| `:slugified_categories` | URL-safe categories | `tech-web-development` |
| `:output_ext` | Output extension | `.html` |

### Date Tokens (for dated content)

| Token | Description | Example |
|-------|-------------|---------|
| `:year` | Four-digit year | `2024` |
| `:month` | Two-digit month | `01` |
| `:day` | Two-digit day | `15` |
| `:short_year` | Two-digit year | `24` |
| `:i_month` | Month without leading zero | `1` |
| `:i_day` | Day without leading zero | `5` |
| `:short_month` | Abbreviated month name | `Jan` |
| `:long_month` | Full month name | `January` |
| `:short_day` | Abbreviated day name | `Mon` |
| `:long_day` | Full day name | `Monday` |
| `:hour` | Two-digit hour | `14` |
| `:minute` | Two-digit minute | `30` |
| `:second` | Two-digit second | `45` |

Dates come from front matter (`date:`) or a `YYYY-MM-DD-` filename prefix. If no
date is available, GenGen falls back to the file’s modified time for posts and
collections.

### Custom Pattern Examples

```yaml
# Blog-style with categories
permalink: /blog/:categories/:title/

# Date-based with clean URLs
permalink: /:year/:month/:title/

# Simple category structure
permalink: /:categories/:basename/

# Complex pattern
permalink: /posts/:year/:short_month/:day/:title/
```

## Literal Permalinks

For exact URL control, specify the complete path:

```yaml
---
title: Special Page
permalink: /exactly/this/path/
---
```

**Benefits:**
- Complete control over URL structure
- No token processing
- Predictable output paths

## Site-wide Permalink Configuration

Set default permalink patterns in your `config.yaml`:

```yaml
# Default for all pages
permalink: pretty

# Override for posts
posts:
  permalink: /blog/:year/:month/:title/
```

## Best Practices

### 1. Choose Appropriate URL Structure
```yaml
# Directory structure
permalink: /about/

# Direct file
permalink: /about.html
```

### 2. Keep URLs Short and Descriptive
```yaml
# Good
permalink: /services/web-design/

# Avoid - Too verbose
permalink: /our-company-services-and-offerings/web-design-and-development/
```

### 3. Use Consistent Patterns
```yaml
# Consistent blog structure
permalink: /blog/:year/:month/:title/

# Not recommended - Mixed patterns
# Some posts: /blog/:title/
# Others: /:year/:month/:title/
```

### 4. Consider SEO
```yaml
# SEO-friendly
permalink: /learn/:categories/:title/

# Less SEO-friendly
permalink: /p/:basename/
```

## Troubleshooting

### Common Issues

**Problem**: Permalink tokens not being replaced
```yaml
# Check for typos in token names
permalink: /:titel/  # Wrong - should be :title
```

**Problem**: Directory structure not working
```yaml
# Ensure permalink ends with / for directory structure
permalink: /about/   # Creates about/index.html
permalink: /about    # Also creates about/index.html
```

**Problem**: Date tokens not working
```yaml
# Ensure content has a valid date field
---
date: 2024-01-15    # Required for date tokens
permalink: /:year/:month/:title/
---
```

If a date cannot be parsed, GenGen falls back to a non-date permalink.

### Debugging Permalinks

Enable debug logging to see permalink processing:

```bash
# Build with verbose logging
gengen build --verbose
```

Look for log messages showing:
- Permalink processing
- Token replacement
- File path generation

## Advanced Usage

### Conditional Permalinks

Use different permalinks based on content type:

```yaml
# In config.yaml
posts:
  permalink: /blog/:year/:month/:title/

pages:
  permalink: /:title/
```

### Dynamic Permalinks with Liquid

Process permalinks with Liquid templates:

```yaml
---
title: My Post
category: tech
permalink: /{{ page.category }}/{{ page.title | slugify }}/
---
```

### Multilingual Permalinks

Structure URLs for multiple languages:

```yaml
---
title: About Us
lang: en
permalink: /{{ page.lang }}/about/
---
```

## Examples

### Corporate Website
```yaml
# Homepage
permalink: /

# About page
permalink: /about/

# Services
permalink: /services/:title/

# Contact
permalink: /contact/
```

### Blog
```yaml
# Blog posts
permalink: /blog/:year/:month/:title/

# Categories
permalink: /blog/category/:categories/

# Archive
permalink: /blog/archive/:year/
```

### Documentation Site
```yaml
# Docs
permalink: /docs/:path/:title/

# API Reference
permalink: /api/:title/

# Guides
permalink: /guides/:categories/:title/
```

## Migration from Other Platforms

### From Jekyll
GenGen supports Jekyll-style permalinks:

```yaml
# Jekyll format
permalink: /:categories/:year/:month/:day/:title.html

# GenGen equivalent
permalink: /:categories/:year/:month/:day/:title/
```

### From WordPress
Convert WordPress URLs:

```yaml
# WordPress: /2024/01/15/post-title/
permalink: /:year/:month/:day/:title/

# WordPress with category: /category/post-title/
permalink: /:categories/:title/
```

## Related Documentation

- [Pages Documentation](pages.md) - Creating and configuring pages
- [Aliases Documentation](/aliases/) - Multiple URLs for the same content
- [Configuration Guide](config.md) - Site-wide permalink settings 
