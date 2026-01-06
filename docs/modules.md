---
layout: docs
title: Modules
permalink: /modules/
---

# Module Versioning

GenGen supports versioned themes and plugins through a module system inspired by Hugo Modules. This allows you to declare dependencies on remote themes and plugins with specific versions, ensuring reproducible builds.

## Quick Start

Add a `module` section to your site's config file:

```yaml
# config.yaml or gengen.yaml
module:
  imports:
    - path: github.com/user/gengen-theme-minimal
      version: ^1.0.0
    - path: github.com/user/gengen-plugin-seo
      version: ">=2.0.0 <3.0.0"
```

Then run:

```bash
gengen mod get
```

## Module Sources

GenGen supports three types of module sources:

### Git Repositories

```yaml
module:
  imports:
    - path: github.com/user/repo
      version: ^1.0.0
    - path: gitlab.com/org/theme
      version: branch:main
    - path: bitbucket.org/team/plugin
      version: tag:v2.0.0
```

### Local Paths

```yaml
module:
  imports:
    - path: ../my-local-theme
    - path: /absolute/path/to/plugin
```

### pub.dev Packages

```yaml
module:
  imports:
    - path: pub:gengen_theme_aurora
      version: ^0.5.0
```

## Version Constraints

GenGen uses pub-style version constraints:

| Constraint | Meaning |
|------------|---------|
| `^1.0.0` | Compatible with 1.x.x (≥1.0.0 and <2.0.0) |
| `>=1.0.0 <2.0.0` | Explicit range |
| `1.2.3` | Exact version |
| `any` | Any version |

For git repositories, you can also use:

| Constraint | Meaning |
|------------|---------|
| `branch:main` | Specific branch |
| `tag:v1.0.0` | Specific tag |
| `commit:abc123` | Specific commit |

## Development Overrides

Use replacements to override modules with local paths during development:

```yaml
module:
  imports:
    - path: github.com/user/gengen-theme-minimal
      version: ^1.0.0
  replacements:
    - path: github.com/user/gengen-theme-minimal
      local: ../my-fork-of-minimal
```

## CLI Commands

### `gengen mod get`

Fetch all declared modules and update the lockfile.

```bash
gengen mod get
```

### `gengen mod update`

Update modules to latest versions matching constraints.

```bash
# Update all modules
gengen mod update --all

# Update specific module
gengen mod update github.com/user/theme
```

### `gengen mod list`

List all declared and resolved modules.

```bash
# Show declared modules
gengen mod list

# Show locked versions
gengen mod list --locked
```

### `gengen mod tidy`

Remove unused modules from the lockfile.

```bash
gengen mod tidy
```

### `gengen mod verify`

Verify cached modules match lockfile checksums.

```bash
gengen mod verify
```

## Lockfile

GenGen generates a `gengen.lock` file to ensure reproducible builds. This file should be committed to version control.

```yaml
# gengen.lock (auto-generated)
packages:
  "github.com/user/gengen-theme-minimal":
    version: "1.2.3"
    resolved: "https://github.com/user/gengen-theme-minimal.git"
    sha: "abc123def456"
```

## Cache

Modules are cached in `~/.gengen/cache/modules/` and organized by source and version:

```
~/.gengen/cache/modules/
└── github.com/
    └── user/
        └── gengen-theme-minimal/
            └── v1.2.3/
                ├── _layouts/
                ├── assets/
                └── config.yaml
```

## Precedence

Module resolution follows this priority order:

1. **Replacements** - Local overrides for development
2. **Local directories** - `_themes/` and `_plugins/` in your site
3. **Cached modules** - From `~/.gengen/cache/modules/`
4. **Remote fetch** - Download from source if not cached

Local themes and plugins always take precedence over modules, allowing you to customize or override module content.

## Using Themes from Modules

Specify the module path as your theme:

```yaml
# config.yaml
theme: github.com/user/gengen-theme-minimal
```

Or use the short name if declared in imports:

```yaml
module:
  imports:
    - path: github.com/user/gengen-theme-minimal
      version: ^1.0.0

theme: gengen-theme-minimal
```

## Migration from Local Themes

Existing sites using local `_themes/` directories continue to work without changes. To migrate to modules:

1. Add module declarations to your config
2. Run `gengen mod get`
3. Optionally remove the local `_themes/` directory

Your local themes will take precedence until removed, so you can migrate gradually.
