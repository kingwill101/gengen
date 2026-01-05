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

## Rendering Order

GenGen renders Liquid before Markdown conversion. This lets Liquid output Markdown that will be converted into HTML.

If you need to show Liquid syntax literally in a page, wrap it with `{% raw %}` and `{% endraw %}` or set `render_with_liquid: false` in the page front matter.

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

GenGen ships a set of built-in Liquid tags and filters. Lua plugins can inject
assets and transform content via `convert`, but they do not register Liquid
filters or tags directly. If you need new Liquid primitives, add them to the
GenGen codebase (or open an issue so we can document the extension point).
