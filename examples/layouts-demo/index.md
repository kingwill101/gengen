---
title: "Home"
layout: default
---

# Welcome to Layouts Demo

This site demonstrates layout inheritance and includes.

## Posts

{% for post in site.posts %}
- [{{ post.title }}]({{ post.url }}) - {{ post.date | date: "%b %d" }}
{% endfor %}

## Layout Chain

This page uses: `default.html` → `base.html`

Posts use: `post.html` → `default.html` → `base.html`
