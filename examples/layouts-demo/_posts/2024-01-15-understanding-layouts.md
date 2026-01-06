---
title: "Understanding Layouts"
layout: post
date: 2024-01-15
tags: [layouts, templates]
---

Layouts in GenGen provide a way to wrap your content in reusable templates.

## How It Works

1. Create a layout in `_layouts/`
2. Reference it in your frontmatter with `layout: name`
3. Your content replaces `{{ content }}` in the layout

## Nesting Layouts

Layouts can extend other layouts by specifying their own `layout` in frontmatter.
