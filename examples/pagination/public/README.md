# GenGen Pagination Example

This comprehensive example demonstrates the powerful pagination features built into GenGen, showcasing a Jekyll-compatible pagination system that rivals jekyll-paginate-v2.

## 🚀 Quick Start

1. **Navigate to this directory:**
   ```bash
   cd examples/pagination
   ```

2. **Build the site:**
   ```bash
   # From the GenGen root directory
   dart run bin/gengen.dart build --source examples/pagination
   ```

3. **View the result:**
   Open `examples/pagination/public/index.html` in your browser to see the paginated blog.

## 📁 Project Structure

```
examples/pagination/
├── README.md                          # This documentation
├── config.yaml                        # Site configuration with pagination settings
├── index.html                         # Main pagination template
├── _posts/                           # Sample blog posts (26 posts total)
│   ├── 2024-01-15-getting-started-gengen.md
│   ├── 2024-01-10-pagination-deep-dive.md
│   └── 2024-01-*-blog-post-*.md     # 25+ sample posts
├── _includes/
│   └── pagination-styles.css        # Styling for the pagination demo
└── public/                          # Generated site (after build)
    ├── index.html                   # Page 1 (first 8 posts)
    ├── page/
    │   ├── 2/index.html            # Page 2 (next 8 posts)
    │   ├── 3/index.html            # Page 3 (next 8 posts)
    │   └── 4/index.html            # Page 4 (remaining posts)
    └── posts/                      # Individual post pages
```

## ⚙️ Configuration Explained

The pagination is configured in `config.yaml`:

```yaml
pagination:
  enabled: true              # Enable pagination
  items_per_page: 8         # 8 posts per page (creates 4 pages from 26 posts)
  collection: posts         # Paginate the posts collection
  permalink: '/page/:num/'  # URL pattern: /page/2/, /page/3/, etc.
  indexpage: index          # Use index.html as the pagination template
```

### Configuration Options

| Option | Description | Default | Example |
|--------|-------------|---------|---------|
| `enabled` | Enable/disable pagination | `true` | `false` |
| `items_per_page` | Posts per page | `5` | `8`, `10`, `15` |
| `collection` | What to paginate | `posts` | `posts`, `pages` |
| `permalink` | URL pattern for pages | `/page/:num/` | `/blog/page/:num/` |
| `indexpage` | Template file name | `index` | `blog`, `archive` |

## 🎯 Key Features Demonstrated

### 1. **Jekyll Compatibility**
- Uses identical variable names and patterns as Jekyll's paginate-v2
- Drop-in replacement for existing Jekyll pagination templates
- Same Liquid template syntax

### 2. **Smart URL Generation**
- Page 1: `/` (root index)
- Page 2+: `/page/2/`, `/page/3/`, etc.
- Clean, SEO-friendly URLs

### 3. **Page Trail Logic**
- Shows optimal number of page links
- Automatically adjusts based on current page
- Example with 4 total pages: `[1, 2, 3, 4]`

### 4. **Responsive Design**
- Mobile-friendly pagination controls
- Grid layout that adapts to screen size
- Touch-friendly navigation buttons

### 5. **Accessibility Features**
- Proper ARIA labels
- Semantic HTML structure
- Keyboard navigation support
- Screen reader friendly

## 🛠️ Template Variables Reference

When pagination is active, these variables are available in your templates:

### Core Variables
- `site.paginate.items` - Array of posts/pages for current page
- `site.paginate.current_page` - Current page number (1, 2, 3...)
- `site.paginate.total_pages` - Total number of pages
- `site.paginate.items_per_page` - Items per page setting
- `site.paginate.total_items` - Total number of items being paginated

### Navigation Variables
- `site.paginate.has_previous` - Boolean: has previous page
- `site.paginate.has_next` - Boolean: has next page
- `site.paginate.page_trail` - Array for navigation (e.g., [1,2,3,4,5])

## 🎨 Template Implementation Examples

