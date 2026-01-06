# GenGen Examples

This directory contains example sites demonstrating GenGen's features.

## Quick Start Examples

| Example | Description |
|---------|-------------|
| [basic](basic/) | Minimal site with posts |
| [base](base/) | Simple blog structure |

## Feature Demos

### Content & Layout

| Example | Description |
|---------|-------------|
| [layouts-demo](layouts-demo/) | Layout inheritance and includes |
| [collections-demo](collections-demo/) | Custom collections beyond posts |
| [data](data/) | Using data files (YAML, JSON) |
| [drafts-demo](drafts-demo/) | Draft posts and publishing |

### Templates

| Example | Description |
|---------|-------------|
| [liquid-filters-demo](liquid-filters-demo/) | Liquid template filters |
| [pagination](pagination/) | Paginated post lists |
| [aliases](aliases/) | URL aliases and redirects |

### Styling

| Example | Description |
|---------|-------------|
| [sass](sass/) | SASS/SCSS compilation |
| [tailwind-demo](tailwind-demo/) | Tailwind CSS integration |

### Feeds & SEO

| Example | Description |
|---------|-------------|
| [rss-sitemap-demo](rss-sitemap-demo/) | RSS feed and sitemap generation |

### Configuration

| Example | Description |
|---------|-------------|
| [plugin-config-demo](plugin-config-demo/) | Plugin groups and configuration |
| [modules-demo](modules-demo/) | Module system for themes/plugins |

### Advanced

| Example | Description |
|---------|-------------|
| [docs](docs/) | Documentation site example |
| [heavy-benchmark](heavy-benchmark/) | Performance testing |

## Running an Example

```bash
cd examples/basic
gengen build
gengen serve
```

Or with the module system:

```bash
cd examples/modules-demo
gengen mod get
gengen build
```

## Creating Your Own Site

```bash
gengen new my-site
cd my-site
gengen serve
```
