---
title: "Assets Management"
layout: default
permalink: /assets/
description: "Bundle scripts, images, and other static assets in GenGen sites."
nav_section: "Styling & Assets"
nav_order: 3
---

# Managing Assets

GenGen treats everything outside the `_` prefixed directories as a static asset. You can drop images, JavaScript, fonts, or other resources alongside your content and they will be copied to the destination output.

## Organize Assets

- Store CSS under `assets/css/` (or let Sass/Tailwind emit bundles there).
- Place JavaScript in `assets/js/` and reference it from your layouts.
- Keep images in `assets/images/` to avoid cluttering your posts directory.

## Asset URLs

Use the `asset_url` filter to generate links that respect the configured destination:

```liquid
<link rel="stylesheet" href="{{ 'assets/css/site.css' | asset_url }}">
```

## Fingerprinting & Caching

For production builds, pair assets with the manifest helper from the production-readiness tasks so you can fingerprint and bust caches automatically.
