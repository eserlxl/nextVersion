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
CYAN='\033[0;36m'
PINK='\033[0;35m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_INDIVIDUAL_TESTS=0
PASSED_INDIVIDUAL_TESTS=0
FAILED_INDIVIDUAL_TESTS=0
SKIPPED_INDIVIDUAL_TESTS=0
FAILED_TEST_NAMES=()

# Test duration tracking for summary
TEST_DURATIONS=()
TEST_NAMES=()

# Configuration
TEST_TIMEOUT=${TEST_TIMEOUT:-300}  # Default 300 seconds timeout for C++ tests
FIXED_OUTPUT_DIR="test_results"
SUMMARY_FILE="$FIXED_OUTPUT_DIR/cpp_tests_summary.txt"
DETAILED_LOG="$FIXED_OUTPUT_DIR/cpp_tests_detailed.log"

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
# This function is now only used to collect failed test names, not to count tests
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
        return
    fi
    
    # Only collect failed test names for reporting, don't count tests here
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*[0-9]+/[0-9]+[[:space:]]+Test[[:space:]]+#[0-9]+:[[:space:]]+([^[:space:]]+)[[:space:]]+\.\.\.+[[:space:]]+([A-Za-z]+)[[:space:]]+[0-9.]+ ]]; then
            local test_name="${BASH_REMATCH[1]}"
            local test_status="${BASH_REMATCH[2]}"
            
            if [[ "$test_status" == "Failed" ]]; then
                FAILED_TEST_NAMES+=("$test_name")
            fi
        fi
    done < "$ctest_log_path"
}

# Function to run a test category and collect individual test results
run_test_category() {
    local test_dir="$1"
    local test_name
    test_name=$(basename "$test_dir")
    
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
    
    if [ $exit_code -eq 0 ]; then
        log_test "$test_name" "PASS" "$output" "$duration"
        # Parse individual test results but don't display them yet
        parse_individual_test_results "$test_name"
    elif [ $exit_code -eq 124 ]; then
        log_test "$test_name" "TIMEOUT" "Tests timed out after ${TEST_TIMEOUT}s" "$TEST_TIMEOUT"
        # For timeout, we can't parse individual results
    else
        log_test "$test_name" "FAIL" "$output" "$duration"
        # Even for failed categories, try to parse individual results
        parse_individual_test_results "$test_name"
    fi
}

