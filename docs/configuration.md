---
title: "Configuration"
layout: default
permalink: /configuration/
description: "Complete guide to configuring GenGen with all available options"
nav_section: "Getting Started"
nav_order: 3
---

# GenGen Configuration

GenGen uses YAML configuration files to customize your site's behavior. This guide covers all available configuration options and their usage.

## Configuration Files

GenGen looks for configuration files in your site's root directory:

- `config.yaml` or `config.yml` - Main configuration file
- `config.development.yaml` - Development-specific overrides
- `config.production.yaml` - Production-specific overrides

### File Format

Configuration files use YAML format:

```yaml
# Site Information
title: "My GenGen Site"
url: "https://example.com"

# Build Settings
destination: public
theme: default

# Content Processing
permalink: date
markdown_extensions:
  - .md
  - .markdown
```

## Core Configuration Options

### Site Information

Basic information about your site:

```yaml
# Site title (used in templates and metadata)
title: "My GenGen Site"

# Site URL (used for absolute URLs)
url: "https://example.com"

# Site description
description: "A static site built with GenGen"

# Site author
author: "Your Name"

# Additional site data (accessible as site.* in templates)
site:
  email: "contact@example.com"
  social:
    twitter: "@username"
    github: "username"
```

### Build Settings

Control how GenGen processes and outputs your site:

```yaml
# Source directory (default: current directory)
source: "."

# Output directory (default: "public")
destination: "public"

# Theme to use (default: "default")
theme: "default"
```

### Directory Structure

Customize where GenGen looks for different types of content:

```yaml
# Posts directory (default: "_posts")
post_dir: "_posts"

# Drafts directory (default: "_drafts") 
draft_dir: "_drafts"

# Collections directory (default: "")
# When set, collections, posts, and drafts are read from this directory.
collections_dir: "collections"

# Themes directory (default: "_themes")
themes_dir: "_themes"

# Layouts directory (default: "_layouts")
layout_dir: "_layouts"

# Plugins directory (default: "_plugins")
plugin_dir: "_plugins"

# Sass/SCSS directory (default: "_sass")
sass_dir: "_sass"

# Data files directory (default: "_data")
data_dir: "_data"

# Static assets directory (default: "assets")
asset_dir: "assets"

# Templates directory (default: "_templates")
template_dir: "_templates"

# Includes directory (default: "_includes")
include_dir: "_includes"
```

### Collections

Collections let you group content in underscore-prefixed folders like `_docs` or `_tutorials`.

```yaml
collections:
  docs:
    output: true
    permalink: "/:collection/:path/"
  tutorials:
    output: false

defaults:
  - scope:
      type: "docs"
    values:
      layout: "doc"
```

`output: true` writes collection items to the destination. When `output` is `false`,
items are still available in Liquid via `site.collections` and `site.<name>`.

Collections can also be declared as a list:

```yaml
collections:
  - docs
  - tutorials
```

### Publish Controls

```yaml
# Include future-dated content in output
future: false

# Include items with published: false
unpublished: false

# Require front matter on extensionless posts
strict_front_matter: false
```

### Safe Mode (Plugins)

Safe mode disables **Lua plugins** by default. This is useful for locked-down
environments or shared builds.

```yaml
# Disable Lua plugins unless explicitly allowlisted
safe: true

# Allowlist Lua plugins that may run in safe mode
safe_plugins:
  - "trusted-plugin"
  - "theme-banner"
```

You can also enable safe mode from the CLI:

```bash
gengen build --safe
```

### File Processing

Control which files are processed and how:

```yaml
# Files to include in processing (glob patterns)
include:
  - "_posts/special/*.md"
  - "hidden-file.txt"

# Files to exclude from processing (glob patterns)
exclude:
  - "README.md"
  - "config.*"
  - "node_modules"
  - ".git"

# Markdown file extensions to process
markdown_extensions:
  - ".md"
  - ".markdown"
  - ".mdown"

# Files to completely block from access
block_list:
  - "secret.txt"
  - "private/*"
```

## Permalink Configuration

Control how URLs are generated for your content:

### Built-in Permalink Structures

```yaml
# Date-based permalink (default)
permalink: "date"
# Generates: /posts/2024/01/15/post-title.html

# Pretty URLs (directory structure)
permalink: "pretty" 
# Generates: /posts/2024/01/15/post-title/

# Ordinal day of year
permalink: "ordinal"
# Generates: /posts/2024/015/post-title.html

# Week-based
permalink: "weekdate"
# Generates: /posts/2024/W02/Sun/post-title.html

# Categories and title only
permalink: "none"
# Generates: /posts/post-title.html
```

