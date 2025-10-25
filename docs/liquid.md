---
title: "Liquid Templates"
layout: default
permalink: /liquid/
description: "Use Liquid for layouts, includes, filters, and custom tags in GenGen."
nav_section: "Advanced Features"
nav_order: 3
---

# Liquid Templates

GenGen uses Liquid as its templating language. Pages, layouts, and includes can mix Markdown with Liquid variables, filters, and tags.

## Core Concepts

- `{{ ... }}` outputs data such as `page.title` or `site.posts`.
- `{% ... %}` executes logic like `for`, `if`, `include`, or custom GenGen tags.
- Drops like `page` and `site` expose structured metadata from your content.

## Includes & Components

Store reusable fragments under `_includes/` and render them with:

```liquid
{% render 'components/callout', variant: 'info', title: 'Heads up!' %}
  Content goes here.
{% endrender %}
```

## Custom Filters & Tags

Plugins can register new filters and tags. See the plugin development guide for writing Dart-based extensions that hook into Liquid.
