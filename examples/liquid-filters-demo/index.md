---
title: "Liquid Filters Examples"
layout: default
sample_text: "Hello World"
sample_date: 2024-01-15
---

# Liquid Filters in Action

## String Filters

| Filter | Input | Output |
|--------|-------|--------|
| upcase | "{{ sample_text }}" | "{{ sample_text | upcase }}" |
| downcase | "{{ sample_text }}" | "{{ sample_text | downcase }}" |
| size | "{{ sample_text }}" | {{ sample_text | size }} |
| strip | "  hello  " | "{{ "  hello  " | strip }}" |
| truncate | "{{ sample_text }}" | "{{ sample_text | truncate: 8 }}" |
| slugify | "{{ sample_text }}" | "{{ sample_text | slugify }}" |

## Date Filters

| Format | Output |
|--------|--------|
| %Y-%m-%d | {{ page.sample_date | date: "%Y-%m-%d" }} |
| %B %d, %Y | {{ page.sample_date | date: "%B %d, %Y" }} |
| %A | {{ page.sample_date | date: "%A" }} |

## Array Filters

{% assign fruits = "apple,banana,cherry" | split: "," %}

| Filter | Output |
|--------|--------|
| split "apple,banana,cherry" by "," | {{ fruits | join: " / " }} |
| first | {{ fruits | first }} |
| last | {{ fruits | last }} |
| size | {{ fruits | size }} |
| sort | {{ fruits | sort | join: ", " }} |
| reverse | {{ fruits | reverse | join: ", " }} |

## Math Filters

| Expression | Result |
|------------|--------|
| 10 plus 5 | {{ 10 | plus: 5 }} |
| 10 minus 3 | {{ 10 | minus: 3 }} |
| 10 times 2 | {{ 10 | times: 2 }} |
| 10 divided_by 3 | {{ 10 | divided_by: 3 }} |
| 10 modulo 3 | {{ 10 | modulo: 3 }} |

## URL Filters

| Filter | Output |
|--------|--------|
| url_encode "hello world" | {{ "hello world" | url_encode }} |
| relative_url "/page" | {{ "/page" | relative_url }} |
