---
title: "Installation"
layout: default
permalink: /installation/
description: "Install GenGen, configure prerequisites, and verify your setup."
nav_section: "Getting Started"
nav_order: 2
---

# Installation

There are two ways to install GenGen:

1. **Use the Dart SDK** – activate GenGen globally with `dart pub global activate gengen` and add the global bin directory to your `PATH`.
2. **Use the standalone binary** – download a platform-specific executable from the project releases, mark it as executable, and place it somewhere on your `PATH`.

> 💡 **Tip** — On macOS or Linux you can also manage the CLI with homebrew or asdf if you prefer to pin a version.

## Prerequisites

- Dart SDK 3.3 or newer
- Optional: `sass` / `tailwindcss` CLIs for asset pipelines
- Optional: Git (recommended for scaffolding and deployments)

## Verify Installation

```bash
gengen --version
gengen help
```

If the version prints correctly you are ready to create your first site with `gengen new my-site`.
