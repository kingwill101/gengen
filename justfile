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

# Run tests and generate LCOV coverage report in coverage/lcov.info.
coverage:
	rm -rf coverage
	dart test --concurrency=1 --coverage=coverage test
	dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --report-on=lib --ignore-files "lib/**.g.dart" --ignore-files "lib/**.freezed.dart"

# Generate HTML coverage report if lcov/genhtml is installed.
coverage-html: coverage
	@if command -v genhtml >/dev/null; then \
		genhtml -o coverage/html coverage/lcov.info; \
	else \
		echo "genhtml not found; install lcov to generate HTML output."; \
	fi
