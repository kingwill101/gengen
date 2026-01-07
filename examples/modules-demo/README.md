# Modules Demo

This example demonstrates GenGen's Hugo-inspired module system for themes and plugins.

## Quick Start

```bash
# 1. Fetch modules declared in config.yaml
gengen mod get --source=examples/modules-demo

# 2. Mount the theme (creates symlink to cached module)
mkdir -p examples/modules-demo/_themes
ln -s ~/.gengen/cache/modules/github.com/kingwill101/gengen_content/*/themes/minimal examples/modules-demo/_themes/minimal

# 3. Build the site
gengen build examples/modules-demo
```

## Features Demonstrated

- Importing themes from GitHub repositories
- Version constraints (semver, git refs)
- Lockfile for reproducible builds
- Local development replacements

## Configuration

See `config.yaml` for module configuration options.

## Commands

```bash
# Fetch modules declared in config.yaml
gengen mod get

# Update modules to latest versions within constraints
gengen mod update

# List all modules (declared and locked)
gengen mod list

# Remove unused modules from cache
gengen mod tidy

# Verify module integrity
gengen mod verify
```

## Version Constraint Formats

| Format | Example | Description |
|--------|---------|-------------|
| Caret | `^1.0.0` | Compatible versions (>=1.0.0 <2.0.0) |
| Range | `>=1.0.0 <2.0.0` | Explicit range |
| Exact | `1.2.3` | Exact version only |
| Branch | `branch:main` | Git branch |
| Tag | `tag:v1.0.0` | Git tag |
| Commit | `commit:abc123` | Git commit SHA |

## Module Sources

- **GitHub**: `github.com/user/repo`
- **GitLab**: `gitlab.com/org/project`
- **Bitbucket**: `bitbucket.org/team/repo`
- **Local**: `../path/to/module`

## Lockfile

After running `gengen mod get`, a `gengen.lock` file is created:

```yaml
packages:
  "github.com/user/theme":
    version: "v1.0.1"
    resolved: "/home/user/.gengen/cache/modules/..."
    sha: "abc123..."
    locked_at: "2024-01-01T00:00:00"
```

Commit this file for reproducible builds across environments.