### Custom Permalink Patterns

Create custom URL structures using tokens:

```yaml
# Custom pattern with date tokens
permalink: "blog/:year/:month/:title/"

# Simple blog structure
permalink: "posts/:title/"

# Category-based structure
permalink: ":categories/:title.html"
```

#### Available Tokens

- `:year` - 4-digit year (2024)
- `:month` - 2-digit month (01-12)
- `:day` - 2-digit day (01-31)
- `:title` - Slugified post title
- `:categories` - Post categories/tags joined with `/`
- `:basename` - Original filename without extension
- `:output_ext` - Output file extension (.html)

### Literal Permalinks

Use exact paths for specific pages:

```yaml
# In front matter
permalink: "/about/"           # Creates /about/index.html
permalink: "/contact.html"     # Creates /contact.html
permalink: "custom-page"       # Creates /custom-page/index.html
```

## Content Configuration

### Posts and Pages

```yaml
# Output directory for posts
output:
  posts_dir: "posts"

# Date format for parsing post dates
date_format: "yyyy-MM-dd HH:mm:ss"

# Whether to publish draft posts
publish_drafts: false
```

Notes:

- Posts can live in subdirectories under `_posts/`.
- Filenames do **not** need a date prefix. Dates are read from front matter,
  or derived from a `YYYY-MM-DD-` filename prefix when present.
- If you use date-based permalinks without a date, GenGen falls back to the file
  modified time.
- `_index.md` files in `_posts/` (or any content folder) are treated as
  directory-level front matter and are not rendered.

### Data Files

Data files in `_data/` are automatically loaded and available in templates:

```yaml
# Custom data can be added directly to config
data:
  navigation:
    - title: "Home"
      url: "/"
    - title: "About" 
      url: "/about/"
  
  footer:
    copyright: "© 2024 My Site"
```

## Pagination Configuration

Configure automatic pagination for posts:

```yaml
pagination:
  # Enable pagination (default: true)
  enabled: true
  
  # Number of items per page (default: 5)
  items_per_page: 10
  
  # Collection to paginate (default: "posts")
  collection: "posts"
  
  # URL pattern for pagination pages (default: "/page/:num/")
  permalink: "/page/:num/"
  
  # Index page template (default: "index")
  indexpage: "index"
```

### Pagination Template Variables

In your templates, pagination data is available as:

```liquid
<!-- Current page items -->
{% for post in page.paginate.items %}
  <h2>{{ post.title }}</h2>
{% endfor %}

<!-- Pagination info -->
<p>Page {{ page.paginate.current_page }} of {{ page.paginate.total_pages }}</p>

<!-- Navigation -->
{% if page.paginate.has_previous %}
  <a href="/page/{{ page.paginate.current_page | minus: 1 }}/">Previous</a>
{% endif %}

{% if page.paginate.has_next %}
  <a href="/page/{{ page.paginate.current_page | plus: 1 }}/">Next</a>
{% endif %}
```

## Theme Configuration

### Using Themes

```yaml
# Use a built-in or custom theme
theme: "default"

# Theme-specific settings can be added
theme_config:
  color_scheme: "dark"
  show_sidebar: true
```

### Theme Structure

Themes are located in `_themes/theme-name/` and can contain:

- `_layouts/` - Layout templates
- `_includes/` - Partial templates  
- `_sass/` - Sass/SCSS stylesheets
- `assets/` - Theme assets (CSS, JS, images)
- `config.yaml` - Theme-specific configuration

## Plugin Configuration

GenGen uses a flexible plugin system that allows you to enable/disable plugins individually or by groups.

### Plugin Groups

Plugins are organized into logical groups for easier management:

```yaml
plugins:
  # Enable plugin groups
  enabled:
    - core          # Essential plugins (Draft, Markdown, Liquid)
    - seo           # SEO plugins (RSS, Sitemap)
    - assets        # Asset processing (Sass, Tailwind)
    - content       # Content enhancement (Pagination, Aliases)
  
  # Disable specific plugins
  disabled:
    - TailwindPlugin  # Disable Tailwind even if assets group is enabled
  
  # Define custom plugin groups
  groups:
    core:
      - DraftPlugin
      - MarkdownPlugin
      - LiquidPlugin
    seo:
      - RssPlugin
      - SitemapPlugin
    assets:
      - SassPlugin
      - TailwindPlugin
    content:
      - PaginationPlugin
      - AliasPlugin
    
    # Custom group example
    blog:
      - MarkdownPlugin
      - LiquidPlugin
      - RssPlugin
      - PaginationPlugin
```

