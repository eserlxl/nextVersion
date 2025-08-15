#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Test file parsing functionality

set -Euo pipefail

# Source test helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

# Function to test file parsing
test_file_parsing() {
    local test_name="$1"
    local file_content="$2"
    local parsing_command="$3"
    local expected_pattern="$4"
    
    # Create a temporary test file
    local temp_file="/tmp/file_parsing_test_$$.txt"
    echo -e "$file_content" > "$temp_file"
    
    # Test file parsing
    local output
    output=$(eval "$parsing_command" < "$temp_file")
    
    if echo "$output" | grep -q "$expected_pattern"; then
        log_test_result "$test_name" "PASS" "File parsing matches expected pattern"
        ((TESTS_PASSED++))
    else
        log_test_result "$test_name" "FAIL" "File parsing doesn't match expected pattern"
        echo "Expected: $expected_pattern"
        echo "Got: $output"
        ((TESTS_FAILED++))
    fi
    
    # Cleanup
    rm -f "$temp_file"
}

# Main test execution
main() {
    echo "Starting file parsing tests"
    echo "=========================="
    
    # Test CSV parsing
    test_file_parsing "CSV field parsing" "name,age,city\nJohn,25,NYC\nJane,30,LA" "awk -F',' 'NR>1 {print \$1}'" "John"
    test_file_parsing "CSV line counting" "name,age,city\nJohn,25,NYC\nJane,30,LA" "awk 'END{print NR}'" "3"
    
    # Test JSON-like parsing
    test_file_parsing "Key-value parsing" "name=John\nage=25\ncity=NYC" "grep '^name=' | cut -d'=' -f2" "John"
    test_file_parsing "Key-value counting" "name=John\nage=25\ncity=NYC" "grep -c '='" "3"
    
    # Test configuration file parsing
    test_file_parsing "Config file parsing" "PORT=8080\nHOST=localhost\nDEBUG=true" "grep '^PORT=' | cut -d'=' -f2" "8080"
    test_file_parsing "Config boolean parsing" "PORT=8080\nHOST=localhost\nDEBUG=true" "grep '^DEBUG=' | cut -d'=' -f2" "true"
    
    # Test log file parsing
    test_file_parsing "Log timestamp parsing" "2025-01-01 12:00:00 INFO: Test message\n2025-01-01 12:01:00 ERROR: Error message" "grep 'ERROR' | wc -l" "1"
    test_file_parsing "Log level counting" "2025-01-01 12:00:00 INFO: Test message\n2025-01-01 12:01:00 ERROR: Error message" "grep -o 'INFO\|ERROR' | sort | uniq -c | wc -l" "2"
    
    # Test structured text parsing
    test_file_parsing "Structured text parsing" "---\nname: John\nage: 25\n---\nname: Jane\nage: 30" "grep -A1 'name: John' | grep 'age:' | cut -d' ' -f2" "25"
    
    # Test XML-like parsing
    test_file_parsing "XML-like tag parsing" "<user><name>John</name><age>25</age></user>" "grep -o '<name>[^<]*</name>' | sed 's/<[^>]*>//g'" "John"
    
    # Test parsing with sed
    run_test "Sed line parsing" 0 "echo 'line1:value1' | sed 's/.*://'" "value1"
    run_test "Sed multiple parsing" 0 "printf 'line1:value1\nline2:value2\n' | sed 's/.*://' | wc -l" "2"
    
    # Test parsing with awk
    run_test "Awk field parsing" 0 "echo 'field1|field2|field3' | awk -F'|' '{print \$2}'" "field2"
    run_test "Awk conditional parsing" 0 "printf 'a:1\nb:2\nc:3\n' | awk -F':' '\$2>1 {print \$1}' | wc -l" "2"
    
    # Test parsing with grep
    run_test "Grep pattern parsing" 0 "printf 'test1\nTEST2\ntest3\n' | grep -i 'test' | wc -l" "3"
    run_test "Grep regex parsing" 0 "printf 'abc123\ndef456\nghi789\n' | grep -E '[0-9]{3}' | wc -l" "3"
    
    # Test parsing error handling
    run_test "Parsing empty file" 0 "echo '' | wc -l" "1"
    run_test "Parsing malformed input" 0 "echo 'invalid:format:here' | awk -F':' '{print NF}'" "3"
    
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