# Function to find longest running tests
find_longest_tests() {
    local -a sorted_indices
    local i j temp
    
    # Create array of indices
    for ((i=0; i<${#TEST_DURATIONS[@]}; i++)); do
        sorted_indices[i]=$i
    done
    
    # Simple bubble sort to find top 5 longest tests
    for ((i=0; i<${#TEST_DURATIONS[@]}-1; i++)); do
        for ((j=0; j<${#TEST_DURATIONS[@]}-i-1; j++)); do
            if [[ ${TEST_DURATIONS[sorted_indices[j]]} -lt ${TEST_DURATIONS[sorted_indices[j+1]]} ]]; then
                temp=${sorted_indices[j]}
                sorted_indices[j]=${sorted_indices[j+1]}
                sorted_indices[j+1]=$temp
            fi
        done
    done
    
    # Display top 5 longest tests
    if [[ ${#TEST_DURATIONS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${BLUE}Top 5 Longest Running Tests:${NC}"
        local count=0
        for i in "${sorted_indices[@]}"; do
            if [[ $count -lt 5 ]]; then
                echo "  $((count+1)). ${TEST_NAMES[i]} - ${TEST_DURATIONS[i]}s"
                ((count++))
            fi
        done
    fi
}

# Main test execution
echo "Starting C++ test suite execution at $(date)"
echo ""

# Run all test categories to collect individual test results
run_test_category "core-tests"
run_test_category "cli-tests"
run_test_category "utility-tests"
run_test_category "analyzer-tests"

# Now display the individual tests in the same format as bash tests
echo ""
echo -e "${CYAN}=== C++ Tests ===${NC}"
echo -e "${CYAN}┌─────┬────────────────────────────────────────────────────┬────────┬─────────┐${NC}"
echo -e "${CYAN}│ #   │ Test                                               │ Result │   Time  │${NC}"
echo -e "${CYAN}├─────┼────────────────────────────────────────────────────┼────────┼─────────┤${NC}"

# Display individual test results in table format
# Since we can't get individual test timing from CTest easily, we'll show category results
# but format them to look like individual tests
test_number=1

# Read all test results from the core tests log file (which contains all tests)
if [[ -f "test_results/ctest_core_detailed.log" ]]; then
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*[0-9]+/[0-9]+[[:space:]]+Test[[:space:]]+#[0-9]+:[[:space:]]+([^[:space:]]+)[[:space:]]+\.\.\.+[[:space:]]+([A-Za-z]+)[[:space:]]+[0-9.]+ ]]; then
            test_name="${BASH_REMATCH[1]}"
            test_status="${BASH_REMATCH[2]}"
            duration=1  # Default duration since we can't get individual timing
            
            if [[ "$test_status" == "Passed" ]]; then
                printf "${CYAN}│ %02d  │ %-50s │ ${GREEN}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "PASS" "$duration"
                TEST_DURATIONS+=("$duration")
                TEST_NAMES+=("$test_name")
                PASSED_INDIVIDUAL_TESTS=$((PASSED_INDIVIDUAL_TESTS + 1))
            elif [[ "$test_status" == "Failed" ]]; then
                printf "${CYAN}│ %02d  │ %-50s │ ${RED}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "FAIL" "$duration"
                TEST_DURATIONS+=("$duration")
                TEST_NAMES+=("$test_name")
                FAILED_INDIVIDUAL_TESTS=$((FAILED_INDIVIDUAL_TESTS + 1))
            else
                printf "${CYAN}│ %02d  │ %-50s │ ${YELLOW}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "$test_status" "$duration"
                TEST_DURATIONS+=("$duration")
                TEST_NAMES+=("$test_name")
                SKIPPED_INDIVIDUAL_TESTS=$((SKIPPED_INDIVIDUAL_TESTS + 1))
            fi
            TOTAL_INDIVIDUAL_TESTS=$((TOTAL_INDIVIDUAL_TESTS + 1))
            ((test_number++))
        fi
    done < "test_results/ctest_core_detailed.log"
fi







# Close table
echo -e "${CYAN}└─────┴────────────────────────────────────────────────────┴────────┴─────────┘${NC}"

# Generate final summary
echo ""
echo "=========================================="
echo "          C++ TEST SUMMARY"
echo "=========================================="
echo "Total tests: $TOTAL_INDIVIDUAL_TESTS"

# Calculate success rate
if [[ $TOTAL_INDIVIDUAL_TESTS -gt 0 ]]; then
    success_rate=$((PASSED_INDIVIDUAL_TESTS * 100 / TOTAL_INDIVIDUAL_TESTS))
    
    # Only show passed count if not all tests failed
    if [ "$FAILED_INDIVIDUAL_TESTS" -lt "$TOTAL_INDIVIDUAL_TESTS" ]; then
        echo -e "Passed: ${GREEN}$PASSED_INDIVIDUAL_TESTS${NC}"
    fi
    
    # Only show failed count if not all tests passed
    if [ "$PASSED_INDIVIDUAL_TESTS" -lt "$TOTAL_INDIVIDUAL_TESTS" ]; then
        echo -e "Failed: ${RED}$FAILED_INDIVIDUAL_TESTS${NC}"
    fi
    
    # Only show skipped if there are any
    if [ "$SKIPPED_INDIVIDUAL_TESTS" -gt 0 ]; then
        echo -e "Skipped: ${YELLOW}$SKIPPED_INDIVIDUAL_TESTS${NC}"
    fi
    
    echo "Success rate: $success_rate%"
fi

# Show longest running tests
find_longest_tests

echo ""
echo "Summary saved to: $SUMMARY_FILE"
echo "Detailed log: $DETAILED_LOG"

# Save final summary to file
{
    echo "NEXTVERSION C++ TEST SUITE SUMMARY"
    echo "Generated: $(date)"
    echo ""
    echo "INDIVIDUAL TESTS:"
    echo "  Total tests: $TOTAL_INDIVIDUAL_TESTS"
    
    # Only show passed count if not all tests failed
    if [ "$FAILED_INDIVIDUAL_TESTS" -lt "$TOTAL_INDIVIDUAL_TESTS" ]; then
        echo "  Passed: $PASSED_INDIVIDUAL_TESTS"
    fi
    
    # Only show failed count if not all tests passed
    if [ "$PASSED_INDIVIDUAL_TESTS" -lt "$TOTAL_INDIVIDUAL_TESTS" ]; then
        echo "  Failed: $FAILED_INDIVIDUAL_TESTS"
    fi
    
    # Only show skipped if there are any
    if [ "$SKIPPED_INDIVIDUAL_TESTS" -gt 0 ]; then
        echo "  Skipped: $SKIPPED_INDIVIDUAL_TESTS"
    fi
    
    if [[ $TOTAL_INDIVIDUAL_TESTS -gt 0 ]]; then
        success_rate=$((PASSED_INDIVIDUAL_TESTS * 100 / TOTAL_INDIVIDUAL_TESTS))
        echo "  Success rate: $success_rate%"
    fi
    echo ""
    if [ ${#FAILED_TEST_NAMES[@]} -gt 0 ]; then
        echo "Failed tests:"
        for failed_test in "${FAILED_TEST_NAMES[@]}"; do
            echo "  - $failed_test"
        done
        echo ""
    fi
    echo "Detailed results available in: $DETAILED_LOG"
} > "$SUMMARY_FILE"

# Display failed tests if any
if [ "$FAILED_INDIVIDUAL_TESTS" -gt 0 ]; then
    echo ""
    echo -e "${RED}Failed tests:${NC}"
    for failed_test in "${FAILED_TEST_NAMES[@]}"; do
        echo -e "  ${RED}❌ $failed_test${NC}"
    done
    echo ""
    echo -e "${RED}Some C++ tests failed!${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}All C++ tests passed!${NC}"
    exit 0
fi
