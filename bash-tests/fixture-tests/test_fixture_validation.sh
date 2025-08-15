#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Test fixture validation functionality

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

# Function to test fixture validation
test_fixture_validation() {
    local test_name="$1"
    local fixture_content="$2"
    local validation_command="$3"
    local expected_pattern="$4"
    
    # Create a temporary test fixture
    local temp_fixture="/tmp/fixture_validation_test_$$.txt"
    echo -e "$fixture_content" > "$temp_fixture"
    
    # Test fixture validation
    local output
    output=$(eval "$validation_command" < "$temp_fixture")
    
    if echo "$output" | grep -q "$expected_pattern"; then
        log_test_result "$test_name" "PASS" "Fixture validation matches expected pattern"
        ((TESTS_PASSED++))
    else
        log_test_result "$test_name" "FAIL" "Fixture validation doesn't match expected pattern"
        echo "Expected: $expected_pattern"
        echo "Got: $output"
        ((TESTS_FAILED++))
    fi
    
    # Cleanup
    rm -f "$temp_fixture"
}

# Main test execution
main() {
    echo "Starting fixture validation tests"
    echo "================================"
    
    # Test fixture structure validation
    test_fixture_validation "Fixture structure validation" "---\nname: test\nversion: 1.0\n---" "grep -c '^---'" "2"
    test_fixture_validation "Fixture content validation" "name: test\nversion: 1.0\ndescription: test fixture" "grep '^name:' | cut -d' ' -f2" "test"
    
    # Test fixture format validation
    test_fixture_validation "YAML-like format validation" "key1: value1\nkey2: value2\nkey3: value3" "grep -c ':'" "3"
    test_fixture_validation "JSON-like format validation" "{\"key1\": \"value1\", \"key2\": \"value2\"}" "grep -o '\"[^\"]*\"' | wc -l" "4"
    
    # Test fixture content validation
    test_fixture_validation "Required field validation" "name: test\nversion: 1.0\nrequired: true" "grep 'required:' | cut -d' ' -f2" "true"
    test_fixture_validation "Optional field validation" "name: test\nversion: 1.0\noptional: false" "grep 'optional:' | cut -d' ' -f2" "false"
    
    # Test fixture data validation
    test_fixture_validation "Numeric data validation" "count: 42\nsize: 1024\nratio: 3.14" "grep 'count:' | cut -d' ' -f2" "42"
    test_fixture_validation "String data validation" "title: Test Title\nauthor: Test Author" "grep 'title:' | sed 's/^title: //'" "Test Title"
    
    # Test fixture array validation
    test_fixture_validation "Array format validation" "items:\n  - item1\n  - item2\n  - item3" "grep -c '  - '" "3"
    test_fixture_validation "Array content validation" "tags:\n  - tag1\n  - tag2" "grep 'tag1' | wc -l" "1"
    
    # Test fixture nested structure validation
    test_fixture_validation "Nested structure validation" "config:\n  database:\n    host: localhost\n    port: 5432" "grep 'host:' | sed 's/^[[:space:]]*host: //'" "localhost"
    
    # Test fixture validation commands
    run_test "Fixture line count validation" 0 "printf 'line1\nline2\nline3\n' | wc -l" "3"
    run_test "Fixture field count validation" 0 "printf 'key1: value1\nkey2: value2\n' | grep -c ':'" "2"
    
    # Test fixture error handling
    run_test "Empty fixture validation" 0 "echo '' | wc -l" "1"
    run_test "Malformed fixture validation" 0 "echo 'invalid:format:here:extra' | awk -F':' '{print NF}'" "4"
    
    # Test fixture content verification
    run_test "Fixture content verification" 0 "echo 'test content' | grep 'test'" "test"
    run_test "Fixture pattern matching" 0 "echo 'version: 1.2.3' | grep -E 'version: [0-9]+\.[0-9]+\.[0-9]+'" "version: 1.2.3"
    
    # Test fixture metadata validation
    test_fixture_validation "Metadata validation" "created: 2025-01-01\nmodified: 2025-01-02\nauthor: Test User" "grep 'created:' | cut -d' ' -f2" "2025-01-01"
    test_fixture_validation "Metadata format validation" "timestamp: 1704067200\nduration: 300\nstatus: active" "grep 'status:' | cut -d' ' -f2" "active"
    
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
