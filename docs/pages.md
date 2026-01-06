---
title: "Creating Pages"
layout: default
permalink: /pages/
description: "Learn how to create and structure pages in your GenGen site"
nav_section: "Getting Started"
nav_order: 4
---

# Creating Pages in GenGen

This guide covers everything you need to know about creating pages in GenGen, from basic setup to advanced configurations.

## What are Pages?

Pages in GenGen are static content files that form the structure of your website. Unlike posts, which are typically blog entries organized by date (from front matter or a `YYYY-MM-DD-` filename prefix), pages are standalone content like "About", "Contact", or "Services" pages.

## Basic Page Structure

Every page in GenGen consists of two main parts:

1. **Front Matter** - YAML configuration at the top of the file
2. **Content** - The actual page content (Markdown, HTML, or Liquid)

### Example Basic Page

```markdown
---
layout: page
---

# About Our Company

This is the content of the about page written in Markdown.
```

**Note**: The title is automatically inferred from the filename. For a file named `about.md`, the title would be "About".

## Front Matter Configuration

Front matter is YAML configuration enclosed between triple dashes (`---`) at the beginning of your file. Here are the key properties you can configure:

### Required Properties

GenGen can work with minimal or even no front matter configuration. All properties are optional since GenGen provides sensible defaults.

### Optional Properties

- **`title`**: The page title (used in `<title>` tags and navigation). If not provided, GenGen automatically infers the title from the filename
- **`layout`**: Specifies which layout template to use (defaults to site configuration)
- **`permalink`**: Custom URL structure for the page
- **`description`**: Page description for SEO and meta tags
- **`date`**: Publication date (useful for organizing pages)
- **`published`**: Set to `false` to exclude from site generation
- **`tags`**: Array of tags for categorization
- **`categories`**: Array of categories for organization

### Example with All Properties

```yaml
---
title: Contact Us
layout: page
permalink: /contact/
description: Get in touch with our team
date: 2024-01-15
published: true
tags: [contact, support]
categories: [business]
---
```

## Page Types and Examples

### 1. Homepage (index.html/index.md)

The homepage is typically named `index.html` or `index.md` and placed in your site root:

```markdown
---
layout: home
title: Welcome to My Site
---

# Welcome!

This is the homepage of my website.
```

### 2. About Page

```markdown
---
title: About
layout: page
permalink: /about/
---

# About Us

Learn more about our company and mission.
```

**Result**: Creates `public/about/index.html`

### 3. Contact Page

```markdown
---
title: Contact
layout: page
permalink: /contact/
---

# Get in Touch

- Email: hello@example.com
- Phone: (555) 123-4567
```

**Result**: Creates `public/contact/index.html`

### 4. Custom 404 Page

```html
---
permalink: /404.html
layout: default
title: Page Not Found
---

<div class="error-page">
  <h1>404 - Page Not Found</h1>
  <p>The page you're looking for doesn't exist.</p>
  <a href="/">Return Home</a>
</div>
```

## Permalink Configuration

Permalinks determine the URL structure of your pages. GenGen supports several permalink patterns.

### Directory Structure

GenGen creates directory structures when permalinks end with `/` or have no file extension:

```yaml
---
title: About Us
permalink: /about/
---
```

This creates:
- **Directory**: `public/about/`
- **File**: `public/about/index.html`

### Built-in Permalink Structures

- **`none`**: Uses the file path as-is
- **`date`**: For posts, uses `/year/month/day/title.html`
- **`pretty`**: Removes file extensions for clean URLs

### Custom Permalinks

You can define custom permalink patterns using tokens:

```yaml
---
title: My Page
permalink: /custom/:title/
---
```

Available tokens:
- `:title` - Slugified page title
- `:path` - Relative path from site root
- `:basename` - Filename without extension
- `:output_ext` - Output file extension (usually `.html`)
- `:categories` - Page categories joined with `/`
- `:year`, `:month`, `:day` - Date components (for dated content)

### Literal Permalinks

For exact URL control, use literal permalinks:

```yaml
---
title: Special Page
permalink: /exactly/this/path/
---
```

**Permalink Behavior:**
- `/path/` → Creates `path/index.html`
- `/path` → Creates `path/index.html`  
- `/path.html` → Creates `path.html`

For comprehensive permalink documentation, see the [Permalinks Guide](permalinks.md).

### Aliases

Create multiple URLs that point to the same page content:

```yaml
---
title: About Us
permalink: /about/
aliases:
  - /company-info.html
  - /who-we-are.html
  - /team.html
---
```

This creates:
- **Main page**: `public/about/index.html`
- **Alias files**: `public/company-info.html`, `public/who-we-are.html`, `public/team.html`

