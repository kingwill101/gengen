---
title: Sass Handling
layout: default
permalink: /sass/
description: Learn how to use Sass/SCSS in GenGen with the _sass directory structure, imports, and compilation.
nav_section: "Styling & Assets"
nav_order: 1
---

# Sass Handling in GenGen

GenGen automatically compiles `.scss` and `.sass` files using the Dart Sass compiler.

## Directory Structure

{% highlight text %}
your-site/
├── _sass/
│   ├── _mixins.scss         # Reusable mixins
│   └── _variables.scss      # Variables
├── css/
│   └── main.scss            # Main stylesheet
└── _themes/
    └── your-theme/
        └── _sass/           # Theme Sass files
{% endhighlight %}

## Import Paths

GenGen automatically configures import paths:

1. Site `_sass/` directory
2. Theme `_sass/` directory

## Usage

**`_sass/_mixins.scss`**:
{% highlight scss %}
@mixin border-radius($radius) {
  -webkit-border-radius: $radius;
  -moz-border-radius: $radius;
  border-radius: $radius;
}
{% endhighlight %}

**`css/main.scss`**:
{% highlight scss %}
@use "mixins" as *;

.button {
  @include border-radius(4px);
}
{% endhighlight %}

## Configuration

{% highlight yaml %}
sass_dir: "_sass"
{% endhighlight %}

## Compilation

- **Input**: `css/main.scss`
- **Output**: `public/css/main.css`

Files in `_sass/` are not compiled directly but are available for import. 
