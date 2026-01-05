---
title: "Collections Demo"
layout: default
---

# Collections Demo

This example mirrors Jekyll-style collection behavior: `collections_dir`, ordering,
static files inside collections, and `{% raw %}{% include_relative %}{% endraw %}`.

## Collections

<div class="grid">
{% for collection in site.collections %}
  <div class="card">
    <strong>{{ collection.label }}</strong><br />
    output: {{ collection.output }}<br />
    docs: {{ collection.docs | size }}<br />
    files: {{ collection.files | size }}
  </div>
{% endfor %}
</div>

## Tutorials (sorted by `lesson`)

{% for doc in site.tutorials %}
- [{{ doc.title }}]({{ doc.url }}) — lesson {{ doc.lesson }}
{% endfor %}

## Snippets (manual `order`)

{% for doc in site.snippets %}
- {{ doc.title }}
{% endfor %}

## Documents (includes collection static files)

{% for doc in site.documents %}
- {{ doc.relative_path }} → {{ doc.url }}
{% endfor %}

## Posts

Only posts under `collections/_posts` are read when `collections_dir` is set.

{% for post in site.posts %}
- {{ post.title }} ({{ post.url }})
{% endfor %}
