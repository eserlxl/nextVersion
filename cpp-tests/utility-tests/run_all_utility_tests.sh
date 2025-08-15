#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Utility C++ Tests Runner
# This script builds and runs all utility C++ unit tests

set -Euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_ROOT/build-test"

# Ensure we're in the project root
cd "$PROJECT_ROOT" || exit

echo "[INFO] Running NEXTVERSION UTILITY C++ TESTS..."
echo "[INFO] Project root: $PROJECT_ROOT"
echo "[INFO] Utility test directory: $TEST_DIR"

# Create test results directory
mkdir -p "$PROJECT_ROOT/test_results"

# Build configuration
echo "[INFO] Configuring CMake with testing enabled..."
if ! cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DENABLE_SANITIZERS=ON -DWARNING_MODE=ON > "$PROJECT_ROOT/test_results/cmake_config_utility.log" 2>&1; then
    echo "[ERROR] CMake configuration failed. Check $PROJECT_ROOT/test_results/cmake_config_utility.log"
    exit 1
fi
echo "[SUCCESS] CMake configuration completed"

# Build tests
echo "[INFO] Building utility tests..."
if ! cmake --build "$BUILD_DIR" --config Debug --parallel > "$PROJECT_ROOT/test_results/build_utility.log" 2>&1; then
    echo "[ERROR] Build failed. Check $PROJECT_ROOT/test_results/build_utility.log"
    exit 1
fi
echo "[SUCCESS] Build completed"

# Run utility tests with CTest
echo "[INFO] Running utility tests with CTest..."
CTEST_LOG="$PROJECT_ROOT/test_results/ctest_utility_detailed.log"

ctest_exit_code=0
ctest --test-dir "$BUILD_DIR" --output-on-failure -T Test > "$CTEST_LOG" 2>&1 || ctest_exit_code=$?

# Parse CTest output for utility test results
UTILITY_PASSED=$(grep -c "Passed" "$CTEST_LOG")
UTILITY_FAILED=$(grep -c "Failed" "$CTEST_LOG")

if [ "$ctest_exit_code" -ne 0 ] || [ "$UTILITY_FAILED" -gt 0 ]; then
    echo "[ERROR] Utility tests failed. Check $CTEST_LOG"
    TEST_RESULT=1
else
    echo ""
    echo "[SUCCESS] All utility tests passed!"
    TEST_RESULT=0
fi

# Generate utility test summary
UTILITY_SUMMARY_FILE="$PROJECT_ROOT/test_results/utility_cpp_test_summary.txt"

echo ""
echo "=========================================="
echo "      UTILITY C++ TEST SUMMARY"
echo "=========================================="
echo "Utility tests passed: $UTILITY_PASSED"
echo "Utility tests failed: $UTILITY_FAILED"

if [ "$UTILITY_FAILED" -eq 0 ] && [ "$UTILITY_PASSED" -gt 0 ]; then
    echo -e "Status: ${GREEN}ALL PASSED${NC}"
else
    echo -e "Status: ${RED}SOME FAILED${NC}"
fi

echo ""
echo "Summary saved to: $UTILITY_SUMMARY_FILE"
echo "Detailed log: $CTEST_LOG"

# Save utility test summary to file
{
    echo "NEXTVERSION UTILITY C++ TEST SUITE SUMMARY"
    echo "Generated: $(date)"
    echo ""
    echo "Utility tests passed: $UTILITY_PASSED"
    echo "Utility tests failed: $UTILITY_FAILED"
    echo ""
    echo "Detailed results available in: $CTEST_LOG"
} > "$UTILITY_SUMMARY_FILE"

exit $TEST_RESULT
