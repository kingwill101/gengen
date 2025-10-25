---
title: "Troubleshooting"
layout: default
permalink: /troubleshooting/
description: "Diagnose common build and deployment issues in GenGen."
nav_section: "Reference"
nav_order: 3
---

# Troubleshooting

## Build Fails Because of Missing Theme

Ensure the theme is installed or bundled in your repository. Run `gengen list themes` or double-check the `_themes/` directory.

## Liquid Error: Missing Include

Liquid throws a detailed error including the template and include name. Make sure `_includes/` contains the referenced file or update the path in your render tag.

## Tailwind Executable Not Found

Enable the Tailwind auto-fetch (see Tailwind enhancement proposal) or download the CLI manually and set `tailwind_path` in `_config.yaml`.

If you run into something not covered here, open an issue so we can document the fix.
