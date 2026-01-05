set shell := ["bash", "-lc"]

# Run `just` to list the most common commands for working with GenGen.
@default:
	@just --list

# Build a site directory (defaults to the base example).
build dir="examples/base": exe
	./build/cli/linux_x64/bundle/bin/main build {{dir}}

# Serve a site directory with hot reload.
serve dir="examples/base": exe
	./build/cli/linux_x64/bundle/bin/main serve {{dir}}

# Dump site diagnostics to stdout.
dump dir="examples/base": exe
	./build/cli/linux_x64/bundle/bin/main dump {{dir}}

# Scaffold a brand new GenGen project.
new dir: exe
	./build/cli/linux_x64/bundle/bin/main new {{dir}}

exe:
    dart build cli
