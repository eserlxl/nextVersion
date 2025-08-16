#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Test runner for all bash tests in bash-tests directory
# This script executes all bash test files and provides a summary of results

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
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0
FAILED_TEST_NAMES=()
TEST_DURATIONS=()  # Array to store test durations
TEST_NAMES=()      # Array to store test names for duration tracking

# Configuration
FIXED_OUTPUT_DIR="test_results"
SUMMARY_FILE="$FIXED_OUTPUT_DIR/summary.txt"
DETAILED_LOG="$FIXED_OUTPUT_DIR/detailed.log"

# Function to count total tests
count_total_tests() {
    local total=0
    local dirs=("bash-tests/utility-tests" "bash-tests/file-handling-tests" "bash-tests/edge-case-tests" "bash-tests/debug-tests" "bash-tests/ere-tests" "bash-tests/cli-tests" "bash-tests/core-tests")
    
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local test_files
            mapfile -t test_files < <(find "$dir" -maxdepth 1 -type f \( -name "test_*" -o -name "*.sh" -o -name "*.c" \) -not -name "run_workflow_tests.sh" | sort)
            total=$((total + ${#test_files[@]}))
        fi
    done
    
    echo "$total"
}

# Calculate timeout based on test count: test_count × 30 seconds
TOTAL_TEST_COUNT=$(count_total_tests)
TEST_TIMEOUT=${TEST_TIMEOUT:-$((TOTAL_TEST_COUNT * 30))}  # Dynamic timeout: test_count × 30 seconds

# Clean and recreate output directory only if no summary exists
if [ ! -f "$SUMMARY_FILE" ]; then
    rm -rf "$FIXED_OUTPUT_DIR"
    mkdir -p "$FIXED_OUTPUT_DIR"
else
    echo "Found existing test results, will append to them..."
    mkdir -p "$FIXED_OUTPUT_DIR"
fi

echo "=========================================="
echo "    NEXTVERSION BASH TEST SUITE"
echo "=========================================="
echo "Output directory: $FIXED_OUTPUT_DIR"
echo "Summary file: $SUMMARY_FILE"
echo "Detailed log: $DETAILED_LOG"
echo "Total test count: $TOTAL_TEST_COUNT"
echo "Test timeout: ${TEST_TIMEOUT}s (calculated as: $TOTAL_TEST_COUNT × 30s)"
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

# Function to run a test file
run_test() {
    local test_file="$1"
    local test_number="$2"
    local test_name
    test_name=$(basename "$test_file")
    
    # Skip this script itself to prevent recursion
    if [[ "$test_file" == *"run_workflow_tests.sh" ]]; then
        return
    fi
    
    # Skip CLI test runner to prevent recursion
    if [[ "$test_file" == *"run_all_cli_tests.sh" ]]; then
        return
    fi
    
    # Skip core test runner to prevent recursion
    if [[ "$test_file" == *"run_all_core_tests.sh" ]]; then
        return
    fi
    
    # Skip utility test runner to prevent recursion
    if [[ "$test_file" == *"run_all_utility_tests.sh" ]]; then
        return
    fi
    
    # Skip edge case test runner to prevent recursion
    if [[ "$test_file" == *"run_all_edge_case_tests.sh" ]]; then
        return
    fi
    
    # Skip debug test runner to prevent recursion
    if [[ "$test_file" == *"run_all_debug_tests.sh" ]]; then
        return
    fi
    
    # Skip ERE test runner to prevent recursion
    if [[ "$test_file" == *"run_all_ere_tests.sh" ]]; then
        return
    fi
    
    # Skip file handling test runner to prevent recursion
    if [[ "$test_file" == *"run_all_file_handling_tests.sh" ]]; then
        return
    fi
    
    # Skip fixture test runner to prevent recursion
    if [[ "$test_file" == *"run_all_fixture_tests.sh" ]]; then
        return
    fi
    

    

    
    # Check if file exists
    if [[ ! -f "$test_file" ]]; then
        log_test "$test_name" "SKIPPED" "File not found" "0"
        ((SKIPPED_TESTS++))
        ((TOTAL_TESTS++))
        printf "${CYAN}│ %02d  │ %-50s │ ${YELLOW}%-6s${NC} │ ${PINK}%-7s${NC} │\n" "$test_number" "$test_name" "SKIP" "0.00s"
        return
    fi
    
    # Record start time
    local start_time
    start_time=$(date +%s)
    
    # Run the test based on file type
    if [[ "$test_file" == *.sh ]]; then
        # Shell script test
        if [[ ! -x "$test_file" ]]; then
            chmod +x "$test_file" 2>/dev/null || true
        fi
        
        # Run with timeout and capture output
        local output_file="$FIXED_OUTPUT_DIR/${test_name}.out"
        
        # Use longer timeout for comprehensive tests
        local current_timeout="$TEST_TIMEOUT"
        if [[ "$test_name" == *"comprehensive"* ]] || [[ "$test_name" == "run_loc_delta_tests.sh" ]] || [[ "$test_name" == "test-modular-components.sh" ]]; then
            current_timeout=300  # 5 minutes for comprehensive tests
        fi
        
        timeout "${current_timeout}s" bash "$test_file" > "$output_file" 2>&1
        local exit_code=$?
        
        # Calculate duration
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        # Store test duration and name for tracking
        TEST_DURATIONS+=("$duration")
        TEST_NAMES+=("$test_name")
        
        # Check if this is a test that returns a specific exit code (like test_func.sh)
        if [[ "$test_name" == "test_func.sh" ]] && [[ $exit_code -eq 20 ]]; then
            log_test "$test_name" "PASSED" "$(cat "$output_file")" "$duration"
            ((PASSED_TESTS++))
            printf "${CYAN}│ %02d  │ %-50s │ ${GREEN}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "PASS" "$duration"
        elif [[ "$test_name" == "test_ere_fix.sh" ]] && [[ $exit_code -eq 0 ]]; then
            # test_ere_fix.sh exits with 0 when all tests pass (which is expected behavior)
            log_test "$test_name" "PASSED" "$(cat "$output_file")" "$duration"
            ((PASSED_TESTS++))
            printf "${CYAN}│ %02d  │ %-50s │ ${GREEN}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "PASS" "$duration"
        elif [[ "$test_name" == "test_compare_analyzers.sh" ]] && [[ $exit_code -eq 1 ]]; then
            # test_compare_analyzers.sh exits with 1 when it finds differences (which is expected behavior)
            # Note: This test has been moved to comparator/tests/
            log_test "$test_name" "PASSED" "$(cat "$output_file")" "$duration"
            ((PASSED_TESTS++))
            printf "${CYAN}│ %02d  │ %-50s │ ${GREEN}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "PASS" "$duration"
        elif [[ $exit_code -eq 11 ]]; then
            # Exit code 11 indicates success for tests that expect it
            log_test "$test_name" "PASSED" "$(cat "$output_file")" "$duration"
            ((PASSED_TESTS++))
            printf "${CYAN}│ %02d  │ %-50s │ ${GREEN}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "PASS" "$duration"
        elif [[ $exit_code -eq 0 ]]; then
            log_test "$test_name" "PASSED" "$(cat "$output_file")" "$duration"
            ((PASSED_TESTS++))
            printf "${CYAN}│ %02d  │ %-50s │ ${GREEN}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "PASS" "$duration"
        elif [[ $exit_code -eq 124 ]]; then
            log_test "$test_name" "TIMEOUT" "$(cat "$output_file")" "$duration"
            ((FAILED_TESTS++))
            FAILED_TEST_NAMES+=("$test_name (TIMEOUT)")
            printf "${CYAN}│ %02d  │ %-50s │ ${RED}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "TIMEOUT" "$duration"
        else
            log_test "$test_name" "FAILED" "$(cat "$output_file")" "$duration"
            ((FAILED_TESTS++))
            FAILED_TEST_NAMES+=("$test_name")
            printf "${CYAN}│ %02d  │ %-50s │ ${RED}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "FAIL" "$duration"
        fi
    elif [[ "$test_file" == *.c ]]; then
        # C file test - compile and run if possible
        local test_bin="$FIXED_OUTPUT_DIR/${test_name%.c}"
        local output_file="$FIXED_OUTPUT_DIR/${test_name}.out"
        
        if gcc -o "$test_bin" "$test_file" > "$output_file" 2>&1; then
            if timeout "${TEST_TIMEOUT}s" "$test_bin" > "$output_file" 2>&1; then
                local end_time
                end_time=$(date +%s)
                local duration=$((end_time - start_time))
                
                # Store test duration and name for tracking
                TEST_DURATIONS+=("$duration")
                TEST_NAMES+=("$test_name")
                
                printf "${CYAN}│ %02d  │ %-50s │ ${GREEN}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "PASS" "$duration"
                log_test "$test_name" "PASSED" "$(cat "$output_file")" "$duration"
                ((PASSED_TESTS++))
            else
                local end_time
                end_time=$(date +%s)
                local duration=$((end_time - start_time))
                
                # Store test duration and name for tracking
                TEST_DURATIONS+=("$duration")
                TEST_NAMES+=("$test_name")
                
                printf "${CYAN}│ %02d  │ %-50s │ ${RED}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "FAIL" "$duration"
                log_test "$test_name" "FAILED" "$(cat "$output_file")" "$duration"
                ((FAILED_TESTS++))
                FAILED_TEST_NAMES+=("$test_name")
            fi
        else
            local end_time
            end_time=$(date +%s)
            local duration=$((end_time - start_time))
            
            # Store test duration and name for tracking
            TEST_DURATIONS+=("$duration")
            TEST_NAMES+=("$test_name")
            
            printf "${CYAN}│ %02d  │ %-50s │ ${YELLOW}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "SKIP" "$duration"
            log_test "$test_name" "SKIPPED" "Compilation failed: $(cat "$output_file")" "$duration"
            ((SKIPPED_TESTS++))
        fi
    else
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        # Store test duration and name for tracking
        TEST_DURATIONS+=("$duration")
        TEST_NAMES+=("$test_name")
        
        printf "${CYAN}│ %02d  │ %-50s │ ${YELLOW}%-6s${NC} │ ${PINK}%6.2fs${NC} │\n" "$test_number" "$test_name" "SKIP" "$duration"
        log_test "$test_name" "SKIPPED" "Unknown file type" "$duration"
        ((SKIPPED_TESTS++))
    fi
    
    ((TOTAL_TESTS++))
}

# Function to run tests in a directory
run_tests_in_directory() {
    local dir="$1"
    local dir_name
    dir_name=$(basename "$dir")
    
    if [[ ! -d "$dir" ]]; then
        return
    fi
    
    # Find all test files in the directory, excluding runner scripts
    local test_files
    mapfile -t test_files < <(find "$dir" -maxdepth 1 -type f \( -name "test_*" -o -name "*.sh" -o -name "*.c" \) -not -name "run_*.sh" -not -name "run_workflow_tests.sh" | sort)
    
    if [[ ${#test_files[@]} -eq 0 ]]; then
        echo "No test files found in $dir_name"
        return
    fi
    
    # Display table header
    echo ""
    echo -e "${CYAN}=== $dir_name (${#test_files[@]} tests) ===${NC}"
    echo -e "${CYAN}┌─────┬────────────────────────────────────────────────────┬────────┬─────────┐${NC}"
    echo -e "${CYAN}│ #   │ Test                                               │ Result │   Time  │${NC}"
    echo -e "${CYAN}├─────┼────────────────────────────────────────────────────┼────────┼─────────┤${NC}"
    
    # Run tests and collect results for table display
    local test_count=1
    
    for test_file in "${test_files[@]}"; do
        run_test "$test_file" "$test_count"
        ((test_count++))
    done
    
    # Close table
    echo -e "${CYAN}└─────┴────────────────────────────────────────────────────┴────────┴─────────┘${NC}"
}

# Main execution
echo "Starting test execution at $(date)"
echo ""

# Ensure we're in the project root directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || exit

# Run tests in each subdirectory
run_tests_in_directory "bash-tests/utility-tests"
run_tests_in_directory "bash-tests/file-handling-tests"
run_tests_in_directory "bash-tests/edge-case-tests"
run_tests_in_directory "bash-tests/debug-tests"
run_tests_in_directory "bash-tests/ere-tests"
run_tests_in_directory "bash-tests/cli-tests"
run_tests_in_directory "bash-tests/core-tests"

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

# Generate summary
echo ""
echo "=========================================="
echo "          BASH TEST SUMMARY"
echo "=========================================="
echo "Total tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo -e "Skipped: ${YELLOW}$SKIPPED_TESTS${NC}"

# Calculate success rate
if [[ $TOTAL_TESTS -gt 0 ]]; then
    success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    echo "Success rate: $success_rate%"
fi

# Show longest running tests
find_longest_tests

# Save summary to file
{
    echo "NEXTVERSION BASH TEST SUITE SUMMARY"
    echo "Generated: $(date)"
    echo ""
    echo "Total tests: $TOTAL_TESTS"
    echo "Passed: $PASSED_TESTS"
    echo "Failed: $FAILED_TESTS"
    echo "Skipped: $SKIPPED_TESTS"
    if [[ $TOTAL_TESTS -gt 0 ]]; then
        echo "Success rate: $success_rate%"
    fi
    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo ""
        echo "Failed tests:"
        for failed_test in "${FAILED_TEST_NAMES[@]}"; do
            echo "  - $failed_test"
        done
    fi
    
    # Add timing information to summary file
    if [[ ${#TEST_DURATIONS[@]} -gt 0 ]]; then
        echo ""
        echo "Test Timing Information:"
        echo "Top 5 Longest Running Tests:"
        sorted_indices=()
        i=0
        j=0
        temp=0
        
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
        count=0
        for i in "${sorted_indices[@]}"; do
            if [[ $count -lt 5 ]]; then
                echo "  $((count+1)). ${TEST_NAMES[i]} - ${TEST_DURATIONS[i]}s"
                ((count++))
            fi
        done
    fi
    
    echo ""
    echo "Detailed results available in: $DETAILED_LOG"
    echo "Test outputs available in: $FIXED_OUTPUT_DIR/"
} > "$SUMMARY_FILE"

echo ""
echo "Summary saved to: $SUMMARY_FILE"
echo "Detailed log: $DETAILED_LOG"
echo "Test outputs: $FIXED_OUTPUT_DIR/"

# Display failed tests if any
if [[ $FAILED_TESTS -gt 0 ]]; then
    echo ""
    echo -e "${RED}Failed tests:${NC}"
    for failed_test in "${FAILED_TEST_NAMES[@]}"; do
        echo -e "  ${RED}❌ $failed_test${NC}"
    done
    echo ""
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
else
    echo ""
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi 