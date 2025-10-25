---
title: "Deploy to Netlify"
layout: default
permalink: /deploy-netlify/
description: "Use Netlify to build and host your GenGen documentation or marketing site."
nav_section: "Deployment"
nav_order: 3
---

# Deploy to Netlify

Netlify can build GenGen sites using a simple build command. Point Netlify at your repository and configure:

- **Build command**: `gengen build docs`
- **Publish directory**: `docs/public`

Netlify detects the Dart SDK automatically, but you can add the following to a `netlify.toml` for clarity:

```toml
[build]
  command = "dart pub get && gengen build docs"
  publish = "docs/public"

[build.environment]
  DART_VERSION = "3.3.0"
```

You can also enable Netlify Forms, redirects, or image optimization by adding configuration files under `docs/_netlify/` if needed.