All URLs serve identical content, perfect for:
- **SEO preservation** during site restructuring
- **Backward compatibility** when changing URLs
- **Multiple access paths** for the same content

See the [Aliases Documentation](aliases.md) for detailed examples and use cases.

## Layouts

Layouts define the HTML structure that wraps your page content. GenGen looks for layouts in:

1. `_layouts/` directory
2. Theme layouts (`_themes/[theme]/_layouts/`)

### Specifying a Layout

```yaml
---
layout: page
---
```

### Common Layout Types

- **`default`**: Basic page layout with header/footer
- **`page`**: Standard page layout
- **`post`**: Blog post layout (typically for posts)
- **`home`**: Homepage layout

### Layout Inheritance

Layouts can inherit from other layouts:

```html
<!-- _layouts/page.html -->
---
layout: default
---

<article class="page">
  {{ content }}
</article>
```

## Content Formats

GenGen supports multiple content formats:

### Markdown (.md, .markdown)

```markdown
---
title: Markdown Page
---

# Heading

This is **bold** and *italic* text.

- List item 1
- List item 2
```

### HTML (.html)

```html
---
title: HTML Page
---

<h1>HTML Content</h1>
<p>Direct HTML content.</p>
```

### Liquid Templates

You can use Liquid templating in your content:

```markdown
---
title: Dynamic Page
---

# Welcome, {{ site.title }}!

Recent posts:
{% for post in site.posts limit:3 %}
- [{{ post.title }}]({{ post.url }})
{% endfor %}
```

## File Organization

### Recommended Directory Structure

```
your-site/
├── _layouts/          # Layout templates
├── _includes/         # Reusable partials
├── _themes/           # Theme files
├── assets/            # CSS, JS, images
├── about.md           # About page
├── contact.md         # Contact page
├── index.md           # Homepage
└── config.yaml        # Site configuration
```

### Page Placement

- **Root level**: For main site pages (about.md, contact.md)
- **Subdirectories**: For organized content (services/web-design.md)
- **Special directories**: Avoid `_posts/` for regular pages (reserved for blog posts). Posts can live in subdirectories under `_posts/` and do not require a date in the filename.

### Theme Pages

Themes can ship pages via a `content/` directory. Any **theme content file with
YAML front matter** is treated as a page and rendered into the final site output
using its relative path inside the theme `content/` folder. If the site provides
a file at the same relative path, the site file overrides the theme page.

### Generated Output Structure

Your pages create organized directory structures:

```
public/
├── about/
│   └── index.html
├── contact/
│   └── index.html
├── services/
│   └── web-design/
│       └── index.html
└── index.html
```

## Advanced Features

### Page Variables in Liquid

Access page properties in your content:

```liquid
<h1>{{ page.title }}</h1>
<p>Published: {{ page.date | date: "%B %d, %Y" }}</p>
<p>Tags: {{ page.tags | join: ", " }}</p>
```

**Note**: `page.title` will use the title from front matter if specified, otherwise it will use the title inferred from the filename.

### Site Variables

Access site-wide data:

```liquid
<p>Site: {{ site.title }}</p>
<p>Total pages: {{ site.pages | size }}</p>
```

### Conditional Content

```liquid
{% if page.description %}
<meta name="description" content="{{ page.description }}">
{% endif %}
```

## Best Practices

### 1. Consistent Front Matter

Use consistent front matter across your pages:

```yaml
---
title: Page Title
layout: page
description: Page description
date: 2024-01-15
---
```

### 2. SEO-Friendly Permalinks

Use descriptive, clean URLs:

```yaml
# Good
permalink: /about-us/

# Avoid
permalink: /page1.html
```

### 3. Logical File Organization

Organize pages in a logical directory structure:

```
├── about/
│   ├── index.md       # /about/
│   ├── team.md        # /about/team/
│   └── history.md     # /about/history/
├── services/
│   ├── index.md       # /services/
│   └── consulting.md  # /services/consulting/
└── contact.md         # /contact/
```

### 4. Layout Hierarchy

Create a clear layout hierarchy:

```
_layouts/
├── default.html       # Base layout
├── page.html         # Inherits from default
└── special.html      # For special pages
```

## Troubleshooting

### Common Issues

1. **Page not generating**: Check front matter syntax and file placement
2. **Layout not found**: Verify layout exists in `_layouts/` or theme
3. **Permalink conflicts**: Ensure unique permalinks across all pages
4. **Missing content**: Check for proper front matter delimiters (`---`)

### Debugging Tips

1. Check the generated `public/` directory for output files
2. Verify front matter YAML syntax
3. Ensure layout files exist and are properly structured
4. Check GenGen build logs for error messages

## Examples

For more examples, check the `examples/` directory in the GenGen repository, which contains various site configurations and page types demonstrating different features and use cases. 
