---
title: "Collections"
layout: default
description: "Group structured content with Jekyll-style collections."
---

# Collections

Collections let you organize structured content in underscore-prefixed folders like
`_docs` or `_tutorials`. Each collection can control output and permalink patterns.

## Configure a collection

```yaml
collections:
  docs:
    output: true
    permalink: "/:collection/:path/"
```

Collections can also be declared as a list when you only need defaults:

```yaml
collections:
  - docs
  - tutorials
```

With this config, any file under `_docs/` is treated as part of the `docs` collection.
For example:

```
_docs/getting-started.md -> /docs/getting-started/
```

Collections support nested folders. The `:path` token includes subdirectories:

```
_docs/guides/intro.md -> /docs/guides/intro/
```

## Directory front matter with `_index.md`

Place an `_index.md` file in a collection directory to apply front matter defaults
to everything inside that directory. `_index.md` files are **not** rendered.

```
_docs/_index.md          # Applies to all docs
_docs/guides/_index.md   # Applies to all guides
```

## Output control

If `output` is `false`, the items are still available in Liquid, but GenGen will not
write them to `public/`:

```yaml
collections:
  tutorials:
    output: false
```

## Liquid access

Collections are exposed through `site.collections` (a list) and a convenience key:

```liquid
{% for collection in site.collections %}
  <h3>{{ collection.label }} (output: {{ collection.output }})</h3>
{% endfor %}

{% for doc in site.docs %}
  <a href="{{ doc.url }}">{{ doc.title }}</a>
{% endfor %}

{% for doc in site.documents %}
  {{ doc.relative_path }}
{% endfor %}
```

Each collection exposes:

- `collection.docs` for items with front matter (rendered documents)
- `collection.files` for items without front matter (static files)

## Sorting and ordering

Collections can be sorted automatically or manually:

```yaml
collections:
  docs:
    output: true
    sort_by: "weight"
    order:
      - "getting-started.md"
      - "guides/intro.md"
```

- `sort_by` uses a front matter key when present.
- `order` lets you pin specific paths; remaining items use default sorting.

## Default front matter

Use `defaults` to apply front matter values to a collection:

```yaml
defaults:
  - scope:
      type: "docs"
    values:
      layout: "doc"
```

Defaults apply before front matter so individual files can override them.
