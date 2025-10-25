---
title: "Plugins"
layout: default
permalink: /plugins/
description: "Using and configuring plugins to extend GenGen functionality"
nav_section: "Advanced Features"
nav_order: 2
---

# GenGen Plugins

GenGen uses a powerful plugin system to extend functionality. Plugins can be configured through your site's configuration file, and you can enable/disable them individually or by groups.

## Plugin Configuration

### Basic Configuration

Plugins are configured in your `config.yaml` file under the `plugins` section:

```yaml
plugins:
  enabled:
    - core          # Enable the core plugin group
    - seo           # Enable SEO plugins
  disabled:
    - TailwindPlugin  # Disable a specific plugin
```

### Plugin Groups

GenGen organizes plugins into logical groups for easier management:

{% for group in site.data.plugins.groups %}
- **{{ group[0] }}**: {{ group[1].description }}
{% endfor %}

### Default Configuration

By default, GenGen enables only the `core` group:

```yaml
plugins:
  enabled:
{% for group in site.data.plugins.defaults.enabled %}    - {{ group }}
{% endfor %}
  disabled: {{ site.data.plugins.defaults.disabled | jsonify }}
  groups:
{% for group in site.data.plugins.groups %}    {{ group[0] }}:
{% for plugin in group[1].plugins %}      - {{ plugin.class_name }}
{% endfor %}
{% endfor %}
```

### Configuration Examples

{% for example in site.data.plugins.examples %}
**{{ example[1].description }}:**
```yaml
{{ example[1].config | jsonify }}
```
{% endfor %}

## Built-in Plugins

GenGen comes with several built-in plugins that provide core functionality:

{% for group in site.data.plugins.groups %}
### {{ group[1].name }}

{{ group[1].description }}

{% for plugin in group[1].plugins %}
#### {{ plugin.name }}
{{ plugin.description }}

{% if plugin.config_key %}**Default configuration:**
```yaml
{{ plugin.config_key }}:
{{ plugin.default_config | jsonify }}
```
{% endif %}

{% if plugin.supported_extensions %}**Supported file extensions:**
{% for ext in plugin.supported_extensions %}- `{{ ext }}`
{% endfor %}
{% endif %}

{% if plugin.features %}**Features:**
{% for feature in plugin.features %}- {{ feature }}
{% endfor %}
{% endif %}

{% if plugin.available_objects %}**Available objects:**
{% for obj in plugin.available_objects %}- `{{ obj }}`
{% endfor %}
{% endif %}

{% if plugin.requirements %}**Requirements:**
{% for req in plugin.requirements %}- {{ req }}
{% endfor %}
{% endif %}

{% if plugin.usage %}**Usage:**
{{ plugin.usage }}
{% endif %}

{% endfor %}
{% endfor %}

## Plugin Management Commands

GenGen provides a command-line interface for managing plugins:

```bash
# {{ site.data.plugins.commands.list | split: ' ' | slice: 2, 10 | join: ' ' }}
{{ site.data.plugins.commands.list }}

# {{ site.data.plugins.commands.available | split: ' ' | slice: 2, 10 | join: ' ' }}
{{ site.data.plugins.commands.available }}

# {{ site.data.plugins.commands.enabled | split: ' ' | slice: 2, 10 | join: ' ' }}
{{ site.data.plugins.commands.enabled }}

# {{ site.data.plugins.commands.groups | split: ' ' | slice: 2, 10 | join: ' ' }}
{{ site.data.plugins.commands.groups }}
```

## Configuration Examples

Here are some common configuration patterns:

{% for example in site.data.config_examples %}
### {{ example[1].name }}

{{ example[1].description }}

```yaml
{{ example[1].config }}
```

{% endfor %}

## Writing Custom Plugins

### Plugin Structure

A GenGen plugin consists of:

1. A configuration file (`config.yaml`)
2. Lua source files that implement the plugin lifecycle (recommended)
3. Optional assets (CSS, JavaScript, images, etc.)

> Legacy Dart-based plugins are still discovered but will log warnings during load. New plugins should use Lua.

### Basic Plugin Example

**`_plugins/my-plugin/config.yaml`:**
```yaml
name: MyCustomPlugin
entrypoint: main.lua:init_plugin
description: A custom plugin for GenGen
author: Your Name
version: 1.0.0
```

**`_plugins/my-plugin/main.lua`:**
```lua
function init_plugin(metadata)
  return {
    head_injection = function()
      return '<meta name="my-plugin" content="enabled">'
    end,
    css_assets = function()
      return { 'assets/styles.css' }
    end,
    convert = function(content, page)
      return content .. '\n<!-- processed by my-plugin -->'
    end,
    after_generate = function()
      print('MyCustomPlugin finished generating!')
    end
  }
end
```

