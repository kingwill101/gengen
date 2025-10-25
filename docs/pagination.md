---
title: "Pagination"
layout: default
permalink: /pagination/
description: "Setting up automatic pagination for posts and content"
nav_section: "Advanced Features"
nav_order: 1
---

# Pagination in GenGen

GenGen provides a powerful pagination system that allows you to split your content across multiple pages, similar to Jekyll's paginate-v2 plugin. This guide covers everything you need to know about setting up and using pagination in your GenGen site.

## Overview

The pagination system automatically creates multiple pages from your posts or pages, with each page containing a specified number of items. For example, if you have 27 posts and set `items_per_page: 5`, GenGen will create 6 pages:

- **Page 1**: `/` (your index.html) - Posts 1-5
- **Page 2**: `/page/2/` - Posts 6-10  
- **Page 3**: `/page/3/` - Posts 11-15
- **Page 4**: `/page/4/` - Posts 16-20
- **Page 5**: `/page/5/` - Posts 21-25
- **Page 6**: `/page/6/` - Posts 26-27

## Configuration

### Basic Configuration

Add pagination configuration to your `config.yaml`:

```yaml
pagination:
  enabled: true
  items_per_page: 5
  collection: posts
  permalink: '/page/:num/'
  indexpage: index
```

### Configuration Options

- **`enabled`**: Boolean - Enable or disable pagination (default: `false`)
- **`items_per_page`**: Integer - Number of items per page (default: `5`)
- **`collection`**: String - Collection to paginate: `posts` or `pages` (default: `posts`)
- **`permalink`**: String - URL pattern for pagination pages (default: `/page/:num/`)
- **`indexpage`**: String - Name of the index template without extension (default: `index`)

### Advanced Configuration

```yaml
pagination:
  enabled: true
  items_per_page: 10
  collection: posts
  permalink: '/blog/page/:num/'
  indexpage: blog-index
```

## Required Files

### Index Template (Required)

**⚠️ Critical Requirement**: Pagination requires an `index.html` file in your site root. Without this file, pagination will fail with a clear error message.

Create `index.html` with pagination template code:

```html
---
layout: default
title: "My Blog"
---

<h1>Latest Posts</h1>

<!-- Check if we have paginated items -->
{% if page.paginate.items.size > 0 %}
  
  <!-- Post listing -->
  <div class="posts">
    {% for post in page.paginate.items %}
      <article class="post">
        <h2><a href="{{ post.url }}">{{ post.title }}</a></h2>
        <p class="meta">Published: {{ post.date | date: '%B %d, %Y' }}</p>
        <p>{{ post.excerpt }}</p>
        <a href="{{ post.url }}">Read more →</a>
      </article>
    {% endfor %}
  </div>
  
  <!-- Pagination navigation -->
  {% if page.paginate.total_pages > 1 %}
    <nav class="pagination">
      <!-- Previous page link -->
      {% if page.paginate.has_previous %}
        <a href="{% if page.paginate.current_page == 2 %}/{% else %}/page/{{ page.paginate.current_page | minus: 1 }}/{% endif %}" class="prev">
          ← Previous
        </a>
      {% endif %}
      
      <!-- Page numbers -->
      {% for page_num in page.paginate.page_trail %}
        {% if page_num == page.paginate.current_page %}
          <span class="current">{{ page_num }}</span>
        {% else %}
          <a href="{% if page_num == 1 %}/{% else %}/page/{{ page_num }}/{% endif %}">
            {{ page_num }}
          </a>
        {% endif %}
      {% endfor %}
      
      <!-- Next page link -->
      {% if page.paginate.has_next %}
        <a href="/page/{{ page.paginate.current_page | plus: 1 }}/" class="next">
          Next →
        </a>
      {% endif %}
    </nav>
  {% endif %}
  
{% else %}
  <p>No posts found.</p>
{% endif %}
```

## Template Variables

### Core Pagination Variables

All pagination data is accessed through `page.paginate.*`:

- **`page.paginate.items`**: Array of items for the current page
- **`page.paginate.current_page`**: Current page number (1, 2, 3, etc.)
- **`page.paginate.total_pages`**: Total number of pages
- **`page.paginate.items_per_page`**: Number of items per page
- **`page.paginate.total_items`**: Total number of items being paginated
- **`page.paginate.has_previous`**: Boolean - true if there's a previous page
- **`page.paginate.has_next`**: Boolean - true if there's a next page
- **`page.paginate.page_trail`**: Array of page numbers for navigation (e.g., [1, 2, 3, 4, 5])

### Navigation Variables

```liquid
<!-- Page information -->
<p>
  Page {{ page.paginate.current_page }} of {{ page.paginate.total_pages }}
  ({{ page.paginate.items.size }} of {{ page.paginate.total_items }} posts)
</p>

<!-- Previous page URL -->
{% if page.paginate.has_previous %}
  {% assign prev_page = page.paginate.current_page | minus: 1 %}
  {% if prev_page == 1 %}
    <a href="/">Previous</a>
  {% else %}
    <a href="/page/{{ prev_page }}/">Previous</a>
  {% endif %}
{% endif %}

<!-- Next page URL -->
{% if page.paginate.has_next %}
  {% assign next_page = page.paginate.current_page | plus: 1 %}
  <a href="/page/{{ next_page }}/">Next</a>
{% endif %}
```

## Template Examples

### Simple Post Listing

```liquid
{% for post in page.paginate.items %}
  <div class="post-preview">
    <h3><a href="{{ post.url }}">{{ post.title }}</a></h3>
    <p class="date">{{ post.date | date: '%B %d, %Y' }}</p>
    <p>{{ post.excerpt | strip_html | truncatewords: 30 }}</p>
  </div>
{% endfor %}
```
