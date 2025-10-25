---
title: "Syntax Highlighting"
layout: default
permalink: /syntax-highlighting/
description: "Learn how to use GenGen's built-in syntax highlighting with the highlight tag"
nav_section: "Styling & Assets"
nav_order: 2
---

# Syntax Highlighting

GenGen includes built-in syntax highlighting powered by the `highlight` package. Use the `{% highlight %}` Liquid tag to add beautiful code highlighting to your content.

## Basic Usage

The highlight tag supports many programming languages:

{% highlight liquid %}
{% raw %}{% highlight language %}
your code here
{% endhighlight %}{% endraw %}
{% endhighlight %}

## Supported Languages

### YAML Configuration

{% highlight yaml %}
# GenGen configuration example
title: "My GenGen Site"
description: "A static site built with GenGen"

# Build settings
destination: public
permalink: pretty

# Content processing
markdown_extensions:
  - .md
  - .markdown

# Custom data
site:
  author: "Your Name"
  email: "contact@example.com"
{% endhighlight %}

### Dart Code

{% highlight dart %}
import 'dart:io';

class SiteGenerator {
  final String sourceDir;
  final String outputDir;
  
  SiteGenerator(this.sourceDir, this.outputDir);
  
  Future<void> build() async {
    print('Building site from $sourceDir to $outputDir');
    
    // Process markdown files
    await processMarkdownFiles();
    
    // Copy static assets
    await copyAssets();
    
    print('Build completed successfully!');
  }
  
  Future<void> processMarkdownFiles() async {
    final sourceDirectory = Directory(sourceDir);
    await for (final file in sourceDirectory.list(recursive: true)) {
      if (file.path.endsWith('.md')) {
        await processMarkdownFile(file as File);
      }
    }
  }
}
{% endhighlight %}

### JavaScript

{% highlight javascript %}
// GenGen plugin example
class CustomPlugin {
  constructor(config) {
    this.config = config;
    this.name = 'custom-plugin';
  }
  
  async process(site, pages) {
    console.log(`Processing ${pages.length} pages with ${this.name}`);
    
    // Add custom data to each page
    pages.forEach(page => {
      page.data.customField = this.generateCustomData(page);
    });
    
    return pages;
  }
  
  generateCustomData(page) {
    return {
      wordCount: page.content.split(/\s+/).length,
      readingTime: Math.ceil(page.content.split(/\s+/).length / 200),
      lastModified: new Date().toISOString()
    };
  }
}

module.exports = CustomPlugin;
{% endhighlight %}

### HTML Templates

{% highlight html %}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ page.title }} - {{ site.title }}</title>
    <link rel="stylesheet" href="/assets/css/main.css">
</head>
<body>
    <header class="site-header">
        <nav class="main-nav">
            <a href="/" class="site-title">{{ site.title }}</a>
            <ul class="nav-links">
                <li><a href="/about/">About</a></li>
                <li><a href="/posts/">Posts</a></li>
                <li><a href="/contact/">Contact</a></li>
            </ul>
        </nav>
    </header>
    
    <main class="content">
        {{ content }}
    </main>
    
    <footer class="site-footer">
        <p>&copy; {{ "now" | date: "%Y" }} {{ site.author }}</p>
    </footer>
</body>
</html>
{% endhighlight %}

### CSS/SCSS Styles

{% highlight scss %}
// Variables
$primary-color: #2563eb;
$text-color: #1e293b;
$font-family: -apple-system, BlinkMacSystemFont, sans-serif;

// Mixins
@mixin button-style($bg-color: $primary-color) {
  display: inline-block;
  padding: 0.75rem 1.5rem;
  background-color: $bg-color;
  color: white;
  text-decoration: none;
  border-radius: 0.375rem;
  transition: background-color 0.2s ease;
  
  &:hover {
    background-color: darken($bg-color, 10%);
  }
}

// Base styles
body {
  font-family: $font-family;
  color: $text-color;
  line-height: 1.6;
}

