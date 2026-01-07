---
layout: default
title: Posts
permalink: /posts/
---

# Posts

{% if site.posts.size == 0 %}
No posts yet. Create one in `_posts/` to populate this index.
{% else %}
{% for post in site.posts %}
1. [{{ post.title }}]({{ post.url }}) — {{ post.date | date: "%Y-%m-%d" }}
{% endfor %}
{% endif %}
