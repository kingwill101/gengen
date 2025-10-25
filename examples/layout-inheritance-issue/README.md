# Layout Inheritance Issue Demo

This minimal site reproduces the behaviour where a layout without YAML front
matter does not chain to its parent layout.

Steps:

1. `dart run bin/main.dart build examples/layout-inheritance-issue`
2. Inspect `public/posts/2024/04/16/minimal-layout-issue.html`

Observed output:

- The rendered page only contains the markup from `_layouts/post.html`
- The default layout's footer (`_includes/foot.html`) is missing

This happens because `_layouts/post.html` has no front matter, so its `Layout`
instance exposes an empty `data` map. The Liquid plugin therefore never sees a
`layout` key and does not render `_layouts/default.html`. Adding front matter
to the post layout (e.g. `---\nlayout: default\n---`) restores the expected
wrapped output.