.btn {
  @include button-style();
  
  &.btn-secondary {
    @include button-style(#64748b);
  }
}
{% endhighlight %}

### JSON Data

{% highlight json %}
{
  "site": {
    "title": "GenGen Documentation",
    "description": "Complete guide to using GenGen static site generator",
    "version": "1.0.0",
    "features": [
      "Fast build times",
      "Jekyll compatibility", 
      "Plugin system",
      "Sass support",
      "Modern templating"
    ]
  },
  "navigation": [
    {
      "title": "Getting Started",
      "url": "/getting-started/",
      "order": 1
    },
    {
      "title": "Configuration", 
      "url": "/configuration/",
      "order": 2
    },
    {
      "title": "Themes",
      "url": "/themes/",
      "order": 3
    }
  ]
}
{% endhighlight %}

### Shell Scripts

{% highlight bash %}
#!/bin/bash

# GenGen build script
set -e

echo "🚀 Building GenGen site..."

# Clean previous build
if [ -d "public" ]; then
    echo "🧹 Cleaning previous build..."
    rm -rf public
fi

# Install dependencies
echo "📦 Installing dependencies..."
dart pub get

# Build the site
echo "🔨 Building site..."
dart run bin/main.dart build

# Optimize images (if imagemagick is available)
if command -v convert &> /dev/null; then
    echo "🖼️  Optimizing images..."
    find public -name "*.jpg" -o -name "*.png" | while read img; do
        convert "$img" -quality 85 "$img"
    done
fi

# Generate sitemap
echo "🗺️  Generating sitemap..."
find public -name "*.html" | sed 's|public/||' | sed 's|/index.html|/|' > public/sitemap.txt

echo "✅ Build completed successfully!"
echo "📁 Output directory: $(pwd)/public"
{% endhighlight %}

### Python Scripts

{% highlight python %}
#!/usr/bin/env python3
"""
GenGen deployment script
Builds and deploys a GenGen site to various hosting platforms
"""

import os
import subprocess
import argparse
from pathlib import Path

class GenGenDeployer:
    def __init__(self, site_path: str):
        self.site_path = Path(site_path)
        self.public_dir = self.site_path / "public"
    
    def build_site(self) -> bool:
        """Build the GenGen site"""
        print("🔨 Building GenGen site...")
        
        try:
            result = subprocess.run(
                ["gengen", "build"], 
                cwd=self.site_path,
                check=True,
                capture_output=True,
                text=True
            )
            print("✅ Site built successfully!")
            return True
        except subprocess.CalledProcessError as e:
            print(f"❌ Build failed: {e.stderr}")
            return False
    
    def deploy_to_netlify(self, site_id: str) -> bool:
        """Deploy to Netlify"""
        print(f"🚀 Deploying to Netlify (site: {site_id})...")
        
        try:
            subprocess.run([
                "netlify", "deploy", 
                "--prod", 
                "--dir", str(self.public_dir),
                "--site", site_id
            ], check=True)
            print("✅ Deployed to Netlify successfully!")
            return True
        except subprocess.CalledProcessError:
            print("❌ Netlify deployment failed!")
            return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Deploy GenGen site")
    parser.add_argument("--site-path", default=".", help="Path to GenGen site")
    parser.add_argument("--netlify-site-id", help="Netlify site ID")
    
    args = parser.parse_args()
    
    deployer = GenGenDeployer(args.site_path)
    
    if deployer.build_site():
        if args.netlify_site_id:
            deployer.deploy_to_netlify(args.netlify_site_id)
{% endhighlight %}

## Advanced Features

### No Language Specified

When no language is specified, the highlight tag defaults to plain text:

{% highlight %}
This is plain text without syntax highlighting.
It's useful for showing output or simple text content.
{% endhighlight %}

### Liquid Template Code

To show Liquid template code itself, use the `liquid` language:

{% highlight liquid %}
<!-- Show current page title -->
<h1>{{ page.title }}</h1>

<!-- Loop through posts -->
{% for post in site.posts %}
  <article>
    <h2><a href="{{ post.url }}">{{ post.title }}</a></h2>
    <time>{{ post.date | date: "%B %d, %Y" }}</time>
    <p>{{ post.excerpt }}</p>
  </article>
{% endfor %}

<!-- Include partial -->
{% include 'sidebar' %}
{% endhighlight %}

## Usage Tips

1. **Choose the right language** - Use specific language identifiers for better highlighting
2. **Keep code readable** - Don't make code blocks too long
3. **Add context** - Explain what the code does before or after the block
4. **Use consistent indentation** - Maintain proper formatting in your code blocks

The highlight tag makes your documentation more readable and professional. Use it throughout your GenGen site to showcase code examples beautifully! 
