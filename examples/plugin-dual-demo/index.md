---
layout: default
title: "Plugin Demo"
plugin_label: "Site plugin injected this callout before the content."
---

## A convincing plugin demo

This page uses **two plugins**:

- A **site plugin** from `/_plugins/site-enhancer`
- A **theme plugin** from `/_themes/default/_plugins/theme-banner`

### What they do

- The site plugin prepends a callout and writes `assets/site-plugin.txt`.
- The theme plugin injects a floating badge and writes `assets/theme-plugin.txt`.
- Both plugins contribute CSS through the layout's plugin head injection.

### Why this matters

With plugins you can extend content pipelines, inject assets, and generate extra
output files without touching core templates.
