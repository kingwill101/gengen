---
layout: default
title: "Welcome"
permalink: /
---

# Welcome to GenGen

GenGen helps you build fast, flexible static sites with familiar Liquid templates.
Customize this page, add data files, or wire up plugins to match your project.

## Latest Posts

{% if site.posts.size == 0 %}
There are no posts yet. Create one in `_posts/` to see it appear here.
{% else %}
{% for post in site.posts %}
- [{{ post.title }}]({{ post.url }}) — {{ post.date | date: "%Y-%m-%d" }}
{% endfor %}
{% endif %}
