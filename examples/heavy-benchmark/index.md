---
layout: default
title: "Heavy Test Site - Performance Benchmark"
---

# Welcome to Heavy Test Site

This site contains **150 posts** and **50 pages** generated for performance testing of the GenGen static site generator.

## Recent Posts

{% for post in site.posts limit:10 %}
- [{{ post.title }}]({{ post.url }}) - {{ post.date | date: '%B %d, %Y' }}
{% endfor %}

## Statistics

- **Total Posts:** {{ site.posts | size }}
- **Total Pages:** {{ site.pages | size }}
- **Categories:** tech, programming, web-dev, mobile, ai, blockchain, design, productivity
- **Generated for:** Parallel processing performance testing

## Performance Testing

This site is designed to test the performance improvements of parallel processing in GenGen's build system.
