---
title: "Getting Started with GenGen"
date: 2024-01-15
layout: default
permalink: /posts/getting-started/
description: "A comprehensive guide to getting started with GenGen static site generator"
# Migration scenario - preserve old blog platform URLs
aliases:
  - "/2024/01/15/getting-started-with-gengen.html"  # Jekyll-style date URL
  - "/blog/gengen-tutorial.html"                    # Old blog section
  - "/tutorials/gengen-guide.html"                  # Tutorials section
  - "/wordpress/getting-started-gengen.html"        # WordPress migration
  - "/posts/gengen-tutorial.html"                   # Alternative post URL
---

# Getting Started with GenGen

Welcome to GenGen! This guide will help you build your first static site.

## What is GenGen?

GenGen is a powerful static site generator that helps you build fast, modern websites from Markdown files and templates.

## Migration Story

This blog post was originally published on multiple platforms:

- **WordPress** - Had a different URL structure
- **Jekyll** - Used date-based URLs  
- **Custom Blog** - Had its own naming convention
- **Tutorial Site** - Was in a tutorials section

Instead of losing all the SEO value and breaking existing links, we used aliases to preserve all the old URLs!

## Installation

```bash
# Install GenGen
dart pub global activate gengen

# Create a new site
gengen new my-site
cd my-site

# Build the site
gengen build
```

## Key Features

- **Fast Builds** - Lightning-fast static site generation
- **Flexible** - Support for multiple content types
- **Aliases** - Maintain backward compatibility (like this post!)
- **Themes** - Beautiful, customizable themes

## Why Use Aliases?

This post demonstrates a real-world scenario where aliases are invaluable:

1. **SEO Preservation** - Keep search engine rankings
2. **User Experience** - Don't break bookmarks
3. **Migration Safety** - Smooth platform transitions
4. **Link Maintenance** - External links keep working

## Next Steps

- Read the [documentation](/)
- Check out our [about page](/about/)
- [Contact us](/contact/) for support

---

*This post shows how aliases help during platform migration by preserving old URLs from Jekyll, WordPress, and custom blog systems.* 