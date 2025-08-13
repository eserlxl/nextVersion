# nextVersion

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![C++20](https://img.shields.io/badge/C%2B%2B-20-blue.svg)](https://isocpp.org/std/status)
[![Bash](https://img.shields.io/badge/Bash-5.0+-green.svg)](https://www.gnu.org/software/bash/)
[![CMake](https://img.shields.io/badge/CMake-3.16+-orange.svg)](https://cmake.org/)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)

**nextVersion** is a comprehensive toolkit for automated semantic versioning and release management, featuring both C++ and bash implementations with advanced LOC-based delta calculations. It automatically calculates semantic version bumps based on code changes, commit analysis, and Lines of Code (LOC) deltas, providing both high-performance C++ binaries and portable bash scripts for maximum flexibility.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Architecture](#architecture)
- [Documentation](#documentation)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

## Overview

Managing semantic versioning manually can be error-prone and time-consuming, especially in fast-paced development environments. Common challenges include:

- **Inconsistent Versioning**: Manual version bumps often lead to inconsistent release numbering
- **Complex Change Analysis**: Determining the appropriate version increment requires analyzing multiple factors
- **LOC-Based Calculations**: Traditional semantic versioning doesn't account for the magnitude of code changes
- **Git Integration**: Lack of seamless integration with version control systems and CI/CD pipelines
- **Rollover Management**: Complex version number management when reaching version limits

`nextVersion` addresses these challenges by providing an intelligent, automated system that combines semantic analysis with mathematical LOC-based calculations, ensuring consistent and meaningful version increments while maintaining full compatibility with existing development workflows.

[↑ Back to top](#nextversion)

## Features

### Core Versioning System
- **Dual Implementation**: High-performance C++ binaries for production use and portable bash scripts for maximum compatibility
- **Advanced LOC Delta System**: Mathematical version calculation based on change magnitude and complexity
- **Semantic Analysis**: Automatic detection of breaking changes, new features, and bug fixes through intelligent commit analysis
- **Smart Rollover Logic**: Intelligent version number management with automatic rollover handling for large version increments

### Git Integration & Workflow
- **Seamless Git Integration**: Native support for git repositories with automatic tag management and commit processing
- **CI/CD Ready**: Structured output formats (JSON, YAML) for easy integration with automated pipelines
- **Commit Analysis**: Intelligent parsing of commit messages and change patterns for accurate version determination
- **Tag Management**: Automated git tag creation and management with validation

### Performance & Efficiency
- **High-Performance C++**: Built with modern C++20, optimized for large repository analysis
- **Stream Processing**: Efficient handling of large codebases without memory issues
- **Parallel Processing**: Multi-threaded analysis where applicable for improved performance
- **Memory Optimization**: Smart memory management for processing large repositories

### Configuration & Customization
- **YAML Configuration**: Flexible configuration system for customizing versioning behavior
- **Bonus Point System**: Configurable bonus points for different types of changes
- **Threshold Management**: Adjustable thresholds and multipliers for fine-tuning version increments
- **Rollover Configuration**: Customizable rollover behavior and version limits

### Development & Quality Assurance
- **Comprehensive Testing**: Extensive test suite with realistic repository scenarios and edge cases
- **Automated Validation**: Built-in version validation and consistency checking
- **Debug Support**: Comprehensive logging and debugging capabilities for troubleshooting
- **Cross-Platform**: Support for Linux, macOS, and Windows environments

[↑ Back to top](#nextversion)

## Quick Start

### Prerequisites
- **For C++ Implementation**: C++20 compatible compiler (GCC 10+, Clang 12+, or MSVC 2019+), CMake 3.16+
- **For Bash Implementation**: Bash 5.0+ and standard Unix tools
- **Git**: Repository with commit history for analysis

### C++ Implementation (Recommended for Production)

```bash
# Clone the repository
git clone <repository-url>
cd nextVersion

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

[↑ Back to top](#nextversion)

## Installation

### From Source (Recommended)

```bash
# Clone the repository
git clone <repository-url>
cd nextVersion

# Build the project
mkdir build
cd build
cmake ..
make -j20

# Optional: Install system-wide
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

### Build Options

The project supports multiple build configurations:

```bash
# Default build
mkdir build && cd build
cmake ..
make -j20

# Debug build with sanitizers
cmake -DCMAKE_BUILD_TYPE=Debug ..
make -j20

# Release build with optimizations
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j20
```

[↑ Back to top](#nextversion)

## Usage

`nextVersion` provides multiple interfaces for different use cases, from simple command-line analysis to full CI/CD integration.

### Basic Version Analysis

```bash
# Analyze current repository and suggest next version
./bin/semantic-version-analyzer.sh

# Get detailed analysis with LOC calculations
./bin/version-calculator-loc.sh

# Validate current version configuration
./bin/version-validator.sh
```

### Automated Version Bumping

```bash
# Automatically bump version based on detected changes
./bin/mathematical-version-bump.sh --commit

# Preview version changes without committing
./bin/mathematical-version-bump.sh --dry-run

# Force specific version increment type
./bin/mathematical-version-bump.sh --patch
./bin/mathematical-version-bump.sh --minor
./bin/mathematical-version-bump.sh --major
```

### Advanced Usage Examples

```bash
# Analyze specific commit range
./bin/semantic-version-analyzer.sh --from-commit HEAD~5 --to-commit HEAD

# Custom configuration file
./bin/version-calculator.sh --config custom-versioning.yml

# Generate release notes
./bin/version-calculator.sh --generate-notes

# Analyze external repository
./bin/semantic-version-analyzer.sh --repo /path/to/external/repo

# Machine-readable output for CI/CD
./bin/next-version --json --quiet
```

### Command-Line Options

| Option | Long Option | Description |
|--------|-------------|-------------|
| `--json` | | Output in JSON format for machine processing |
| `--yaml` | | Output in YAML format for configuration files |
| `--quiet` | | Suppress non-essential output |
| `--verbose` | | Enable detailed logging and debugging |
| `--config` | | Specify custom configuration file |
| `--dry-run` | | Preview changes without applying them |
| `--commit` | | Automatically commit version changes |
| `--tag` | | Create git tag for new version |
| `--help` | | Show help message |

For a comprehensive list of all available options and advanced usage patterns, refer to the individual script help messages or the documentation.

[↑ Back to top](#nextversion)

## Architecture

### Core Components

- **Semantic Analyzer**: Detects breaking changes, new features, and bug fixes through intelligent commit analysis
- **LOC Delta Calculator**: Mathematical version increment based on change magnitude and complexity
- **Git Operations**: Repository analysis, tag management, and commit processing with full git integration
- **Configuration System**: YAML-based configuration for customizing behavior, thresholds, and multipliers
- **Output Formatter**: Structured output formats (JSON, YAML, human-readable) for CI/CD integration

### Versioning Algorithm

The system uses an advanced mathematical approach combining semantic analysis with LOC-based calculations:

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
- **Automatic handling**: Seamless rollover without manual intervention

### Configuration System

The system is highly configurable through `config/versioning.yml`:
- **Bonus points**: Customizable points for different change types
- **Multipliers**: Adjustable LOC multipliers and thresholds
- **Rollover behavior**: Configurable rollover limits and behavior
- **Output formats**: Customizable output formatting and verbosity

[↑ Back to top](#nextversion)

## Documentation

Comprehensive documentation is available in the `doc/` directory:

- [Versioning Strategy](doc/VERSIONING.md) - Core versioning concepts and mathematical foundations
- [Release Workflow](doc/RELEASE_WORKFLOW.md) - Complete release process guide and automation
- [CI/CD Guide](doc/CI_CD_GUIDE.md) - Integration with CI/CD pipelines and automation tools
- [TAG Management](doc/TAG_MANAGEMENT.md) - Git tag handling and management strategies
- [LOC Delta System](doc/LOC_DELTA_SYSTEM.md) - Mathematical foundations and calculations
- [Semantic Analyzer](doc/SEMANTIC_ANALYZER_MODULAR_ARCHITECTURE.md) - Semantic analysis architecture
- [Modular Architecture](doc/BUMP_VERSION_MODULAR_ARCHITECTURE.md) - System architecture and design
- [Versioning Algorithm](doc/VERSIONING_ALGORITHM.md) - Detailed algorithm documentation

[↑ Back to top](#nextversion)

## Testing

The project includes an extensive test suite covering all aspects of the versioning system:

### Running Tests

```bash
# Run all tests
./run_tests.sh

# Run specific test categories
cd test-workflows/core-tests
./test_semantic_version_analyzer.sh

# Run LOC delta system tests
./test_loc_delta_system.sh

# Run comprehensive integration tests
./test_versioning_system_integration.sh
```

### Test Categories

- **Core Tests**: Fundamental versioning logic and calculations
- **Edge Case Tests**: Boundary conditions and error handling
- **Integration Tests**: End-to-end workflow testing
- **Performance Tests**: Large repository and stress testing
- **Compatibility Tests**: Cross-platform and environment testing

### Test Fixtures

The test suite includes realistic repository scenarios and fixtures:
- Sample source code with various change patterns
- Git repository states for testing different scenarios
- Configuration files for testing customization options
- Expected outputs for validation

[↑ Back to top](#nextversion)

## Contributing

We welcome contributions! Please see our contributing guidelines for details on:

- Code style and standards
- Testing requirements
- Pull request process
- Issue reporting

### Development Setup

```bash
# Clone the repository
git clone <repository-url>
cd nextVersion

# Build with tests
mkdir build
cd build
cmake ..
make -j20

# Run tests
cd ..
./run_tests.sh
```

### Development Guidelines

- Follow the existing code style and conventions
- Add tests for new functionality
- Ensure all tests pass before submitting changes
- Update documentation for new features
- Use conventional commit messages

[↑ Back to top](#nextversion)

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

[↑ Back to top](#nextversion)
