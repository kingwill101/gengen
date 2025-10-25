---
title: "Aliases"
layout: default
permalink: /aliases/
description: "Creating URL redirects and aliases for content migration"
nav_section: "URL Structure"
nav_order: 2
---

# Aliases in GenGen

Aliases in GenGen allow you to create multiple URLs that point to the same content. This is particularly useful for maintaining backward compatibility when changing URL structures, creating shorter URLs, or providing alternative paths to your content.

## What are Aliases?

Aliases are alternative URLs that redirect to your main content. When GenGen builds your site, it creates additional HTML files at the alias locations that contain the same content as the original page or post.

## Basic Usage

Add aliases to any page or post using the `aliases` field in your front matter:

```yaml
---
title: My Important Post
aliases: [old-url.html, another-path.html]
---

Your content here...
```

## Alias Formats

### Array Format (Recommended)

```yaml
---
title: My Post
aliases: [alias1.html, alias2.html, path/to/alias3.html]
---
```

### YAML List Format

```yaml
---
title: My Post
aliases:
  - alias1.html
  - alias2.html
  - path/to/alias3.html
---
```

## Alias Path Types

### 1. Relative Paths

Relative paths are resolved relative to your site's output directory:

```yaml
---
title: About Us
aliases: [about.html, company-info.html]
---
```

This creates:
- `public/about.html` → copies content from main page
- `public/company-info.html` → copies content from main page

### 2. Directory Paths

You can create aliases in subdirectories:

```yaml
---
title: Contact Information
aliases: [contact/info.html, help/contact.html]
---
```

This creates:
- `public/contact/info.html`
- `public/help/contact.html`

### 3. Absolute Paths

Absolute paths (starting with `/`) are resolved from the site root:

```yaml
---
title: Legacy Post
aliases: ["/2020/01/old-post.html", "/archive/legacy.html"]
---
```

**Note**: GenGen automatically removes the leading `/` and treats these as relative to the output directory.

## Real-World Examples

### Blog Post Migration

When migrating from another blogging platform:

```yaml
---
title: "Getting Started with GenGen"
date: 2024-01-15
permalink: /posts/gengen-getting-started/
aliases: 
  - "/2024/01/15/getting-started-with-gengen.html"
  - "/blog/gengen-tutorial.html"
  - "/old-blog/gengen-guide.html"
---
```

### Page Restructuring

When reorganizing your site structure:

```yaml
---
title: "Our Services"
permalink: /services/
aliases:
  - "/what-we-do.html"
  - "/offerings.html"
  - "/company/services.html"
---
```

### Short URLs

Creating memorable short URLs:

```yaml
---
title: "Contact Us"
permalink: /contact/
aliases:
  - "/contact.html"
  - "/get-in-touch.html"
  - "/hello.html"
---
```

## How Aliases Work

When GenGen processes a page or post with aliases:

1. **Main Content**: Creates the primary file at the permalink location
2. **Alias Files**: Creates identical copies at each alias location
3. **File Extension**: Automatically applies the same extension as the main file
4. **Directory Creation**: Creates necessary subdirectories for alias paths

### Example Processing

For a post with this front matter:

```yaml
---
title: "My Post"
permalink: /posts/my-post/
aliases: [old-post.html, archive/post.html]
---
```

GenGen creates:
- `public/posts/my-post/index.html` (main content)
- `public/old-post.html` (alias copy)
- `public/archive/post.html` (alias copy)

## File Extension Handling

GenGen automatically applies the correct file extension to aliases:

```yaml
---
title: "Markdown Post"
aliases: [old-post, archive/post]
---
```

Results in:
- `public/old-post.html` (`.html` extension added)
- `public/archive/post.html` (`.html` extension added)

If you want to specify the extension explicitly:

```yaml
---
title: "Custom Extension"
aliases: [feed.xml, data.json]
---
```

## Best Practices

### 1. Use Descriptive Aliases

Create aliases that are meaningful and memorable:

```yaml
# Good
aliases: [about-us.html, company-info.html, who-we-are.html]

# Avoid
aliases: [page1.html, p2.html, temp.html]
```

### 2. Maintain URL Consistency

Keep aliases consistent with your site's URL structure:

```yaml
# If your posts use /posts/ structure
aliases: ["/posts/old-title.html"]

# If your pages use clean URLs
aliases: ["/old-page/"]
```

### 3. Plan for SEO

Use aliases to maintain SEO value when changing URLs:

```yaml
---
title: "New Page Title"
permalink: /new-optimized-url/
aliases:
  - "/old-page-url.html"  # Preserve old SEO value
  - "/legacy/page.html"   # Handle legacy links
---
```

### 4. Document Your Aliases

Keep track of aliases in comments or documentation:

```yaml
---
title: "Important Page"
# Aliases for backward compatibility after 2024 restructure
aliases: 
  - "/old-structure/page.html"  # Pre-2024 URL
  - "/legacy/important.html"    # Legacy blog URL
---
```

## Common Use Cases

### 1. Platform Migration

When migrating from Jekyll, WordPress, or other platforms:

```yaml
---
title: "My Blog Post"
# Preserve WordPress URLs
aliases: ["/2023/12/my-blog-post.html"]
---
```

### 2. URL Cleanup

When cleaning up messy URLs:

```yaml
---
title: "Clean Title"
permalink: /clean-title/
# Preserve old messy URLs
aliases: ["/old_messy-URL123.html"]
---
```

### 3. Seasonal Content

For content that might be accessed via different seasonal paths:

```yaml
---
title: "Holiday Recipes"
aliases: 
  - "/christmas-recipes.html"
  - "/holiday-cooking.html"
  - "/december-recipes.html"
---
```

### 4. Multiple Languages/Regions

For content accessible via different language paths:

```yaml
---
title: "About Us"
aliases:
  - "/en/about.html"
  - "/english/about.html"
  - "/us/about.html"
---
```

## Troubleshooting

### Common Issues

1. **Alias Not Created**: Check that the alias path is valid and doesn't conflict with existing files
2. **Wrong Extension**: Verify the file extension is being applied correctly
3. **Path Conflicts**: Ensure aliases don't conflict with other pages or posts
4. **Directory Permissions**: Make sure GenGen can create directories for nested alias paths

### Debugging Tips

1. **Check Build Output**: Look for alias creation messages in the build log:
   ```
   -> Created alias 'old-post.html'
   -> '/path/to/public/old-post.html'
   ```

2. **Verify File Creation**: Check that alias files are actually created in the `public/` directory

3. **Test Paths**: Manually verify that alias URLs work in your browser

### Error Messages

- `"Failed to create alias 'alias.html'"`: Usually indicates a file system permission issue or invalid path
- Path conflicts will be logged as warnings during the build process

## Advanced Configuration

### Conditional Aliases

You can use Liquid templating in your content to reference aliases:

```liquid
<!-- In your layout or content -->
{% if page.aliases %}
  <!-- This page has aliases: {{ page.aliases | join: ", " }} -->
{% endif %}
```

### Site-wide Alias Patterns

While aliases are typically defined per-page, you can create patterns in your site configuration for consistent alias generation across multiple pages.

## Performance Considerations

- **File Size**: Aliases create complete copies of content, which increases build time and output size
- **Build Time**: Many aliases will slow down the build process
- **Maintenance**: Keep aliases organized and remove outdated ones periodically

## Examples

For more examples of aliases in action, check the `examples/` directory in the GenGen repository, particularly:
- `examples/base/_posts/` - Shows aliases for blog post migration
- `examples/base2/_posts/` - Demonstrates various alias patterns 
