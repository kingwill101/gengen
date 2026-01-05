# Collections Demo

This example demonstrates Jekyll-compatible collections behavior:

- `collections_dir` routing for collections and posts
- Collection ordering via `sort_by` and `order`
- `{% include_relative %}` support
- Collection static files (no front matter) written alongside docs
- `site.collections`, `site.<collection>`, and `site.documents`

## Build

From repo root:

```
./build/cli/linux_x64/bundle/bin/main build --source examples/collections-demo
```

Output is written to `examples/collections-demo/public`.

## Notes

- Posts are read from `collections/_posts`. The root `_posts` folder is ignored
  when `collections_dir` is set.
- `collections/_tutorials/callout.md` has **no** front matter, so it is treated
  as a collection static file and is also written to the output.