### Basic Post Loop
```liquid
{% for post in site.paginate.items %}
  <article>
    <h2><a href="{{ post.url }}">{{ post.title }}</a></h2>
    <time>{{ post.date | date: '%B %d, %Y' }}</time>
    <p>{{ post.excerpt }}</p>
  </article>
{% endfor %}
```

### Smart Navigation
```liquid
<!-- Previous Page -->
{% if site.paginate.has_previous %}
  <a href="{% if site.paginate.current_page == 2 %}/{% else %}/page/{{ site.paginate.current_page | minus: 1 }}/{% endif %}">
    ← Previous
  </a>
{% endif %}

<!-- Page Numbers -->
{% for page_num in site.paginate.page_trail %}
  {% if page_num == site.paginate.current_page %}
    <span class="current">{{ page_num }}</span>
  {% else %}
    <a href="{% if page_num == 1 %}/{% else %}/page/{{ page_num }}/{% endif %}">
      {{ page_num }}
    </a>
  {% endif %}
{% endfor %}

<!-- Next Page -->
{% if site.paginate.has_next %}
  <a href="/page/{{ site.paginate.current_page | plus: 1 }}/">
    Next →
  </a>
{% endif %}
```

## 📊 Performance Benefits

This pagination implementation provides:

1. **Faster Page Loads**: Only 8 posts loaded per page instead of all 26
2. **Better SEO**: Search engines can crawl paginated content efficiently  
3. **Improved UX**: Users can navigate content in digestible chunks
4. **Mobile Friendly**: Less scrolling on mobile devices
5. **Memory Efficient**: Reduced DOM size improves performance

## 🔧 Customization Guide

### Change Items Per Page
```yaml
# Show more posts per page
pagination:
  items_per_page: 12  # Will create fewer pages
```

### Custom URL Pattern
```yaml
# Use /blog/page/2/ instead of /page/2/
pagination:
  permalink: '/blog/page/:num/'
```

### Different Collection
```yaml
# Paginate pages instead of posts
pagination:
  collection: pages
```

### Custom Template
```yaml
# Use a different template file
pagination:
  indexpage: blog-archive  # Uses blog-archive.html
```

## 🎨 Styling Features

The included CSS (`_includes/pagination-styles.css`) provides:

- **Modern card-based design** for posts
- **Responsive grid layout**
- **Interactive hover effects**
- **Clean pagination controls**
- **Mobile-optimized navigation**

## 🐛 Troubleshooting

### Common Issues

**1. Pagination not appearing**
- Ensure you have more posts than `items_per_page`
- Check that `pagination.enabled` is `true`
- Verify posts are in the `_posts` directory with correct naming

**2. 404 errors on page/2/**
- Check your web server configuration
- Ensure it supports clean URLs without `.html` extensions
- Verify the build completed successfully

**3. Incorrect post count**
- Check post front matter dates
- Ensure posts aren't marked as drafts
- Verify `show_drafts` configuration

**4. Styling issues**
- Ensure `_includes/pagination-styles.css` is included
- Check for CSS conflicts with other styles
- Verify the include path is correct

### Debug Information

The example includes a debug panel that shows all pagination variables in real-time:

- Current page number
- Total pages
- Items per page
- Total items
- Navigation state
- Page trail array
- Items on current page

This helps understand how the pagination system works internally.

## 🔧 Advanced Usage

### SEO Optimization
Add these to your `<head>` section:

```html
{% if site.paginate.has_previous %}
  <link rel="prev" href="{% if site.paginate.current_page == 2 %}/{% else %}/page/{{ site.paginate.current_page | minus: 1 }}/{% endif %}">
{% endif %}
{% if site.paginate.has_next %}
  <link rel="next" href="/page/{{ site.paginate.current_page | plus: 1 }}/">
{% endif %}
```

### Multiple Pagination Instances
You can create multiple paginated sections by:

1. Creating different configuration files
2. Using different `indexpage` templates  
3. Setting up different `permalink` patterns

## 📚 Learn More

This example demonstrates the full power of GenGen's pagination system. Experiment with different configurations, customize the styling, and adapt the templates to fit your specific needs.

For more information about GenGen's features, check out the main documentation and other examples in this repository.

---

**Happy paginating! 🎉**
