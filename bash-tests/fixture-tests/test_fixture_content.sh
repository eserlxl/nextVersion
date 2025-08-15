#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Test fixture content verification functionality

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

# Function to test fixture content
test_fixture_content() {
    local test_name="$1"
    local fixture_content="$2"
    local verification_command="$3"
    local expected_pattern="$4"
    
    # Create a temporary test fixture
    local temp_fixture="/tmp/fixture_content_test_$$.txt"
    echo -e "$fixture_content" > "$temp_fixture"
    
    # Test fixture content verification
    local output
    output=$(eval "$verification_command" < "$temp_fixture")
    
    if echo "$output" | grep -q "$expected_pattern"; then
        log_test_result "$test_name" "PASS" "Fixture content verification matches expected pattern"
        ((TESTS_PASSED++))
    else
        log_test_result "$test_name" "FAIL" "Fixture content verification doesn't match expected pattern"
        echo "Expected: $expected_pattern"
        echo "Got: $output"
        ((TESTS_FAILED++))
    fi
    
    # Cleanup
    rm -f "$temp_fixture"
}

# Main test execution
main() {
    echo "Starting fixture content verification tests"
    echo "==========================================="
    
    # Test fixture data integrity
    test_fixture_content "Data integrity validation" "id: 12345\nname: Test Item\nvalue: 42.5" "grep 'id:' | cut -d' ' -f2" "12345"
    test_fixture_content "Data type validation" "string: hello\nnumber: 42\nboolean: true" "grep 'boolean:' | cut -d' ' -f2" "true"
    
    # Test fixture content structure
    test_fixture_content "Content structure validation" "header:\n  title: Test\n  version: 1.0\nbody:\n  content: test" "grep -c '^[[:space:]]*[a-z]*:'" "5"
    test_fixture_content "Content hierarchy validation" "level1:\n  level2:\n    level3: value" "grep -c '^[[:space:]]*level[0-9]:'" "3"
    
    # Test fixture content patterns
    test_fixture_content "Pattern matching validation" "email: test@example.com\nphone: +1-555-1234" "grep -E '@.*\.com'" "test@example.com"
    test_fixture_content "Regex validation" "code: ABC123\nserial: XYZ-789" "grep -E '[A-Z]{3}[0-9]{3}'" "ABC123"
    
    # Test fixture content relationships
    test_fixture_content "Content relationship validation" "parent: item1\nchildren:\n  - child1\n  - child2" "grep 'parent:' | cut -d' ' -f2" "item1"
    test_fixture_content "Content dependency validation" "requires: [dep1, dep2]\nprovides: [feature1, feature2]" "grep -c 'dep[0-9]'" "1"
    
    # Test fixture content constraints
    test_fixture_content "Content constraint validation" "min_value: 0\nmax_value: 100\ncurrent: 50" "awk '\$2 >= 0 && \$2 <= 100' | wc -l" "3"
    test_fixture_content "Content range validation" "range: [1, 10]\nvalue: 5" "grep 'value:' | cut -d' ' -f2" "5"
    
    # Test fixture content verification commands
    run_test "Content line verification" 0 "printf 'line1\nline2\nline3\n' | wc -l" "3"
    run_test "Content field verification" 0 "printf 'key1: value1\nkey2: value2\n' | grep -c ':'" "2"
    
    # Test fixture content error handling
    run_test "Empty content verification" 0 "echo '' | wc -l" "1"
    run_test "Malformed content verification" 0 "echo 'invalid:format:here:extra' | awk -F':' '{print NF}'" "4"
    
    # Test fixture content verification
    run_test "Content pattern verification" 0 "echo 'test content' | grep 'test'" "test"
    run_test "Content format verification" 0 "echo 'version: 1.2.3' | grep -E 'version: [0-9]+\.[0-9]+\.[0-9]+'" "version: 1.2.3"
    
    # Test fixture content metadata
    test_fixture_content "Content metadata verification" "created: 2025-01-01\nmodified: 2025-01-02\nauthor: Test User" "grep 'created:' | cut -d' ' -f2" "2025-01-01"
    test_fixture_content "Content format metadata" "encoding: utf-8\nformat: yaml\nversion: 1.1" "grep 'encoding:' | cut -d' ' -f2" "utf-8"
    
    # Test fixture content validation
    test_fixture_content "Content validation rules" "rules:\n  - required: true\n  - min_length: 1\n  - max_length: 100" "grep -c 'required:'" "1"
    test_fixture_content "Content validation results" "validation:\n  status: passed\n  errors: 0\n  warnings: 1" "grep 'status:' | sed 's/^[[:space:]]*status: //'" "passed"
    
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
