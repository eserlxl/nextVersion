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
CYAN='\033[0;36m'
PINK='\033[0;35m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TEST_CATEGORIES=0
PASSED_TEST_CATEGORIES=0
FAILED_TEST_CATEGORIES=0
SKIPPED_TEST_CATEGORIES=0
FAILED_TEST_CATEGORY_NAMES=()

# Individual test tracking
TOTAL_INDIVIDUAL_TESTS=0
PASSED_INDIVIDUAL_TESTS=0
FAILED_INDIVIDUAL_TESTS=0

# Configuration
TEST_TIMEOUT=${TEST_TIMEOUT:-300}  # Default 300 seconds timeout for C++ tests
FIXED_OUTPUT_DIR="test_results"
SUMMARY_FILE="$FIXED_OUTPUT_DIR/cpp_tests_summary.txt"
DETAILED_LOG="$FIXED_OUTPUT_DIR/cpp_tests_detailed.log"

# Get script directory and project root
# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  # Currently unused, kept for future use
# PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"  # Currently unused, kept for future use

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

# Function to parse individual test results from CTest output
parse_individual_test_results() {
    local category_name="$1"
    
    # Look for the CTest log file in the test results directory
    local project_root
    project_root=$(pwd)
    # Convert hyphens to underscores and remove the "tests" suffix to match actual log file names
    local log_category_name
    log_category_name=$(echo "$category_name" | sed 's/-tests$//' | tr '-' '_')
    local ctest_log_path="$project_root/test_results/ctest_${log_category_name}_detailed.log"
    
    if [[ ! -f "$ctest_log_path" ]]; then
        echo "  [WARNING] CTest log not found: $ctest_log_path"
        return
    fi
    
    echo "  Individual test results for $category_name:"
    
    # Parse CTest output to find individual test results
    local passed_count=0
    local failed_count=0
    
    # Extract individual test results from CTest output
    # Look for lines that show test execution results like:
    # "1/16 Test #1: test_semver ........................... Passed 0.00 sec"
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*[0-9]+/[0-9]+[[:space:]]+Test[[:space:]]+#[0-9]+:[[:space:]]+([^[:space:]]+)[[:space:]]+\.\.\.+[[:space:]]+([A-Za-z]+)[[:space:]]+[0-9.]+ ]]; then
            local test_name="${BASH_REMATCH[1]}"
            local test_status="${BASH_REMATCH[2]}"
            
            if [[ "$test_status" == "Passed" ]]; then
                echo -e "    ${GREEN}✓ PASS${NC}: $test_name"
                passed_count=$((passed_count + 1))
                PASSED_INDIVIDUAL_TESTS=$((PASSED_INDIVIDUAL_TESTS + 1))
            elif [[ "$test_status" == "Failed" ]]; then
                echo -e "    ${RED}✗ FAIL${NC}: $test_name"
                failed_count=$((failed_count + 1))
                FAILED_INDIVIDUAL_TESTS=$((FAILED_INDIVIDUAL_TESTS + 1))
            else
                echo -e "    ${YELLOW}? $test_status${NC}: $test_name"
            fi
            TOTAL_INDIVIDUAL_TESTS=$((TOTAL_INDIVIDUAL_TESTS + 1))
        fi
    done < "$ctest_log_path"
    
    # Also try to parse the summary section if available
    if [[ "$passed_count" -eq 0 ]] && [[ "$failed_count" -eq 0 ]]; then
        # Fallback: try to extract from summary lines
        local summary_passed
        local summary_failed
        summary_passed=$(grep -c "Passed" "$ctest_log_path" 2>/dev/null || echo 0)
        summary_failed=$(grep -c "Failed" "$ctest_log_path" 2>/dev/null || echo 0)
        
        if [[ "$summary_passed" -gt 0 ]] || [[ "$summary_failed" -gt 0 ]]; then
            echo "  Summary: $summary_passed passed, $summary_failed failed"
            PASSED_INDIVIDUAL_TESTS=$((PASSED_INDIVIDUAL_TESTS + summary_passed))
            FAILED_INDIVIDUAL_TESTS=$((FAILED_INDIVIDUAL_TESTS + summary_failed))
            TOTAL_INDIVIDUAL_TESTS=$((TOTAL_INDIVIDUAL_TESTS + summary_passed + summary_failed))
        fi
    fi
    
    echo ""
}