### Individual Plugin Configuration

Each plugin can have its own configuration section:

```yaml
# RSS feed configuration
rss:
  path: feed.xml
  limit: 20
  full_content: false

# Sitemap configuration
sitemap:
  path: sitemap.xml
  include_posts: true
  include_pages: true

# Sass configuration
sass:
  style: compressed
  source_map: false
  load_paths: ["_sass"]

# Tailwind configuration
tailwind:
  executable: "./tailwindcss"
  input: "assets/css/tailwind.css"
  output: "assets/css/styles.css"

# Pagination configuration
pagination:
  enabled: true
  per_page: 10
  permalink: "/page/:num/"
  title_suffix: " - Page :num"

# Draft publishing
publish_drafts: false
```

### Plugin Management Commands

Use the command line to inspect your plugin configuration:

```bash
# Show plugin overview
gengen plugins

# Show all available plugins
gengen plugins --available

# Show only enabled plugins
gengen plugins --enabled

# Show plugin groups
gengen plugins --groups
```

### Configuration Examples

**Minimal setup (core only):**
```yaml
plugins:
  enabled:
    - core
```

**Blog setup:**
```yaml
plugins:
  enabled:
    - core
    - seo
    - content
```

**Full-featured site:**
```yaml
plugins:
  enabled:
    - core
    - seo
    - assets
    - content
```

**Custom configuration:**
```yaml
plugins:
  enabled:
    - MarkdownPlugin
    - LiquidPlugin
    - SassPlugin
    - RssPlugin
  disabled: []
```

## Environment-Specific Configuration

### Development Configuration

Create `config.development.yaml` for development-specific settings:

```yaml
# Development overrides
destination: "_site"
show_drafts: true
url: "http://localhost:4000"

# Development-specific data
site:
  analytics_id: ""  # Disable analytics in development
```

### Production Configuration

Create `config.production.yaml` for production settings:

```yaml
# Production overrides
destination: "dist"
url: "https://mysite.com"

# Minification and optimization
sass:
  style: compressed

# Production-specific data
site:
  analytics_id: "GA-XXXXXXXX"
```

## Configuration Precedence

GenGen merges configuration in this order (later values override earlier ones):

1. Built-in defaults
2. `config.yaml`
3. Environment-specific config (`config.development.yaml`)
4. Command-line overrides
5. Front matter (for individual files)

## Complete Example

Here's a comprehensive configuration example:

```yaml
# Site Information
title: "My Blog"
description: "A personal blog about web development"
author: "Jane Developer"
url: "https://myblog.com"

# Custom site data
site:
  email: "jane@myblog.com"
  social:
    twitter: "@janedeveloper"
    github: "janedeveloper"
  navigation:
    - title: "Home"
      url: "/"
    - title: "About"
      url: "/about/"
    - title: "Blog"
      url: "/blog/"

# Build Settings
theme: "default"
destination: "public"
permalink: "pretty"

# Content Processing
markdown_extensions:
  - ".md"
  - ".markdown"

exclude:
  - "README.md"
  - "package.json"
  - "node_modules"
  - ".git"

include:
  - "_posts/drafts/*.md"

# Pagination
pagination:
  enabled: true
  items_per_page: 8
  permalink: "/page/:num/"

# Output Configuration
output:
  posts_dir: "blog"

# Date Format
date_format: "yyyy-MM-dd"

# Development Settings
publish_drafts: false
```

## Validation and Debugging

GenGen validates your configuration and will show warnings for:

- Invalid YAML syntax
- Unknown configuration options
- Incorrect data types (e.g., string instead of array)
- Missing required files or directories

Use the `--verbose` flag when building to see detailed configuration information:

```bash
gengen build --verbose
```

## Migration from Jekyll

GenGen's configuration is largely compatible with Jekyll. Common differences:

### Jekyll → GenGen Mappings

| Jekyll | GenGen | Notes |
|--------|--------|-------|
| `_config.yml` | `config.yaml` | YAML extension preferred |
| `baseurl` | Use `url` | GenGen handles this automatically |
| `collections` | Supported | Configure with `collections` + `_collection` folders |
| `gems` | `plugins` | Different plugin system |
| `highlighter` | Built into markdown | Automatic syntax highlighting |

### Unsupported Jekyll Features

- Jekyll-specific plugins (implement as GenGen plugins)
- Some advanced Liquid filters (basic set supported)

Most Jekyll sites can be migrated by renaming `_config.yml` to `config.yaml` and making minor adjustments to unsupported features. 
