---
title: "Documentation Overview"
layout: default
permalink: /overview/
description: "Overview of GenGen documentation and quick reference guide"
---

# GenGen Documentation

This documentation is built with GenGen itself, demonstrating the power and flexibility of the static site generator! This directory contains comprehensive guides for using GenGen.

## Getting Started

- **[Configuration](configuration.md)** - Complete guide to configuring GenGen with all available options
- **[Pages](pages.md)** - How to create and structure pages in your site
- **[Permalinks](permalinks.md)** - URL structure and permalink configuration
- **[Aliases](aliases.md)** - Creating URL redirects and aliases for content migration

## Adopt the Docs Platform

1. Scaffold a docs project with `gengen new docs my-docs-site` (this repository lives on the same scaffold under `docs/`).
2. Edit `_data/docs/navigation.yml` to describe the sidebar sections, labels, and ordering.
3. Ensure each Markdown page declares matching `nav_section` and `nav_order` front matter so navigation stays in sync.
4. Customize the reusable theme in `_themes/docs-platform`—Sass variables and partials control colors, spacing, and layout.
5. Preview your site locally with `gengen serve` and iterate on navigation or styling before publishing.
6. Prefer the Aurora look? Scaffold a regular site with `gengen new site --theme=aurora my-site` and copy the theme into your docs project.

## Deployment Workflow

- Generate the static output with `gengen build` (or `gengen build docs` when working from the repository root). The rendered HTML lives in `public/`.
- Publish the `public/` directory to any static host. The docs include detailed walkthroughs for [GitHub Pages](deploy-github.md) and [Netlify](deploy-netlify.md).
- Automate deployment by wiring `gengen build` into CI/CD; the output is deterministic so you can cache `public/` or upload it directly.

## Styling & Assets

- **[Sass Handling](sass.md)** - Using Sass/SCSS with the `_sass` directory structure and import system

## Advanced Features

- **[Pagination](pagination.md)** - Setting up automatic pagination for posts and content
- **[Plugins](plugins.md)** - Using and developing plugins to extend GenGen functionality

## Quick Reference

### Essential Configuration

```yaml
# Basic site setup
title: "My Site"
url: "https://example.com"
theme: "default"
destination: "public"
permalink: "pretty"

# Content processing
markdown_extensions:
  - ".md"
  - ".markdown"

exclude:
  - "README.md"
  - "config.*"
```

### Common Commands

```bash
# Create a new site
gengen new my-site

# Build the site
gengen build

# Serve locally with auto-rebuild
gengen serve

# Build with verbose output
gengen build --verbose
```

### Directory Structure

```
my-site/
├── config.yaml          # Main configuration
├── _posts/              # Blog posts
├── _pages/              # Static pages  
├── _layouts/            # Page templates
├── _includes/           # Partial templates
├── _data/               # Data files
├── _themes/             # Custom themes
├── _plugins/            # Custom plugins
├── assets/              # Static assets
└── public/              # Generated site (output)
```

## Examples

Check the `examples/` directory in the GenGen repository for complete working examples:

- `examples/base/` - Basic site setup
- `examples/pagination/` - Pagination configuration
- `examples/aliases/` - URL aliases and redirects

## Need Help?

- Check the relevant documentation sections above
- Look at the example sites for working configurations
- Review the configuration reference for all available options

## Contributing

Found an error or want to improve the documentation? Contributions are welcome! Please ensure any changes maintain the existing structure and style. 
