---
title: "Build Process"
layout: default
permalink: /build/
description: "Understand the GenGen build pipeline from read to write phases."
nav_section: "Deployment"
nav_order: 1
---

# Build Process

GenGen follows a predictable pipeline: read content, convert through plugins, render with Liquid, and finally write the output. The CLI offers helpful commands for different stages:

```bash
gengen build         # one-off build
gengen serve         # local dev server with watch
gengen build --clean # reset destination before writing
```

## Hooks & Plugins

Plugins participate in `beforeRead`, `afterRead`, `beforeRender`, and `afterRender` hooks. Refer to the plugin documentation to see how Tailwind, Sass, and pagination hook into the build.

## Cleaning & Incremental Builds

Use the `destination` config to control where output is written. For CI deployments, run with `--clean` to avoid stale files. Incremental rebuilds are on the roadmap via the production-readiness plan.
