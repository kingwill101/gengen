---
title: "Getting Started with Modules"
layout: post
date: 2024-01-15
---

GenGen's module system makes it easy to share and reuse themes and plugins.

## Installing a Theme

Add to your `config.yaml`:

```yaml
module:
  imports:
    - path: github.com/user/theme-repo
      version: ^1.0.0

theme: theme-name
```

Then run:

```bash
gengen mod get
gengen build
```

## Benefits

- **Version pinning**: Reproducible builds with lockfiles
- **Easy updates**: `gengen mod update` gets latest compatible versions
- **Local development**: Use replacements to test local changes
