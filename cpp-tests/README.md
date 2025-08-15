# NEXTVERSION C++ Test Suite

This directory contains the organized C++ unit tests for the nextVersion project, structured to match the bash test organization pattern. The C++ tests are now a peer directory alongside the bash tests in `test-workflows/`.

## Directory Structure

```
cpp-tests/
├── core-tests/           # Core functionality tests
│   ├── test_semver.cpp
│   ├── test_version_math.cpp
│   ├── test_version_reader_and_cli_parse.cpp
│   ├── test_helpers.h
│   └── run_all_core_tests.sh
├── cli-tests/            # CLI-related tests
│   ├── test_cli_analyzer_breaking.cpp
│   ├── test_config_loader.cpp
│   ├── test_helpers.h
│   └── run_all_cli_tests.sh
├── utility-tests/        # Utility and helper tests
│   ├── test_git_stats.cpp
│   ├── test_basic.cpp
│   ├── test_helpers.h
│   └── run_all_utility_tests.sh
├── analyzer-tests/       # Analysis and suggestion tests
│   ├── test_suggestion_engine.cpp
│   ├── test_output_json.cpp
│   ├── test_helpers.h
│   └── run_all_analyzer_tests.sh
├── run_cpp_tests.sh      # Main orchestrator
└── README.md             # This file
```

## Test Categories

### Core Tests (`core-tests/`)
Tests for fundamental functionality:
- **Semantic Versioning**: Version parsing, validation, and comparison
- **Version Mathematics**: Version arithmetic and calculations
- **Version Reading**: File reading and parsing functionality

### CLI Tests (`cli-tests/`)
Tests for command-line interface functionality:
- **CLI Analysis**: Breaking change detection in CLI options
- **Configuration Loading**: Settings and configuration management

### Utility Tests (`utility-tests/`)
Tests for utility functions and helpers:
- **Git Statistics**: Repository analysis and change tracking
- **Basic Utilities**: Fundamental helper functions

### Analyzer Tests (`analyzer-tests/`)
Tests for analysis and suggestion engines:
- **Suggestion Engine**: Version bump recommendations
- **Output Formatting**: JSON and other output formats

## Running Tests

### Run All C++ Tests
```bash
cd cpp-tests
./run_cpp_tests.sh
```

### Run Specific Categories
```bash
# Run only core tests
cd cpp-tests/core-tests
./run_all_core_tests.sh

# Run only CLI tests
cd cpp-tests/cli-tests
./run_all_cli_tests.sh

# Run only utility tests
cd cpp-tests/utility-tests
./run_all_utility_tests.sh

# Run only analyzer tests
cd cpp-tests/analyzer-tests
./run_all_analyzer_tests.sh
```

### Run from Main Workflow
```bash
# Run all tests including C++ tests
cd test-workflows
./run_workflow_tests.sh
```

## Test Results

All test results are saved to the `test_results/` directory in the project root:

- `cpp_tests_summary.txt` - Overall C++ test summary
- `core_cpp_test_summary.txt` - Core tests summary
- `cli_cpp_test_summary.txt` - CLI tests summary
- `utility_cpp_test_summary.txt` - Utility tests summary
- `analyzer_cpp_test_summary.txt` - Analyzer tests summary
- `ctest_*_detailed.log` - Detailed CTest output for each category

## Dependencies

- **CMake**: Build system configuration
- **CTest**: Test execution framework
- **C++ Compiler**: GCC or Clang with C++17 support
- **Build Tools**: Make or Ninja

## Test Configuration

Tests are built with the following CMake options:
- `CMAKE_BUILD_TYPE=Debug` - Debug build for better error reporting
- `BUILD_TESTING=ON` - Enable testing support
- `ENABLE_SANITIZERS=ON` - Enable address and undefined behavior sanitizers
- `WARNING_MODE=ON` - Enable strict warning flags

## Adding New Tests

1. **Choose the appropriate category** based on test functionality
2. **Copy the test file** to the relevant directory
3. **Include test_helpers.h** for common test utilities
4. **Update CMakeLists.txt** to include the new test
5. **Ensure the test compiles** and runs independently

## Test Helper Functions

The `test_helpers.h` file provides common testing utilities:

- `TEST_ASSERT(condition, message)` - Assert with descriptive message
- `TEST_PASS(message)` - Mark test as passed
- `TEST_FAIL(message)` - Mark test as failed

## Integration with Main Test Suite

The C++ tests are integrated into the main workflow test runner (`run_workflow_tests.sh`) and will be executed alongside bash tests when running the complete test suite.

## Troubleshooting

### Build Issues
- Ensure CMake is properly configured
- Check that all dependencies are installed
- Verify C++ compiler supports C++17

### Test Failures
- Check individual category logs in `test_results/`
- Review CTest detailed output
- Verify test environment and dependencies

### Timeout Issues
- Increase `TEST_TIMEOUT` environment variable if needed
- Check for hanging tests or infinite loops
- Verify system resources are adequate
