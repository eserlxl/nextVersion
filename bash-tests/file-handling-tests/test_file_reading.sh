#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Test file reading functionality

set -Euo pipefail

# Source test helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../test_helper.sh"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to run a test
run_test() {
    local test_name="$1"
    local expected_exit="$2"
    local command="$3"
    local expected_output="$4"
    
    echo -e "${BLUE}Running: $test_name${NC}"
    
    # Run the command and capture output and exit code
    local output
    local exit_code
    output=$(eval "$command" 2>&1)
    exit_code=$?
    
    # Check exit code
    if [[ $exit_code -eq $expected_exit ]]; then
        # Check output if specified
        if [[ -n "$expected_output" ]]; then
            if echo "$output" | grep -q "$expected_output"; then
                log_test_result "$test_name" "PASS" "Exit code and output match expected"
                ((TESTS_PASSED++))
            else
                log_test_result "$test_name" "FAIL" "Exit code matches but output doesn't contain '$expected_output'"
                echo "Expected: $expected_output"
                echo "Got: $output"
                ((TESTS_FAILED++))
            fi
        else
            log_test_result "$test_name" "PASS" "Exit code matches expected"
            ((TESTS_PASSED++))
        fi
    else
        log_test_result "$test_name" "FAIL" "Expected exit code $expected_exit, got $exit_code"
        echo "Output: $output"
        ((TESTS_FAILED++))
    fi
}

# Function to test file reading
test_file_reading() {
    local test_name="$1"
    local file_content="$2"
    local expected_pattern="$3"
    
    # Create a temporary test file
    local temp_file="/tmp/file_reading_test_$$.txt"
    echo "$file_content" > "$temp_file"
    
    # Test file reading
    local output
    output=$(cat "$temp_file")
    
    if echo "$output" | grep -q "$expected_pattern"; then
        log_test_result "$test_name" "PASS" "File reading matches expected pattern"
        ((TESTS_PASSED++))
    else
        log_test_result "$test_name" "FAIL" "File reading doesn't match expected pattern"
        echo "Expected: $expected_pattern"
        echo "Got: $output"
        ((TESTS_FAILED++))
    fi
    
    # Cleanup
    rm -f "$temp_file"
}

# Main test execution
main() {
    echo "Starting file reading tests"
    echo "=========================="
    
    # Test basic file reading
    test_file_reading "Basic text file reading" "Hello World\nThis is a test file" "Hello World"
    test_file_reading "Multi-line file reading" "Line 1\nLine 2\nLine 3" "Line 2"
    test_file_reading "Empty file reading" "" ""
    
    # Test file reading commands
    run_test "Cat command file reading" 0 "echo 'test content' | cat" "test content"
    run_test "Head command file reading" 0 "printf 'line1\nline2\nline3\n' | head -n 2" "line1"
    run_test "Tail command file reading" 0 "printf 'line1\nline2\nline3\n' | tail -n 2" "line3"
    
    # Test file reading with grep
    run_test "File reading with grep" 0 "printf 'apple\nbanana\ncherry\n' | grep 'banana'" "banana"
    run_test "File reading with grep -v" 0 "printf 'apple\nbanana\ncherry\n' | grep -v 'banana' | wc -l" "2"
    
    # Test file reading with sed
    run_test "File reading with sed replacement" 0 "echo 'hello world' | sed 's/hello/goodbye/'" "goodbye world"
    run_test "File reading with sed line deletion" 0 "printf 'line1\nline2\nline3\n' | sed '2d' | wc -l" "2"
    
    # Test file reading with awk
    run_test "File reading with awk field extraction" 0 "echo 'field1,field2,field3' | awk -F',' '{print \$2}'" "field2"
    run_test "File reading with awk line counting" 0 "printf 'line1\nline2\nline3\n' | awk 'END{print NR}'" "3"
    
    # Test file reading error handling
    run_test "File reading non-existent file" 1 "cat /tmp/non_existent_file_$$" "No such file"
    
    # Test file reading permissions
    run_test "File reading permission check" 0 "touch /tmp/test_file_$$ && echo 'test' > /tmp/test_file_$$ && chmod 400 /tmp/test_file_$$ && cat /tmp/test_file_$$ && rm -f /tmp/test_file_$$" "test"
    
    echo ""
    echo "Test Summary:"
    echo "============="
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo "Total tests: $((TESTS_PASSED + TESTS_FAILED))"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