In Lua, the entrypoint follows the `filename:initFunction` format. The initializer receives plugin metadata and must return a table whose keys map to GenGen lifecycle hooks using `snake_case` (for example `after_generate`, `before_render`, `convert`). Missing hooks are treated as no-ops.

### Lua Standard Library

GenGen exposes a `gengen` table inside Lua plugins that provides helpers for logging, configuration, file operations, paths, and common utilities:

- `gengen.log.info|warn|error(message)` – proxy to GenGen's logger.
- `gengen.config.get(key, default)` – read site configuration values.
- `gengen.paths.plugin(relative)` – resolve paths inside the plugin folder; `plugin_root`, `site_source`, and `site_destination` return absolute paths.
- `gengen.content.read_plugin|read_site(path)` – read files relative to the plugin or site source; `write_site(path, content)` writes into the destination.
- `gengen.util.slugify(value)` – slugify strings, `contains_markdown`, `excerpt(html, maxLength)`, `parse_date`.
- `gengen.plugin.metadata` – structured metadata for the current plugin.

See `examples/plugin-lua-stdlib` for a working plugin that uses these helpers to append slugs, write additional assets, and log status messages.

### Plugin Hooks

Plugins can hook into various stages of the build process:

- `afterInit`: Called after site initialization
- `afterRead`: Called after content is read
- `beforeGenerate`: Called before generators run
- `afterGenerate`: Called after generators run
- `beforeRender`: Called before rendering
- `afterRender`: Called after rendering
- `beforeWrite`: Called before writing files
- `afterWrite`: Called after writing files

### Asset Injection

Plugins can automatically inject CSS, JavaScript, and HTML:

```dart
class Plugin extends BasePlugin {
  @override
  List<String> getCssAssets() {
    return ['styles.css', 'theme.css'];
  }

  @override
  List<String> getJsAssets() {
    return ['main.js', 'utils.js'];
  }

  @override
  String getHeadInjection() {
    return '<meta name="my-plugin" content="enabled">';
  }

  @override
  String getBodyInjection() {
    return '<script>console.log("Plugin loaded");</script>';
  }
}
```

### Plugin Directory Structure

```
_plugins/
  my-plugin/
    config.yaml
    my_plugin.dart
    styles.css
    main.js
    images/
      icon.png
    README.md
```

### Registering Custom Plugins

To make a custom plugin available through the configuration system:

```dart
// In your plugin or site initialization
PluginManager.registerPlugin('MyCustomPlugin', () => MyCustomPlugin());
```

Then use it in configuration:

```yaml
plugins:
  enabled:
    - MyCustomPlugin
```

## Template Integration

To enable automatic asset injection in your templates:

```html
<!DOCTYPE html>
<html>
<head>
    <title>{{ page.title }}</title>
    <!-- Plugin assets will be automatically injected here -->
    {% plugin_head %}
</head>
<body>
    {{ content }}
    
    <!-- Plugin body assets will be automatically injected here -->
    {% plugin_body %}
</body>
</html>
```

## Best Practices

1. **Use plugin groups**: Organize related plugins into logical groups
2. **Start with core**: Always enable at least the core plugin group
3. **Test configurations**: Verify your plugin configuration works as expected
4. **Monitor performance**: Some plugins may impact build times
5. **Keep plugins updated**: Ensure custom plugins work with GenGen updates
6. **Document dependencies**: Clearly document any external tool requirements

## Troubleshooting

### Common Issues

**Plugin not loading:**
- Check that the plugin name is spelled correctly
- Verify the plugin is in the enabled list or group
- Ensure the plugin isn't in the disabled list

**Build errors:**
- Check plugin configuration syntax
- Verify external tool dependencies (e.g., Tailwind CSS executable)
- Review plugin-specific configuration options

**Performance issues:**
- Disable unnecessary plugins
- Check for plugin conflicts
- Monitor build times with different plugin combinations

### Debug Commands

```bash
# Check current plugin status
gengen plugins

# Build with verbose logging
gengen build --verbose

# Check site configuration
gengen dump
```

## Contributing Plugins

When contributing plugins to GenGen:

1. Follow the established plugin structure
2. Include comprehensive documentation
3. Add appropriate tests
4. Consider plugin groups and categorization
5. Ensure compatibility with existing plugins

## Conclusion

GenGen's plugin system provides powerful extensibility while maintaining simplicity through configuration-based management. Whether you're using built-in plugins or developing custom ones, the system is designed to be flexible and developer-friendly.
