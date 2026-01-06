# Layouts and Includes Demo

This example demonstrates GenGen's layout system and includes.

## Features

- Layout inheritance (layout nesting)
- Reusable include partials
- Passing variables to includes
- Liquid templating

## Directory Structure

```
_layouts/
  base.html       # Root layout
  default.html    # Extends base
  post.html       # Extends default
  
_includes/
  header.html     # Site header
  footer.html     # Site footer
  nav.html        # Navigation
  meta.html       # Meta tags
```

## Layout Inheritance

Layouts can extend other layouts:

```html
<!-- _layouts/post.html -->
---
layout: default
---
<article>
  <h1>{{ page.title }}</h1>
  {{ content }}
</article>
```

## Using Includes

```liquid
{% include 'header' %}
{% include 'nav', active: 'home' %}
{% render 'footer' %}
```

## Include with Variables

```liquid
{% include 'card', title: 'Hello', body: 'World' %}
```

In the include:
```html
<div class="card">
  <h3>{{ title }}</h3>
  <p>{{ body }}</p>
</div>
```
