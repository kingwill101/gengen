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

If you need to show Liquid syntax literally in a page, wrap it in a raw block or set `render_with_liquid: false` in the page front matter.

## Core Concepts

{% raw %}
- `{{ ... }}` outputs data such as `page.title` or `site.posts`.
- `{% ... %}` executes logic like `for`, `if`, `include`, or custom GenGen tags.
{% endraw %}
- Drops like `page` and `site` expose structured metadata from your content.

## Includes & Components

Store reusable fragments under `_includes/` and render them with:

{% raw %}
```liquid
{% render 'components/callout', variant: 'info', title: 'Heads up!' %}
  Content goes here.
{% endrender %}
```
{% endraw %}

## Shortcodes

Shortcodes are a thin wrapper around {% raw %}`{% render %}`{% endraw %} that make embeds easier to
write in Markdown and Liquid templates.

### Markdown

Use shortcodes inside Markdown content:

```text
[ shortcode 'partials/media/youtube' id='VIDEO_ID' width='560' height='315' ]
```

### Liquid

Use the Liquid tag directly in templates:

{% raw %}
```liquid
{% shortcode 'partials/media/youtube' id='VIDEO_ID' width='560' height='315' %}
```
{% endraw %}

### Attributes

Attributes accept single or double quotes and either `=` or `:` separators:

```text
[ shortcode "partials/media/twitter" url="https://twitter.com/..." width=560 ]
{% raw %}{% shortcode 'partials/media/twitter' url:'https://twitter.com/...' %}{% endraw %}
```

## Custom Filters & Tags

GenGen ships a set of built-in Liquid tags and filters. Lua plugins can also
register custom Liquid filters via `liquid_filters` (see the Plugins guide).
If you need new Liquid tags, add them to the GenGen codebase (or open an issue
so we can document the extension point).
