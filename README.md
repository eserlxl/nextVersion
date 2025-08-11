# nextVersion - Bash Versioning Tools

A collection of bash scripts for automated semantic versioning and release management.

## Quick Start

```bash
# Analyze your repository and suggest next version
./bin/semantic-version-analyzer.sh

# Automatically bump version based on changes
./bin/mathematical-version-bump.sh --commit

# Calculate version with LOC delta
./bin/version-calculator-loc.sh
```

## Scripts

- **semantic-version-analyzer.sh** - Main version analysis tool
- **mathematical-version-bump.sh** - Automated version bumping
- **version-calculator.sh** - Version calculation utilities
- **version-calculator-loc.sh** - LOC-based version calculation
- **tag-manager.sh** - Git tag management
- **git-operations.sh** - Git operations utilities
- **cli-options-analyzer.sh** - CLI options analysis
- **security-keyword-analyzer.sh** - Security analysis
- **keyword-analyzer.sh** - Keyword analysis
- **file-change-analyzer.sh** - File change analysis
- **ref-resolver.sh** - Reference resolution
- **generate-ci-gpg-key.sh** - CI GPG key generation
- **version-utils.sh** - Version utilities
- **version-config-loader.sh** - Configuration loading
- **version-validator.sh** - Version validation

## Configuration

Edit `config/versioning.yml` to customize bonus points, multipliers, and thresholds.

## Installation

Copy the `bin/` directory to your PATH or run scripts directly from this directory.

## License

GPLv3 - See LICENSE file for details.
