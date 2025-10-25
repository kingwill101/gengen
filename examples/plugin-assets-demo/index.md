---
layout: default
title: Plugin Asset Injection Demo
---

# Plugin Asset Injection Demo

This page demonstrates GenGen's automatic plugin asset injection system.

## How It Works

The demo plugin automatically injects:

1. **CSS styles** - Notice the styling of elements below
2. **JavaScript functionality** - Check the browser console and interactive elements
3. **Meta tags** - View the page source to see injected meta tags
4. **Custom HTML** - Additional content injected into head and body

## Demo Elements

<div class="demo-plugin-highlight">
This is a highlighted section styled by the plugin's CSS. The plugin will also add an interactive button here.
</div>

<div class="demo-plugin-highlight">
Another highlighted section to show multiple elements are processed.
</div>

## Check the Browser

1. **View Page Source** - Look for injected meta tags and HTML comments
2. **Open Developer Console** - See messages from the plugin's JavaScript
3. **Inspect Network Tab** - Notice the automatically loaded CSS and JS files

## Asset URLs

Plugin assets are served from:
- CSS: `/assets/plugins/demo-plugin/plugin-styles.css`
- JS: `/assets/plugins/demo-plugin/plugin-main.js`

This all happens automatically without any manual configuration! 