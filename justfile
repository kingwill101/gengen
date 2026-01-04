set shell := ["bash", "-lc"]

# Run `just` to list the most common commands for working with GenGen.
@default:
	@just --list

# Build a site directory (defaults to the base example).
build dir="examples/base":
	dart run bin/main.dart build {{dir}}

# Serve a site directory with hot reload.
serve dir="examples/base":
	dart run bin/main.dart serve {{dir}}

# Dump site diagnostics to stdout.
dump dir="examples/base":
	dart run bin/main.dart dump {{dir}}

# Scaffold a brand new GenGen project.
new dir:
	dart run bin/main.dart new {{dir}}
