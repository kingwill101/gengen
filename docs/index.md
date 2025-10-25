---
title: "GenGen Documentation"
layout: home
permalink: /
description: "A data-driven documentation hub for GenGen static site generator."
nav_section: "Getting Started"
nav_order: 1
---

# Welcome to GenGen

GenGen is a powerful, fast, and flexible static site generator built with Dart. It combines the best features of Jekyll with modern performance and an intuitive configuration system.

## Why GenGen?

- **🚀 Fast Build Times** - Optimized for speed with intelligent caching
- **📝 Jekyll Compatible** - Easy migration from Jekyll sites
- **🎨 Flexible Theming** - Powerful theme system with Sass support
- **🔌 Plugin System** - Extensible with custom plugins
- **📱 Modern Features** - Built-in pagination, aliases, and more

## Quick Start

### 1. Install GenGen

{% highlight bash %}
# Install GenGen (installation method here)
{% endhighlight %}

### 2. Create a New Site

{% highlight bash %}
gengen new my-site
cd my-site
{% endhighlight %}

### 3. Build and Serve

{% highlight bash %}
# Build the site
gengen build

# Serve locally with auto-rebuild
gengen serve
{% endhighlight %}

Your site will be available at `http://localhost:4000`

## Documentation Sections

<div class="docs-grid">
  {% assign sections = site.data.docs.navigation.sidebar.sections %}
  {% for section in sections %}
  <div class="docs-section">
    <h3>{{ section.title }}</h3>
    {% for page in section.pages %}
    <div class="docs-page">
      <h4><a href="{{ page.url }}">{{ page.title }}</a></h4>
      <p>{{ page.description }}</p>
    </div>
    {% endfor %}
  </div>
  {% endfor %}
</div>

## Getting Started

New to GenGen? Start with these essential guides:

1. **[Configuration](configuration/)** - Learn how to configure your site
2. **[Creating Pages](pages/)** - Build your first pages and posts
3. **[Permalinks](permalinks/)** - Customize your URL structure
4. **[Themes](themes/)** - Style your site with themes

## Examples

Looking for inspiration? Check out these example sites:

- **Basic Blog** - Simple blog setup with posts and pages
- **Documentation Site** - This very site you're reading!
- **Portfolio** - Showcase your work with a clean design
- **Business Site** - Professional site with landing pages

## Community

- **GitHub**: [github.com/gengen/gengen](https://github.com/gengen/gengen)
- **Issues**: Report bugs and request features
- **Discussions**: Get help and share ideas

## Features Showcase

### Built-in Pagination

{% highlight yaml %}
pagination:
  enabled: true
  items_per_page: 10
  permalink: "/page/:num/"
{% endhighlight %}

### URL Aliases

{% highlight yaml %}
# In front matter
aliases:
  - old-url.html
  - legacy/path.html
{% endhighlight %}

### Custom Permalinks

{% highlight yaml %}
# Date-based URLs
permalink: "/:year/:month/:day/:title/"

# Simple blog URLs  
permalink: "/blog/:title/"
{% endhighlight %}

### Flexible Themes

{% highlight yaml %}
theme: "my-custom-theme"
theme_config:
  color_scheme: "dark"
  show_sidebar: true
{% endhighlight %}

---

Ready to get started? Head over to the [Configuration guide](configuration/) to begin building your site with GenGen! 
