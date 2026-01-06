# Docs Platform Theme

The Docs Platform theme provides a reusable documentation experience for GenGen projects. It ships with opinionated layouts, navigation components, callouts, and styling so you can bootstrap a docs site quickly without rewriting UI fundamentals.

## Features

- Data-driven sidebar navigation powered by `_data/docs/navigation.yml`
- Responsive header with optional search placeholder
- Built-in breadcrumb trail, previous/next navigation, and table-of-contents slot
- Callout component for highlighting tips, warnings, and references
- Sass partials exposing variables and mixins for easy customization

## File Structure

```
docs/_themes/docs-platform/
├── config.yaml
├── README.md
├── content/
│   └── index.html
├── _layouts/
│   ├── default.html
│   └── home.html
├── _includes/
│   ├── head.html
│   ├── header.html
│   ├── footer.html
│   ├── sidebar.html
│   ├── breadcrumbs.html
│   ├── search.html
│   ├── toc.html
│   ├── page-header.html
│   ├── page-navigation.html
│   └── components/
│       └── callout.html
├── _sass/
│   ├── _variables.scss
│   ├── _mixins.scss
│   ├── _base.scss
│   ├── _layout.scss
│   ├── _sidebar.scss
│   ├── _header.scss
│   └── _callouts.scss
├── assets/
│   ├── css/
│   │   └── main.scss
│   └── js/
│       └── docs.js
```

## Usage

1. Enable the theme in your documentation site's `config.yaml`:

   ```yaml
   theme: "docs-platform"
   ```

2. Define navigation metadata in `_data/docs/navigation.yml`. The theme expects sections, pages, quick links, and footer links to live under this key. Theme-level `_data` is merged into `site.data`, and site `_data` overrides theme defaults.

3. Include the compiled stylesheet in your layout (already handled by `head.html`). If you need further customization, override or extend the Sass partials in your site.

4. Use the callout component inside Markdown with the `render` tag:

   ```liquid
   {% render 'components/callout', variant: 'info', title: 'Heads up!' %}
   This is an informational callout.
   {% endrender %}
   ```

5. Optional: wire up your own search provider by enhancing the `search.html` include or replacing it in your site.

## Theme Pages

The Docs Platform theme can ship pages via the `content/` directory. Any theme
content file with YAML front matter is treated as a page and rendered into the
final site output using its relative path inside `content/`. If your site provides
the same relative path, the site page overrides the theme page.

## Overriding Parts of the Theme

GenGen will prioritize site-level includes/layouts over theme-provided ones. To override a component:

1. Copy the relevant file from `_themes/docs-platform/_includes/...`.
2. Place it under your site's `_includes` directory with the same relative path.
3. Customize as needed.

The same approach works for layouts and Sass partials.
