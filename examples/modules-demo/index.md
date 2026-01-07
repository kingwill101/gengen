---
title: "Welcome to Modules Demo"
layout: default
---

# Welcome
fsdfd
This site uses a theme from a remote GitHub module.

## How It Works

1. The `config.yaml` declares module imports
2. Run `gengen mod get` to fetch modules
3. The theme is loaded from the module cache
4. Build the site with `gengen build`

## Posts

{% for post in site.posts %}
- [{{ post.title }}]({{ post.url }})
{% endfor %}
