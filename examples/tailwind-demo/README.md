# Tailwind CSS Demo for GenGen

This example demonstrates how to use the TailwindPlugin with GenGen to automatically compile Tailwind CSS.

## Setup

1. **Download Tailwind CSS Standalone CLI**
   ```bash
   # Download for your platform from https://tailwindcss.com/blog/standalone-cli
   # For Linux/Mac:
   curl -sLO https://github.com/tailwindlabs/tailwindcss/releases/latest/download/tailwindcss-linux-x64
   chmod +x tailwindcss-linux-x64
   mv tailwindcss-linux-x64 tailwindcss
   ```

2. **Create your Tailwind CSS input file**
   Create `assets/css/tailwind.css`:
   ```css
   @tailwind base;
   @tailwind components;
   @tailwind utilities;
   ```

3. **Build the site**
   ```bash
   gengen build
   ```

## How it Works

The TailwindPlugin automatically:

1. **Detects** your Tailwind input file (`assets/css/tailwind.css` by default)
2. **Compiles** it using the Tailwind CSS standalone CLI
3. **Outputs** the compiled CSS to your destination directory (`assets/css/styles.css` by default)
4. **Runs** after all content is rendered to ensure classes are detected

## Customization

You can customize the plugin behavior:

```dart
// In your GenGen library usage
final generator = GenGen()
  ..plugin(TailwindPlugin(
    tailwindPath: './bin/tailwindcss',
    input: 'src/styles/tailwind.css',
    output: 'dist/css/app.css',
  ));
```

## Default Configuration

- **Tailwind executable**: `./tailwindcss`
- **Input file**: `assets/css/tailwind.css`
- **Output file**: `assets/css/styles.css`

## File Structure

```
your-site/
├── tailwindcss              # Tailwind CSS executable
├── assets/css/tailwind.css  # Your Tailwind input file
├── _layouts/default.html    # Layout referencing compiled CSS
├── index.html               # Your content with Tailwind classes
└── public/                  # Build output
    └── assets/css/styles.css # Compiled CSS (generated)
```

## Features

- ✅ Automatic compilation after rendering
- ✅ Graceful handling of missing files
- ✅ Customizable paths and executable location
- ✅ Works with the complete Tailwind CSS feature set
- ✅ Production-ready CSS output 