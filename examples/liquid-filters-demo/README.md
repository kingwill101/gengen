# Liquid Filters Demo

This example demonstrates Liquid filters available in GenGen.

## String Filters

| Filter | Example | Output |
|--------|---------|--------|
| `upcase` | `{{ "hello" \| upcase }}` | HELLO |
| `downcase` | `{{ "HELLO" \| downcase }}` | hello |
| `capitalize` | `{{ "hello world" \| capitalize }}` | Hello world |
| `strip` | `{{ "  hello  " \| strip }}` | hello |
| `truncate` | `{{ "hello world" \| truncate: 8 }}` | hello... |
| `replace` | `{{ "hello" \| replace: "l", "L" }}` | heLLo |
| `split` | `{{ "a,b,c" \| split: "," }}` | [a, b, c] |
| `slugify` | `{{ "Hello World!" \| slugify }}` | hello-world |

## Array Filters

| Filter | Example | Description |
|--------|---------|-------------|
| `first` | `{{ array \| first }}` | First element |
| `last` | `{{ array \| last }}` | Last element |
| `size` | `{{ array \| size }}` | Array length |
| `sort` | `{{ array \| sort }}` | Sort ascending |
| `reverse` | `{{ array \| reverse }}` | Reverse order |
| `join` | `{{ array \| join: ", " }}` | Join with separator |
| `where` | `{{ posts \| where: "draft", false }}` | Filter by property |

## Date Filters

| Filter | Example | Output |
|--------|---------|--------|
| `date` | `{{ page.date \| date: "%Y-%m-%d" }}` | 2024-01-15 |
| `date` | `{{ page.date \| date: "%B %d, %Y" }}` | January 15, 2024 |
| `date` | `{{ "now" \| date: "%Y" }}` | Current year |

## URL Filters

| Filter | Example | Description |
|--------|---------|-------------|
| `url_encode` | `{{ "hello world" \| url_encode }}` | hello%20world |
| `relative_url` | `{{ "/page" \| relative_url }}` | Prepends baseurl |
| `absolute_url` | `{{ "/page" \| absolute_url }}` | Full URL |

## Math Filters

| Filter | Example | Output |
|--------|---------|--------|
| `plus` | `{{ 5 \| plus: 3 }}` | 8 |
| `minus` | `{{ 5 \| minus: 3 }}` | 2 |
| `times` | `{{ 5 \| times: 3 }}` | 15 |
| `divided_by` | `{{ 10 \| divided_by: 2 }}` | 5 |
| `modulo` | `{{ 10 \| modulo: 3 }}` | 1 |
