#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Comprehensive C++ Tests Runner
# This script builds and runs all comprehensive C++ tests with detailed reporting

set -Euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0
FAILED_TEST_NAMES=()

# Configuration
TEST_TIMEOUT=${TEST_TIMEOUT:-300}  # Default 5 minutes timeout for comprehensive tests
FIXED_OUTPUT_DIR="test_results"
SUMMARY_FILE="$FIXED_OUTPUT_DIR/comprehensive_cpp_tests_summary.txt"
DETAILED_LOG="$FIXED_OUTPUT_DIR/comprehensive_cpp_tests_detailed.log"

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build-test"

# Clean and recreate output directory
rm -rf "$FIXED_OUTPUT_DIR"
mkdir -p "$FIXED_OUTPUT_DIR"

echo "=========================================="
echo "    NEXTVERSION COMPREHENSIVE C++ TESTS"
echo "=========================================="
echo "Output directory: $FIXED_OUTPUT_DIR"
echo "Summary file: $SUMMARY_FILE"
echo "Detailed log: $DETAILED_LOG"
echo "Test timeout: ${TEST_TIMEOUT}s"
echo "Project root: $PROJECT_ROOT"
echo "Build directory: $BUILD_DIR"
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

# Function to run a comprehensive test
run_comprehensive_test() {
    local test_name="$1"
    local test_executable="$2"
    
    echo -n "Running $test_name... "
    
    # Check if executable exists
    if [[ ! -f "$test_executable" ]]; then
        echo -e "${YELLOW}SKIPPED (executable not found)${NC}"
        log_test "$test_name" "SKIPPED" "Executable not found: $test_executable" "0"
        ((SKIPPED_TESTS++))
        ((TOTAL_TESTS++))
        return
    fi
    
    # Record start time
    local start_time
    start_time=$(date +%s)
    
    # Run the test with timeout
    local output
    local exit_code
    output=$(timeout "${TEST_TIMEOUT}s" "$test_executable" 2>&1)
    exit_code=$?
    
    # Calculate duration
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Check exit code
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}PASSED${NC}"
        log_test "$test_name" "PASSED" "$output" "$duration"
        ((PASSED_TESTS++))
    elif [[ $exit_code -eq 124 ]]; then
        echo -e "${RED}TIMEOUT${NC}"
        log_test "$test_name" "TIMEOUT" "Test timed out after ${TEST_TIMEOUT}s" "$duration"
        ((FAILED_TESTS++))
        FAILED_TEST_NAMES+=("$test_name (TIMEOUT)")
    else
        echo -e "${RED}FAILED${NC}"
        log_test "$test_name" "FAILED" "$output" "$duration"
        ((FAILED_TESTS++))
        FAILED_TEST_NAMES+=("$test_name")
    fi
    
    ((TOTAL_TESTS++))
}

# Function to build the project
build_project() {
    echo -e "${BLUE}Building project...${NC}"
    
    # Ensure we're in the project root
    cd "$PROJECT_ROOT" || exit 1
    
    # Configure CMake
    echo "Configuring CMake..."
    if ! cmake -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DENABLE_SANITIZERS=ON -DWARNING_MODE=ON > "$FIXED_OUTPUT_DIR/cmake_config.log" 2>&1; then
        echo -e "${RED}CMake configuration failed. Check $FIXED_OUTPUT_DIR/cmake_config.log${NC}"
        exit 1
    fi
    
    # Build the project
    echo "Building project..."
    if ! cmake --build "$BUILD_DIR" --config Debug --parallel > "$FIXED_OUTPUT_DIR/build.log" 2>&1; then
        echo -e "${RED}Build failed. Check $FIXED_OUTPUT_DIR/build.log${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Build completed successfully${NC}"
}

# Main test execution
echo -e "${BLUE}Starting comprehensive C++ test suite execution...${NC}"
echo ""

# Build the project first
build_project

echo ""
echo -e "${BLUE}Running comprehensive tests...${NC}"
echo ""

# Run core comprehensive tests
echo -e "${CYAN}=== Core Tests ===${NC}"
run_comprehensive_test "Semver Comprehensive" "$BUILD_DIR/bin/test_semver_comprehensive"
run_comprehensive_test "Version Math Comprehensive" "$BUILD_DIR/bin/test_version_math_comprehensive"
run_comprehensive_test "Bonus Calculator Comprehensive" "$BUILD_DIR/bin/test_bonus_calculator_comprehensive"

# Run CLI comprehensive tests
echo -e "${CYAN}=== CLI Tests ===${NC}"
run_comprehensive_test "CLI Comprehensive" "$BUILD_DIR/bin/test_cli_comprehensive"

# Run analyzer comprehensive tests
echo -e "${CYAN}=== Analyzer Tests ===${NC}"
run_comprehensive_test "Analyzers Comprehensive" "$BUILD_DIR/bin/test_analyzers_comprehensive"
run_comprehensive_test "Output Formatter Comprehensive" "$BUILD_DIR/bin/test_output_formatter_comprehensive"

# Run utility comprehensive tests
echo -e "${CYAN}=== Utility Tests ===${NC}"
run_comprehensive_test "Git Helpers Comprehensive" "$BUILD_DIR/bin/test_git_helpers_comprehensive"

# Generate final summary
echo ""
echo "=========================================="
echo "           FINAL SUMMARY"
echo "=========================================="
echo "Total tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo -e "Skipped: ${YELLOW}$SKIPPED_TESTS${NC}"

# Calculate success rate
SUCCESS_RATE=0
if [[ $TOTAL_TESTS -gt 0 ]]; then
    SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
fi
echo "Success rate: $SUCCESS_RATE%"

# Show failed tests if any
if [[ ${#FAILED_TEST_NAMES[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}Failed tests:${NC}"
    for test_name in "${FAILED_TEST_NAMES[@]}"; do
        echo -e "  - ${RED}$test_name${NC}"
    done
fi

echo ""
echo "Summary saved to: $SUMMARY_FILE"
echo "Detailed log: $DETAILED_LOG"

# Save final summary to file
{
    echo "NEXTVERSION COMPREHENSIVE C++ TEST SUITE FINAL SUMMARY"
    echo "Generated: $(date)"
    echo ""
    echo "Total tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Skipped: $SKIPPED_TESTS"
    echo "Success rate: $SUCCESS_RATE%"
    echo ""
    if [[ ${#FAILED_TEST_NAMES[@]} -gt 0 ]]; then
        echo "Failed tests:"
        for test_name in "${FAILED_TEST_NAMES[@]}"; do
            echo "  - $test_name"
        done
        echo ""
    fi
    echo "Detailed results available in: $DETAILED_LOG"
    echo "Build log: $FIXED_OUTPUT_DIR/build.log"
    echo "CMake config log: $FIXED_OUTPUT_DIR/cmake_config.log"
} > "$SUMMARY_FILE"

# Exit with appropriate code
if [[ $FAILED_TESTS -eq 0 ]] && [[ $PASSED_TESTS -gt 0 ]]; then
    echo -e "${GREEN}All comprehensive C++ tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some comprehensive C++ tests failed!${NC}"
    exit 1
fi
