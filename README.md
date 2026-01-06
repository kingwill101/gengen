## GenGen

[![Dart](https://github.com/kingwill101/gengen/actions/workflows/dart.yml/badge.svg)](https://github.com/kingwill101/gengen/actions/workflows/dart.yml)

A powerful static site generator written in Dart that can be used both as a CLI tool and as a library. GenGen provides Jekyll-compatible features with modern Dart architecture and a clean, fluent API.

## Features

- **Jekyll Compatibility**: Uses identical template variables, Liquid syntax, and configuration
- **CLI & Library**: Use as a command-line tool or embed in your Dart applications
- **Simple, Fluent API**: Inspired by StaticShock and Jaspr for minimal setup
- **Plugin System**: Extensible architecture with built-in and custom plugins
- **Modern Architecture**: Written in Dart with async/await support
- **Fast & Efficient**: Optimized for performance and memory usage
- **Developer Friendly**: Hot reload, file watching, and comprehensive error handling

## Installation

### CLI Usage

Install globally:

```bash
dart pub global activate gengen
```

### Library Usage

Add to your `pubspec.yaml`:

```yaml
dependencies:
  gengen: ^0.0.1
```

## Quick Start

### Command Line

```bash
# Create a new site
gengen new my-site
cd my-site

# Build the site
gengen build

# Serve with hot reload
gengen serve
```

> Need a bolder look? Pass `--theme=aurora` when running `gengen new site` to scaffold with the Aurora theme.

## Docs Platform

GenGen ships with a full documentation theme and scaffold so you can spin up product docs without starting from scratch.

```bash
# Scaffold a docs site
gengen new docs my-docs-site
cd my-docs-site

# Preview locally
gengen serve

# Produce the static output
gengen build
```

- Navigation lives in `_data/docs/navigation.yml`; update the sidebar by editing this file rather than the layouts.
- Each Markdown page should declare `nav_section` and `nav_order` in its front matter so the sidebar stays in sync.
- The scaffold installs the reusable theme under `_themes/docs-platform`—swap colors or Sass there without touching layouts.
- Deploy the generated `public/` directory to any static host. The repo includes step-by-step guides in `docs/deploy-github.md` and `docs/deploy-netlify.md`.

The repository itself uses this platform under the `docs/` directory, so you can reference it as a working example.

### Library Usage

```dart
import 'package:gengen/gengen.dart';

void main() async {
  final generator = GenGen()
    ..source('./content')
    ..destination('./build')
    ..title('My Site')
    ..plugin(MarkdownPlugin());
  
  await generator.build();
}
```

## Why GenGen?

GenGen combines the best of Jekyll's simplicity with Dart's modern language features and a clean, chainable API inspired by StaticShock and Jaspr. Whether you're building a blog, documentation site, or need programmatic static site generation, GenGen provides the tools you need.

**Key advantages:**
- **Simple API**: Chain methods with `..` for intuitive configuration
- **No Complex Setup**: Works out of the box with sensible defaults
- **Jekyll Migration**: Easy migration from Jekyll sites
- **Type Safety**: Dart's type system catches errors early
- **Performance**: Fast builds and efficient memory usage
- **Extensibility**: Plugin system for custom functionality

## Library Examples

### Basic Blog

```dart
final blog = GenGen()
  ..source('./posts')
  ..destination('./blog-output')
  ..title('My Development Blog')
  ..plugin(MarkdownPlugin())
  ..plugin(PaginationPlugin());

await blog.build();
```

### Documentation Site

```dart
final docs = GenGen()
  ..source('./docs')
  ..destination('./docs-site')
  ..title('Project Documentation')
  ..plugin(MarkdownPlugin())
  ..plugin(SassPlugin())
  ..config({
    'markdown': {'auto_ids': true},
    'sass': {'style': 'compressed'},
  });

await docs.build();
```

### Development Server

```dart
await generator.serve(port: 4000, watch: true);
```

## Usage

### CLI Commands

```
Usage: gengen <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:
  build   Build static site
  serve   Serve site with development server
  new     Create a new site
  dump    Dump site information
```

### Library API

## Testing & Coverage

Run the test suite:

```bash
dart test
```

Generate an LCOV coverage report (saved to `coverage/lcov.info`):

```bash
just coverage
```

If `lcov`/`genhtml` is installed, you can also generate HTML output:

```bash
just coverage-html
```

See [README_LIBRARY.md](README_LIBRARY.md) for comprehensive library documentation.

## Documentation

- [Library Usage Guide](README_LIBRARY.md) - Complete library API documentation
- [Plugin Development](docs/plugins.md) - Creating custom plugins
- [Configuration](docs/configuration.md) - Site configuration options
- [Examples](examples/) - Working examples and use cases

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This project is licensed under the MIT License.

```agsl

Usage: gengen <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:
  build   Build static site


```
