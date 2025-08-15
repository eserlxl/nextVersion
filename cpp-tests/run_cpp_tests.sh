#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Main C++ Tests Runner
# This script orchestrates all C++ test categories and provides a comprehensive summary

set -Euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0
FAILED_TEST_NAMES=()

# Configuration
TEST_TIMEOUT=${TEST_TIMEOUT:-600}  # Default 600 seconds timeout for C++ tests
FIXED_OUTPUT_DIR="test_results"
SUMMARY_FILE="$FIXED_OUTPUT_DIR/cpp_tests_summary.txt"
DETAILED_LOG="$FIXED_OUTPUT_DIR/cpp_tests_detailed.log"

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Clean and recreate output directory
rm -rf "$FIXED_OUTPUT_DIR"
mkdir -p "$FIXED_OUTPUT_DIR"

echo "=========================================="
echo "    NEXTVERSION C++ TEST SUITE"
echo "=========================================="
echo "Output directory: $FIXED_OUTPUT_DIR"
echo "Summary file: $SUMMARY_FILE"
echo "Detailed log: $DETAILED_LOG"
echo "Test timeout: ${TEST_TIMEOUT}s"
echo ""

# Function to log test results
log_test() {
    local test_name="$1"
    local status="$2"
    local output="$3"
    local duration="$4"
    
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $test_name: $status (${duration}s)"
        if [[ -n "$output" ]]; then
            echo "Output:"
            echo "$output"
            echo "---"
        fi
    } >> "$DETAILED_LOG"
}

# Function to run a test category
run_test_category() {
    local test_dir="$1"
    local test_name
    test_name=$(basename "$test_dir")
    
    echo "[INFO] Running $test_name tests..."
    
    local start_time
    start_time=$(date +%s)
    
    local output
    local exit_code
    output=$(timeout "$TEST_TIMEOUT" bash "$test_dir/run_all_${test_name}_tests.sh" 2>&1)
    exit_code=$?
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ $exit_code -eq 0 ]; then
        echo -e "[${GREEN}PASS${NC}] $test_name tests completed in ${duration}s"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_test "$test_name" "PASS" "$output" "$duration"
    elif [ $exit_code -eq 124 ]; then
        echo -e "[${YELLOW}TIMEOUT${NC}] $test_name tests timed out after ${TEST_TIMEOUT}s"
        SKIPPED_TESTS=$((SKIPPED_TESTS + 1))
        log_test "$test_name" "TIMEOUT" "Tests timed out after ${TEST_TIMEOUT}s" "$TEST_TIMEOUT"
    else
        echo -e "[${RED}FAIL${NC}] $test_name tests failed in ${duration}s"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        FAILED_TEST_NAMES+=("$test_name")
        log_test "$test_name" "FAIL" "$output" "$duration"
    fi
    
    echo ""
}

# Main test execution
echo "[INFO] Starting C++ test suite execution..."
echo ""

# Run core tests
run_test_category "core-tests"

# Run CLI tests
run_test_category "cli-tests"

# Run utility tests
run_test_category "utility-tests"

# Run analyzer tests
run_test_category "analyzer-tests"

# Generate final summary
echo "=========================================="
echo "           FINAL SUMMARY"
echo "=========================================="
echo "Total test categories: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo -e "Skipped: ${YELLOW}$SKIPPED_TESTS${NC}"

# Calculate success rate
SUCCESS_RATE=0
if [ "$TOTAL_TESTS" -gt 0 ]; then
    SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
fi
echo "Success rate: $SUCCESS_RATE%"

# Show failed tests if any
if [ ${#FAILED_TEST_NAMES[@]} -gt 0 ]; then
    echo ""
    echo "Failed test categories:"
    for test_name in "${FAILED_TEST_NAMES[@]}"; do
        echo -e "  - ${RED}$test_name${NC}"
    done
fi

echo ""
echo "Summary saved to: $SUMMARY_FILE"
echo "Detailed log: $DETAILED_LOG"

# Save final summary to file
{
    echo "NEXTVERSION C++ TEST SUITE FINAL SUMMARY"
    echo "Generated: $(date)"
    echo ""
    echo "Total test categories: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Skipped: $SKIPPED_TESTS"
    echo "Success rate: $SUCCESS_RATE%"
    echo ""
    if [ ${#FAILED_TEST_NAMES[@]} -gt 0 ]; then
        echo "Failed test categories:"
        for test_name in "${FAILED_TEST_NAMES[@]}"; do
            echo "  - $test_name"
        done
        echo ""
    fi
    echo "Detailed results available in: $DETAILED_LOG"
} > "$SUMMARY_FILE"

# Exit with appropriate code
if [ "$FAILED_TESTS" -eq 0 ] && [ "$PASSED_TESTS" -gt 0 ]; then
    echo -e "${GREEN}All C++ test categories passed!${NC}"
    exit 0
else
    echo -e "${RED}Some C++ test categories failed!${NC}"
    exit 1
fi
