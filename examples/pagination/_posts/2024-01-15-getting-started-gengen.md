---
title: "Getting Started with GenGen Static Site Generator"
date: 2024-01-15
tags: [gengen, tutorial, getting-started]
excerpt: "Learn how to create your first static site with GenGen, a powerful Jekyll-compatible static site generator built in Dart."
author: "GenGen Team"
---

# Getting Started with GenGen

Welcome to **GenGen**, a modern static site generator that brings the power of Jekyll to the Dart ecosystem! In this comprehensive guide, we'll walk you through everything you need to know to create your first static website.

## What is GenGen?

GenGen is a static site generator inspired by Jekyll, built from the ground up in Dart. It offers:

- **Jekyll Compatibility**: Use familiar Jekyll syntax and patterns
- **Powerful Pagination**: Advanced pagination features similar to jekyll-paginate-v2
- **Plugin System**: Extensible architecture with built-in plugins
- **Modern Architecture**: Built with Dart for performance and reliability
- **Liquid Templates**: Full support for Liquid templating language

## Installation

Getting started with GenGen is straightforward. Make sure you have Dart installed, then:

```bash
# Clone the GenGen repository
git clone https://github.com/your-org/gengen.git
cd gengen

# Install dependencies
dart pub get

# Build the project
dart compile exe bin/gengen.dart -o gengen
```

## Your First Site

Create a new directory for your site and add a basic configuration:

```yaml
# config.yaml
site:
  title: "My Awesome Blog"
  description: "A blog built with GenGen"

theme: default
pagination:
  enabled: true
  items_per_page: 5
```

## Project Structure

A typical GenGen site follows this structure:

```
my-site/
├── config.yaml
├── index.html
├── _posts/
│   ├── 2024-01-15-my-first-post.md
│   └── 2024-01-16-another-post.md
├── _layouts/
│   └── default.html
└── _includes/
    └── header.html
```

## Writing Your First Post

Create a new file in the `_posts` directory:

```markdown
---
title: "My First Post"
date: 2024-01-15
tags: [blog, first-post]
---

# Hello World!

This is my first post using GenGen. The generator supports:

- Markdown content
- Front matter
- Liquid templating
- And much more!
```

## Building Your Site

Once you have your content ready, build your site:

```bash
./gengen build
```

Your generated site will be available in the `public` directory (or whatever you've configured as your destination).

## Next Steps

Now that you have the basics down, explore these advanced features:

1. **Pagination**: Learn how to paginate your posts
2. **Themes**: Customize your site's appearance
3. **Plugins**: Extend functionality with plugins
4. **Data Files**: Use YAML data files for dynamic content

Happy building with GenGen! 🚀 