# Function to run a test category
run_test_category() {
    local test_dir="$1"
    local test_name
    test_name=$(basename "$test_dir")
    local test_number=$((TOTAL_TEST_CATEGORIES + 1))
    
    echo -n "[INFO] Running $test_name tests... "
    
    local start_time
    start_time=$(date +%s)
    
    local output
    local exit_code
    # Convert hyphens to underscores for script naming convention
    local script_name
    script_name=$(echo "$test_name" | tr '-' '_')
    # Use absolute path from cpp-tests directory
    local script_path="cpp-tests/$test_dir/run_all_${script_name}.sh"
    output=$(timeout "$TEST_TIMEOUT" bash "$script_path" 2>&1)
    exit_code=$?
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    TOTAL_TEST_CATEGORIES=$((TOTAL_TEST_CATEGORIES + 1))
    
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED_TEST_CATEGORIES=$((PASSED_TEST_CATEGORIES + 1))
        log_test "$test_name" "PASS" "$output" "$duration"
        
        # Display table row
        printf "${CYAN}│ %02d  │ %-50s │ ${GREEN}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "PASS" "$duration"
        
        # Parse and display individual test results
        parse_individual_test_results "$test_name"
    elif [ $exit_code -eq 124 ]; then
        echo -e "${YELLOW}⏰ TIMEOUT${NC}"
        SKIPPED_TEST_CATEGORIES=$((SKIPPED_TEST_CATEGORIES + 1))
        log_test "$test_name" "TIMEOUT" "Tests timed out after ${TEST_TIMEOUT}s" "$TEST_TIMEOUT"
        
        # Display table row
        printf "${CYAN}│ %02d  │ %-50s │ ${YELLOW}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "TIMEOUT" "$TEST_TIMEOUT"
    else
        echo -e "${RED}✗ FAIL${NC}"
        FAILED_TEST_CATEGORIES=$((FAILED_TEST_CATEGORIES + 1))
        FAILED_TEST_CATEGORY_NAMES+=("$test_name")
        log_test "$test_name" "FAIL" "$output" "$duration"
        
        # Display table row
        printf "${CYAN}│ %02d  │ %-50s │ ${RED}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "FAIL" "$duration"
        
        # Even for failed categories, try to parse individual results
        parse_individual_test_results "$test_name"
    fi
}

# Main test execution
echo "[INFO] Starting C++ test suite execution..."
echo ""

# Display table header for test categories
echo -e "${CYAN}┌─────┬──────────────────────────────────────────────────────────────────┬────────┬─────────┐${NC}"
echo -e "${CYAN}│ #   │ Test Category                                                    │ Result │ Time    │${NC}"
echo -e "${CYAN}├─────┼──────────────────────────────────────────────────────────────────┼────────┼─────────┤${NC}"

# Run core tests
run_test_category "core-tests"

# Run CLI tests
run_test_category "cli-tests"

# Run utility tests
run_test_category "utility-tests"

# Run analyzer tests
run_test_category "analyzer-tests"

# Close table
echo -e "${CYAN}└─────┴──────────────────────────────────────────────────────────────────┴────────┴─────────┘${NC}"

# Generate final summary
echo ""
echo "=========================================="
echo "           FINAL SUMMARY"
echo "=========================================="
echo "Test Categories:"
echo "  Total categories: $TOTAL_TEST_CATEGORIES"
echo -e "  Passed: ${GREEN}$PASSED_TEST_CATEGORIES${NC}"
echo -e "  Failed: ${RED}$FAILED_TEST_CATEGORIES${NC}"
echo -e "  Skipped: ${YELLOW}$SKIPPED_TEST_CATEGORIES${NC}"

echo ""
echo "Individual Tests:"
echo "  Total tests: $TOTAL_INDIVIDUAL_TESTS"
echo -e "  Passed: ${GREEN}$PASSED_INDIVIDUAL_TESTS${NC}"
echo -e "  Failed: ${RED}$FAILED_INDIVIDUAL_TESTS${NC}"

# Calculate success rates
CATEGORY_SUCCESS_RATE=0
INDIVIDUAL_SUCCESS_RATE=0

if [ "$TOTAL_TEST_CATEGORIES" -gt 0 ]; then
    CATEGORY_SUCCESS_RATE=$((PASSED_TEST_CATEGORIES * 100 / TOTAL_TEST_CATEGORIES))
fi

if [ "$TOTAL_INDIVIDUAL_TESTS" -gt 0 ]; then
    INDIVIDUAL_SUCCESS_RATE=$((PASSED_INDIVIDUAL_TESTS * 100 / TOTAL_INDIVIDUAL_TESTS))
fi

echo "  Category success rate: $CATEGORY_SUCCESS_RATE%"
echo "  Individual test success rate: $INDIVIDUAL_SUCCESS_RATE%"

# Show failed test categories if any
if [ ${#FAILED_TEST_CATEGORY_NAMES[@]} -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed test categories:${NC}"
    for test_name in "${FAILED_TEST_CATEGORY_NAMES[@]}"; do
        echo -e "  ${RED}❌ $test_name${NC}"
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
    echo "TEST CATEGORIES:"
    echo "  Total categories: $TOTAL_TEST_CATEGORIES"
    echo "  Passed: $PASSED_TEST_CATEGORIES"
    echo "  Failed: $FAILED_TEST_CATEGORIES"
    echo "  Skipped: $SKIPPED_TEST_CATEGORIES"
    echo "  Success rate: $CATEGORY_SUCCESS_RATE%"
    echo ""
    echo "INDIVIDUAL TESTS:"
    echo "  Total tests: $TOTAL_INDIVIDUAL_TESTS"
    echo "  Passed: $PASSED_INDIVIDUAL_TESTS"
    echo "  Failed: $FAILED_INDIVIDUAL_TESTS"
    echo "  Success rate: $INDIVIDUAL_SUCCESS_RATE%"
    echo ""
    if [ ${#FAILED_TEST_CATEGORY_NAMES[@]} -gt 0 ]; then
        echo "Failed test categories:"
        for test_name in "${FAILED_TEST_CATEGORY_NAMES[@]}"; do
            echo "  - $test_name"
        done
        echo ""
    fi
    echo "Detailed results available in: $DETAILED_LOG"
} > "$SUMMARY_FILE"

# Exit with appropriate code
if [ "$FAILED_TEST_CATEGORIES" -eq 0 ] && [ "$PASSED_TEST_CATEGORIES" -gt 0 ]; then
    echo ""
    echo -e "${GREEN}All C++ test categories passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}Some C++ test categories failed!${NC}"
    exit 1
fi
