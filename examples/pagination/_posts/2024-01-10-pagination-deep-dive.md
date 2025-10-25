---
title: "Deep Dive: GenGen's Powerful Pagination System"
date: 2024-01-10
tags: [gengen, pagination, jekyll, tutorial]
excerpt: "Explore the advanced pagination features in GenGen that rival Jekyll's paginate-v2 plugin, including configuration options, template variables, and best practices."
author: "GenGen Core Team"
featured: true
---

# Deep Dive: GenGen's Powerful Pagination System

GenGen's pagination system is one of its standout features, providing Jekyll-compatible pagination with enhanced capabilities. Let's explore how it works and how to make the most of it.

## Understanding Pagination

Pagination divides your content into manageable chunks, improving both user experience and site performance. Instead of loading hundreds of posts on a single page, pagination creates multiple pages with a subset of content each.

## Configuration Deep Dive

The pagination system is highly configurable through your `config.yaml`:

```yaml
pagination:
  # Enable/disable pagination
  enabled: true
  
  # Posts per page (default: 5)
  items_per_page: 8
  
  # Collection to paginate (posts or pages)
  collection: posts
  
  # URL pattern for pagination pages
  permalink: '/page/:num/'
  
  # Index page template name
  indexpage: index
```

### Advanced Configuration Examples

```yaml
# Custom pagination for different sections
pagination:
  enabled: true
  items_per_page: 12
  collection: posts
  permalink: '/blog/page/:num/'
  indexpage: blog-index
```

## Template Variables Reference

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

## Template Implementation Patterns

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

## Best Practices

### 1. Optimal Page Size
- **8-12 items** per page works well for most blogs
- **16-20 items** for image-heavy content
- **5-8 items** for detailed articles

### 2. SEO Considerations
```html
<!-- Add these to your pagination pages -->
{% if site.paginate.has_previous %}
  <link rel="prev" href="...">
{% endif %}
{% if site.paginate.has_next %}
  <link rel="next" href="...">
{% endif %}
```

### 3. Accessibility
```html
<nav aria-label="Pagination Navigation" role="navigation">
  <!-- Your pagination links -->
</nav>
```

## Advanced Features

### Page Trail Logic
The page trail automatically adjusts based on the current page:
- **Pages 1-3**: Shows [1, 2, 3, 4, 5]
- **Middle pages**: Shows [1, ..., 4, 5, 6, ..., 10]
- **Last pages**: Shows [1, ..., 6, 7, 8, 9, 10]

### Jekyll Compatibility
GenGen's pagination is designed to be drop-in compatible with Jekyll's paginate-v2 plugin, meaning you can:
- Use existing Jekyll pagination templates
- Migrate Jekyll sites seamlessly
- Follow Jekyll pagination tutorials

## Performance Benefits

Pagination improves performance by:
- **Reducing page load times** - Fewer posts to render
- **Better mobile experience** - Less scrolling required
- **Improved SEO** - Search engines can crawl content more efficiently
- **Lower memory usage** - Less content in DOM

## Common Patterns

### Archive Pages
```liquid
<!-- Show pagination info -->
<p>
  Showing {{ site.paginate.items.size }} of {{ site.paginate.total_items }} posts
  (Page {{ site.paginate.current_page }} of {{ site.paginate.total_pages }})
</p>
```

### Featured vs Regular Posts
```liquid
{% for post in site.paginate.items %}
  <article{% if post.featured %} class="featured"{% endif %}>
    <!-- Post content -->
  </article>
{% endfor %}
```

## Troubleshooting

### Common Issues
1. **No pagination appearing**: Check that you have more posts than `items_per_page`
2. **404 on page/2/**: Ensure your web server supports clean URLs
3. **Incorrect post count**: Verify your permalink configuration

### Debug Information
Enable debug mode to see pagination variables:
```liquid
<!-- Development only -->
<details>
  <summary>Debug Info</summary>
  <pre>{{ site.paginate | jsonify }}</pre>
</details>
```

## Conclusion

GenGen's pagination system provides a robust, Jekyll-compatible solution for dividing your content across multiple pages. With proper configuration and template implementation, you can create intuitive navigation that enhances both user experience and site performance.

Try experimenting with different `items_per_page` values and permalink patterns to find what works best for your site! 