# nextVersion - Automated Semantic Versioning System

A comprehensive toolkit for automated semantic versioning and release management, featuring both C++ and bash implementations with advanced LOC-based delta calculations.

## Overview

nextVersion is a sophisticated versioning system that automatically calculates semantic version bumps based on code changes, commit analysis, and Lines of Code (LOC) deltas. It provides both high-performance C++ binaries and portable bash scripts for maximum flexibility.

## Features

- **Dual Implementation**: C++ for performance, bash for portability
- **Advanced LOC Delta System**: Mathematical version calculation based on change magnitude
- **Semantic Analysis**: Automatic detection of breaking changes, new features, and bug fixes
- **Git Integration**: Seamless workflow with git repositories and CI/CD pipelines
- **Smart Rollover Logic**: Intelligent version number management with automatic rollover
- **Comprehensive Testing**: Extensive test suite with realistic repository scenarios

## Quick Start

### C++ Implementation (Recommended for Production)

```bash
# Build the project
mkdir build
cd build
cmake ..
make -j20

# Run the native analyzer
./bin/next-version --help

# Machine-readable output
./bin/next-version --json
```

### Bash Implementation (Portable)

```bash
# Analyze your repository and suggest next version
./bin/semantic-version-analyzer.sh

# Automatically bump version based on changes
./bin/mathematical-version-bump.sh --commit

# Calculate version with LOC delta
./bin/version-calculator-loc.sh
```

## Architecture

### Core Components

- **Semantic Analyzer**: Detects breaking changes, new features, and bug fixes
- **LOC Delta Calculator**: Mathematical version increment based on change magnitude
- **Git Operations**: Repository analysis, tag management, and commit processing
- **Configuration System**: YAML-based configuration for customizing behavior
- **Output Formatter**: Structured output for CI/CD integration

### Versioning Algorithm

The system uses an advanced mathematical approach:

```bash
# Base delta from LOC
PATCH: 1 * (1 + LOC/250)  # Small changes
MINOR: 5 * (1 + LOC/500)  # Medium changes  
MAJOR: 10 * (1 + LOC/1000) # Large changes

# Bonus multiplication with LOC gain
Bonus Multiplier: (1 + LOC/L) where L depends on version type
Total Delta: base_delta + (bonus * bonus_multiplier)
```

### Rollover System

Intelligent rollover logic with `MAIN_VERSION_MOD = 1000`:
- **Patch rollover**: When patch + delta >= 1000, apply mod 1000 and increment minor
- **Minor rollover**: When minor + 1 >= 1000, apply mod 1000 and increment major

## Installation

### From Source

```bash
git clone <repository-url>
cd nextVersion
mkdir build
cd build
cmake ..
make -j20
sudo make install
```

### Bash-Only Release

For environments where C++ compilation isn't possible, use the bash-only release:

```bash
# Generate bash release package
./generate_bash_release.sh

# Install from release package
tar -xzf nextVersion-bash-*.tar.gz
cd nextVersion-bash-*
./install.sh
```

## Configuration

Edit `config/versioning.yml` to customize:
- Bonus points for different change types
- Multipliers and thresholds
- LOC calculation parameters
- Rollover behavior

## Testing

Run the comprehensive test suite:

```bash
# Run all tests
./run_tests.sh

# Run specific test categories
cd test-workflows/core-tests
./test_semantic_version_analyzer.sh
```

## Documentation

- [Versioning Strategy](doc/VERSIONING.md) - Core versioning concepts
- [Release Workflow](doc/RELEASE_WORKFLOW.md) - Release process guide
- [CI/CD Guide](doc/CI_CD_GUIDE.md) - Integration with CI/CD pipelines
- [TAG Management](doc/TAG_MANAGEMENT.md) - Git tag handling
- [LOC Delta System](doc/LOC_DELTA_SYSTEM.md) - Mathematical foundations

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

GPLv3 - See [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- Check the documentation in the `doc/` directory
- Review test examples in `test-workflows/`
- Open an issue on the project repository

---

**Note**: This project provides both C++ and bash implementations. The C++ version offers better performance for production use, while the bash version ensures maximum portability across different environments.
