---
title: "Home"
layout: default
---

# Drafts Demo

## Published Posts
{% for post in site.posts %}
{% unless post.draft %}
- [{{ post.title }}]({{ post.url }})
{% endunless %}
{% endfor %}

## Draft Posts (only visible with --drafts)
{% for post in site.posts %}
{% if post.draft %}
- [{{ post.title }}]({{ post.url }}) *(draft)*
{% endif %}
{% endfor %}
