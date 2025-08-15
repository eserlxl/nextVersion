#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Core C++ Tests Runner
# This script builds and runs all core C++ unit tests

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

echo "[INFO] Running NEXTVERSION CORE C++ TESTS..."
echo "[INFO] Project root: $PROJECT_ROOT"
echo "[INFO] Core test directory: $TEST_DIR"

# Create test results directory
mkdir -p "$PROJECT_ROOT/test_results"

# Build configuration
echo "[INFO] Configuring CMake with testing enabled..."
if ! cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DENABLE_SANITIZERS=ON -DWARNING_MODE=ON > "$PROJECT_ROOT/test_results/cmake_config_core.log" 2>&1; then
    echo "[ERROR] CMake configuration failed. Check $PROJECT_ROOT/test_results/cmake_config_core.log"
    exit 1
fi
echo "[SUCCESS] CMake configuration completed"

# Build tests
echo "[INFO] Building core tests..."
if ! cmake --build "$BUILD_DIR" --config Debug --parallel > "$PROJECT_ROOT/test_results/build_core.log" 2>&1; then
    echo "[ERROR] Build failed. Check $PROJECT_ROOT/test_results/build_core.log"
    exit 1
fi
echo "[SUCCESS] Build completed"

# Run core tests with CTest
echo "[INFO] Running core tests with CTest..."
CTEST_LOG="$PROJECT_ROOT/test_results/ctest_core_detailed.log"

ctest_exit_code=0
ctest --test-dir "$BUILD_DIR" --output-on-failure -T Test > "$CTEST_LOG" 2>&1 || ctest_exit_code=$?

# Parse CTest output for core test results
CORE_PASSED=$(grep -c "Passed" "$CTEST_LOG")
CORE_FAILED=$(grep -c "Failed" "$CTEST_LOG")

if [ "$ctest_exit_code" -ne 0 ] || [ "$CORE_FAILED" -gt 0 ]; then
    echo "[ERROR] Core tests failed. Check $CTEST_LOG"
    TEST_RESULT=1
else
    echo ""
    echo "[SUCCESS] All core tests passed!"
    TEST_RESULT=0
fi

# Generate core test summary
CORE_SUMMARY_FILE="$PROJECT_ROOT/test_results/core_cpp_test_summary.txt"

echo ""
echo "=========================================="
echo "        CORE C++ TEST SUMMARY"
echo "=========================================="
echo "Core tests passed: $CORE_PASSED"
echo "Core tests failed: $CORE_FAILED"

if [ "$CORE_FAILED" -eq 0 ] && [ "$CORE_PASSED" -gt 0 ]; then
    echo -e "Status: ${GREEN}ALL PASSED${NC}"
else
    echo -e "Status: ${RED}SOME FAILED${NC}"
fi

echo ""
echo "Summary saved to: $CORE_SUMMARY_FILE"
echo "Detailed log: $CTEST_LOG"

# Save core test summary to file
{
    echo "NEXTVERSION CORE C++ TEST SUITE SUMMARY"
    echo "Generated: $(date)"
    echo ""
    echo "Core tests passed: $CORE_PASSED"
    echo "Core tests failed: $CORE_FAILED"
    echo ""
    echo "Detailed results available in: $CTEST_LOG"
} > "$CORE_SUMMARY_FILE"

exit $TEST_RESULT
