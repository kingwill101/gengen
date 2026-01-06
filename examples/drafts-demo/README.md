# Drafts Demo

This example demonstrates GenGen's draft post system.

## Features

- Draft posts in `_drafts/` folder
- Posts with `draft: true` in frontmatter
- Future-dated posts
- Preview drafts during development

## Usage

```bash
# Build without drafts (production)
gengen build

# Build with drafts (development)
gengen build --drafts

# Serve with drafts
gengen serve --drafts
```

## Draft Methods

### 1. _drafts Folder

Put unfinished posts in `_drafts/`:

```
_drafts/
  my-draft-post.md    # No date needed in filename
```

### 2. Frontmatter Flag

Add `draft: true` to any post:

```yaml
---
title: "Work in Progress"
draft: true
---
```

### 3. Future Dates

Posts with dates in the future are treated as drafts:

```yaml
---
title: "Scheduled Post"
date: 2025-12-31
---
```

## Configuration

```yaml
# config.yaml
publish_drafts: false  # Set to true to include drafts in production
```
