---
title: "API Reference"
layout: default
permalink: /api/
description: "High-level overview of GenGen’s public Dart APIs for extension authors."
nav_section: "Reference"
nav_order: 2
---

# API Reference

The GenGen Dart packages expose several extension points:

- `BasePlugin` – implement custom build logic or asset processing.
- `Site` – access the singleton site instance, posts, pages, and configuration.
- `DocumentDrop` – extend the data available to Liquid templates.

Generated API docs live in the repository under `docs/api/` once you run `dart doc`. You can host them alongside this documentation by copying the HTML output into a subdirectory and linking to it here.
