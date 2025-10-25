---
layout: default
title: Asset-Only Plugin Demo
---

# Asset-Only Plugin Demo

This page demonstrates GenGen's asset-only plugin system. The syntax highlighter plugin was created **without any Dart code** - just CSS, JavaScript, and configuration!

## Features Provided by Asset-Only Plugin

1. **Custom Monokai Theme** - Dark syntax highlighting theme
2. **Line Numbers** - Automatic line numbering for code blocks  
3. **Copy Button** - Click to copy code to clipboard
4. **Custom Meta Tags** - SEO and feature detection
5. **Initialization Scripts** - Automatic setup when page loads

## Example Code Block

```javascript
// This code block is styled by the asset-only plugin
function greetUser(name) {
    console.log(`Hello, ${name}!`);
    
    // The plugin automatically adds:
    // - Monokai syntax highlighting
    // - Line numbers on the left
    // - Copy button in top-right corner
    
    return `Welcome to GenGen, ${name}!`;
}

// Try clicking the copy button!
greetUser('Developer');
```

## Python Example

```python
# Another example with Python syntax
def fibonacci(n):
    """Generate Fibonacci sequence up to n terms."""
    if n <= 0:
        return []
    elif n == 1:
        return [0]
    elif n == 2:
        return [0, 1]
    
    sequence = [0, 1]
    for i in range(2, n):
        sequence.append(sequence[i-1] + sequence[i-2])
    
    return sequence

# Generate first 10 Fibonacci numbers
result = fibonacci(10)
print(f"First 10 Fibonacci numbers: {result}")
```

## How It Works

The asset-only plugin system automatically:

1. **Detects asset files** (CSS, JS) in the plugin directory
2. **Copies them** to `/assets/plugins/syntax-highlighter/`
3. **Injects CSS links** into the `<head>` section
4. **Injects JS scripts** before `</body>`
5. **Adds custom HTML** from the plugin configuration
6. **Includes meta tags** for feature detection

## Plugin Configuration

This was achieved with just a `config.yaml` file:

```yaml
name: SyntaxHighlighter
description: A pure asset-only plugin
version: 1.0.0

head_injection: |
  <meta name="syntax-highlighter" content="enabled">

body_injection: |
  <script>
    console.log('Syntax Highlighter Plugin loaded!');
  </script>

css_assets:
  - monokai-theme.css
  - line-numbers.css
  - copy-button.css

js_assets:
  - highlight-init.js
  - copy-button.js
```

**No Dart code required!** Just static assets and configuration. 