# Plugin Configuration Demo

This example demonstrates GenGen's flexible plugin system with various configuration options.

## Overview

GenGen uses a powerful plugin system that allows you to:
- Enable/disable plugins individually or by groups
- Configure plugin-specific settings
- Create custom plugin groups
- Use command-line tools to inspect plugin status

## Plugin Groups

GenGen organizes plugins into logical groups:

- **core**: Essential plugins (DraftPlugin, MarkdownPlugin, LiquidPlugin)
- **seo**: SEO optimization (RssPlugin, SitemapPlugin)
- **assets**: Asset processing (SassPlugin, TailwindPlugin)
- **content**: Content enhancement (PaginationPlugin, AliasPlugin)

## Configuration Examples

### 1. Default Configuration (Core Only)

```yaml
plugins:
  enabled:
    - core
```

This enables only the essential plugins needed for basic functionality.

### 2. Blog Setup

```yaml
plugins:
  enabled:
    - core
    - seo
    - content
```

Perfect for blogs with RSS feeds, sitemaps, and pagination.

### 3. Full-Featured Site

```yaml
plugins:
  enabled:
    - core
    - seo
    - assets
    - content
```

Enables all plugin groups for maximum functionality.

### 4. Custom Plugin Selection

```yaml
plugins:
  enabled:
    - MarkdownPlugin
    - LiquidPlugin
    - SassPlugin
    - RssPlugin
```

Select specific plugins without using groups.

### 5. Selective Disable

```yaml
plugins:
  enabled:
    - core
    - assets
  disabled:
    - TailwindPlugin
```

Enable groups but disable specific plugins.

## Plugin-Specific Configuration

Each plugin can have its own configuration section:

```yaml
# RSS feed settings
rss:
  path: feed.xml
  limit: 20
  full_content: false

# Sitemap settings
sitemap:
  path: sitemap.xml
  include_posts: true
  include_pages: true

# Sass compilation
sass:
  style: compressed
  source_map: false
  load_paths: ["_sass"]

# Tailwind CSS
tailwind:
  executable: "./tailwindcss"
  input: "assets/css/tailwind.css"
  output: "assets/css/styles.css"

# Pagination
pagination:
  enabled: true
  per_page: 10
  permalink: "/page/:num/"
  title_suffix: " - Page :num"
```

## Command Line Tools

Use these commands to inspect your plugin configuration:

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

## Running This Example

1. Navigate to this directory:
   ```bash
   cd examples/plugin-config-demo
   ```

2. Check current plugin status:
   ```bash
   gengen plugins
   ```

3. Try different configurations by modifying `config.yaml`

4. Build the site:
   ```bash
   gengen build
   ```

## Customization

Try modifying the `config.yaml` file to experiment with different plugin combinations:

- Comment/uncomment different plugin groups in the `enabled` section
- Add plugins to the `disabled` section
- Create your own custom plugin groups
- Adjust plugin-specific settings

## Best Practices

1. **Start with core**: Always enable at least the core plugin group
2. **Use groups**: Organize related functionality with plugin groups
3. **Test configurations**: Verify your setup works as expected
4. **Monitor performance**: Some plugins may impact build times
5. **Document dependencies**: Note any external tool requirements (like Tailwind CSS)

## Troubleshooting

If plugins aren't working as expected:

1. Check plugin names are spelled correctly
2. Verify plugins are in the enabled list or group
3. Ensure plugins aren't in the disabled list
4. Check for external tool dependencies
5. Use `gengen plugins` to inspect current status
