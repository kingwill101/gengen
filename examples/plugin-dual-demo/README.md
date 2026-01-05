# Plugin Dual Demo

This example shows two Lua plugins working together:

1. **Site plugin** in `_plugins/site-enhancer`
2. **Theme plugin** in `_themes/default/_plugins/theme-banner`

Both plugins are auto-discovered by GenGen and do not require explicit config entries.

## Build

```
# From repo root
./build/cli/linux_x64/bundle/bin/main build --source examples/plugin-dual-demo
```

## What to look for

- The page shows two floating pills (site + theme plugin).
- The site plugin injects a callout above content.
- Plugin assets are injected via `{% plugin_head %}` and `{% plugin_body %}`.
- Output files written by plugins:
  - `assets/site-plugin.txt`
  - `assets/theme-plugin.txt`

