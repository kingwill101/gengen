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
{% assign group_key = group[0] %}
{% assign group_data = group[1] %}
- **{{ group_key }}**: {{ group_data.description }}
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
{% for group in site.data.plugins.groups %}{% assign group_data = group[1] %}    {{ group[0] }}:
{% for plugin in group_data.plugins %}      - {{ plugin.class_name }}
{% endfor %}
{% endfor %}
```

### Configuration Examples

{% for example in site.data.plugins.examples %}
{% assign example_data = example[1] %}
**{{ example_data.description }}:**
```yaml
{{ example_data.config | jsonify }}
```
{% endfor %}

## Built-in Plugins

GenGen comes with several built-in plugins that provide core functionality:

{% for group in site.data.plugins.groups %}
{% assign group_data = group[1] %}
### {{ group_data.name }}

{{ group_data.description }}

{% for plugin in group_data.plugins %}
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
{% assign example_data = example[1] %}
### {{ example_data.name }}

{{ example_data.description }}

```yaml
{{ example_data.config }}
```

{% endfor %}

## Writing Custom Plugins

GenGen custom plugins are **Lua-based** and auto-discovered. Each plugin lives in its
own directory with a `config.yaml` and a Lua entrypoint.

> Legacy Dart-based plugins are still discovered but will log warnings during load.
> New plugins should use Lua.

### Where plugins live

GenGen loads plugins from two locations:

- **Site plugins**: `<site>/_plugins/<plugin>/`
- **Theme plugins**: `<site>/_themes/<theme>/_plugins/<plugin>/`

You can customize the site plugins folder with `plugin_dir` in `config.yaml`
(default: `_plugins`).

### Plugin directory structure

```
_plugins/
  my-plugin/
    config.yaml
    main.lua
    assets/
      banner.css

_themes/
  default/
    _plugins/
      theme-banner/
        config.yaml
        main.lua
        theme.css
```

### Plugin config reference

{% include docs_reference_table.html scope=site.data.lua_plugins.config_fields %}

Example with explicit files:

```yaml
name: site-enhancer
entrypoint: main.lua:init_plugin
description: Adds a callout and writes extra output.
files:
  - name: styles
    path: "assets/*.css"
  - name: banner
    path: "images/banner.png"
```

If `files` is omitted, GenGen scans the plugin directory and registers all files.
Non-Lua files are copied to `/assets/plugins/<plugin-name>/`.

### Quick start: site plugin

**`_plugins/my-plugin/config.yaml`:**
```yaml
name: my-plugin
entrypoint: main.lua:init_plugin
description: A custom plugin for GenGen
author: Your Name
version: 1.0.0
```

**`_plugins/my-plugin/main.lua`:**
```lua
function init_plugin(metadata)
  return {
    head_injection = '<meta name="my-plugin" content="enabled">',

    css_assets = { 'assets/styles.css' },

    convert = function(content, page)
      return '<div class="plugin-callout">Injected by Lua</div>\n' .. content
    end,

    after_generate = function()
      gengen.content.write_site('assets/my-plugin.txt', 'Generated by my-plugin')
    end
  }
end
```

### Quick start: theme plugin

**`_themes/default/_plugins/theme-banner/config.yaml`:**
```yaml
name: theme-banner
entrypoint: main.lua:init_plugin
description: Theme-level badge and CSS.
```

**`_themes/default/_plugins/theme-banner/main.lua`:**
```lua
function init_plugin(metadata)
  return {
    css_assets = { 'theme.css' },
    body_injection = '<div class="plugin-pill">Theme plugin active</div>'
  }
end
```

### Lua hook reference

All hook names are **snake_case**. Missing hooks are treated as no-ops.

#### Lifecycle hooks

{% include docs_reference_table.html scope=site.data.lua_plugins.hooks.lifecycle %}

#### Convert hook

{% include docs_reference_table.html scope=site.data.lua_plugins.hooks.convert %}

#### Asset and head hooks

{% include docs_reference_table.html scope=site.data.lua_plugins.hooks.assets %}

Asset paths are **relative to the plugin directory** and are served at
`/assets/plugins/<plugin-name>/<asset-path>`.

#### Liquid filters

{% include docs_reference_table.html scope=site.data.lua_plugins.hooks.liquid %}

Filters receive `(value, args, named_args)` and return the transformed value.

```lua
liquid_filters = {
  shout = function(value, args, named)
    return string.upper(tostring(value))
  end
}
```

### Page object in `convert`

The `page` argument is a plain Lua table derived from the internal document model.

{% include docs_reference_table.html scope=site.data.lua_plugins.page_object %}

### Lua standard library (`gengen` table)

GenGen exposes a standard library inside Lua plugins:

#### Logging

{% include docs_reference_table.html scope=site.data.lua_plugins.stdlib.log %}

#### Configuration

{% include docs_reference_table.html scope=site.data.lua_plugins.stdlib.config %}

#### Paths

{% include docs_reference_table.html scope=site.data.lua_plugins.stdlib.paths %}

#### Content

{% include docs_reference_table.html scope=site.data.lua_plugins.stdlib.content %}

#### Utilities

{% include docs_reference_table.html scope=site.data.lua_plugins.stdlib.util %}

#### Plugin metadata

{% include docs_reference_table.html scope=site.data.lua_plugins.stdlib.plugin %}

### Execution order

Plugins run in discovery order: **site plugins first**, then **theme plugins**.
Conversion hooks run after Liquid renders content and before layout rendering.

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

`{% plugin_head %}` injects `head_injection`, CSS assets, and meta tags from plugins.
`{% plugin_body %}` injects `body_injection` and JavaScript assets.

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
