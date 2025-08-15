#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# CLI C++ Tests Runner
# This script builds and runs all CLI-related C++ unit tests

set -Euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_ROOT/build-test"

# Ensure we're in the project root
cd "$PROJECT_ROOT" || exit

echo "[INFO] Running NEXTVERSION CLI C++ TESTS..."
echo "[INFO] Project root: $PROJECT_ROOT"
echo "[INFO] CLI test directory: $TEST_DIR"

# Create test results directory
mkdir -p "$PROJECT_ROOT/test_results"

# Build configuration
echo "[INFO] Configuring CMake with testing enabled..."
if ! cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DENABLE_SANITIZERS=ON -DWARNING_MODE=ON > "$PROJECT_ROOT/test_results/cmake_config_cli.log" 2>&1; then
    echo "[ERROR] CMake configuration failed. Check $PROJECT_ROOT/test_results/cmake_config_cli.log"
    exit 1
fi
echo "[SUCCESS] CMake configuration completed"

# Build tests
echo "[INFO] Building CLI tests..."
if ! cmake --build "$BUILD_DIR" --config Debug --parallel > "$PROJECT_ROOT/test_results/build_cli.log" 2>&1; then
    echo "[ERROR] Build failed. Check $PROJECT_ROOT/test_results/build_cli.log"
    exit 1
fi
echo "[SUCCESS] Build completed"

# Run CLI tests with CTest
echo "[INFO] Running CLI tests with CTest..."
CTEST_LOG="$PROJECT_ROOT/test_results/ctest_cli_detailed.log"

ctest_exit_code=0
ctest --test-dir "$BUILD_DIR" --output-on-failure -T Test > "$CTEST_LOG" 2>&1 || ctest_exit_code=$?

# Parse CTest output for CLI test results
CLI_PASSED=$(grep -c "Passed" "$CTEST_LOG")
CLI_FAILED=$(grep -c "Failed" "$CTEST_LOG")

if [ "$ctest_exit_code" -ne 0 ] || [ "$CLI_FAILED" -gt 0 ]; then
    echo "[ERROR] CLI tests failed. Check $CTEST_LOG"
    TEST_RESULT=1
else
    echo ""
    echo "[SUCCESS] All CLI tests passed!"
    TEST_RESULT=0
fi

# Generate CLI test summary
CLI_SUMMARY_FILE="$PROJECT_ROOT/test_results/cli_cpp_test_summary.txt"

echo ""
echo "=========================================="
echo "        CLI C++ TEST SUMMARY"
echo "=========================================="
echo "CLI tests passed: $CLI_PASSED"
echo "CLI tests failed: $CLI_FAILED"

if [ "$CLI_FAILED" -eq 0 ] && [ "$CLI_PASSED" -gt 0 ]; then
    echo -e "Status: ${GREEN}ALL PASSED${NC}"
else
    echo -e "Status: ${RED}SOME FAILED${NC}"
fi

echo ""
echo "Summary saved to: $CLI_SUMMARY_FILE"
echo "Detailed log: $CTEST_LOG"

# Save CLI test summary to file
{
    echo "NEXTVERSION CLI C++ TEST SUITE SUMMARY"
    echo "Generated: $(date)"
    echo ""
    echo "CLI tests passed: $CLI_PASSED"
    echo "CLI tests failed: $CLI_FAILED"
    echo ""
    echo "Detailed results available in: $CTEST_LOG"
} > "$CLI_SUMMARY_FILE"

exit $TEST_RESULT
