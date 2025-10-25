# Lua Stdlib Demo Plugin

This example demonstrates how to build a Lua plugin that uses GenGen's `gengen` standard library helpers.

Place the `_plugins/stdlib-demo` directory inside your site's plugins directory and enable the plugin by adding `StdlibDemoPlugin` to your configuration:

```yaml
plugins:
  enabled:
    - core
    - StdlibDemoPlugin
```

The plugin logs status messages, writes an additional file to the output directory, and appends a computed slug to rendered content using the standard library utilities.
