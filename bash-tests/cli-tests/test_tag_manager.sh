#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# CLI tests for tag-manager.sh

set -Euo pipefail

# Source test helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
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

# Function to test help and version
test_help() {
    local test_name="$1"
    local command="$2"
    
    run_test "$test_name" 0 "$command" "Usage:"
}

# Function to test error conditions
test_error_condition() {
    local test_name="$1"
    local command="$2"
    local expected_error="$3"
    
    run_test "$test_name" 1 "$command" "$expected_error"
}

# Function to create a test git repository with tags
create_test_repo() {
    local temp_dir="$1"
    
    cd "$temp_dir" || return 1
    
    # Initialize git repository
    git init --quiet
    
    # Create initial commit
    echo "Initial content" > README.md
    git add README.md
    git commit --quiet -m "Initial commit"
    
    # Create some tags
    git tag v1.0.0
    git tag v1.1.0
    git tag v1.2.0
    git tag v2.0.0
    git tag v2.1.0
    
    # Create annotated tags
    git tag -a v1.0.1 -m "Annotated tag v1.0.1"
    git tag -a v1.1.1 -m "Annotated tag v1.1.1"
    
    return 0
}

# Main test execution
main() {
    echo "Starting CLI tests for tag-manager.sh"
    echo "===================================="
    
    # Test help
    test_help "Help flag" "${PROJECT_ROOT}/bin/tag-manager.sh --help"
    test_help "Help short flag" "${PROJECT_ROOT}/bin/tag-manager.sh -h"
    
    # Test basic functionality without git repository
    # Note: The list command doesn't check for git repository, so it will work
    # but show no tags. We'll test this differently.
    
    # Create temporary test environment
    local temp_dir
    temp_dir=$(mktemp -d /tmp/tag-manager-test-XXXXXX)
    
    if [[ ! -d "$temp_dir" ]]; then
        log_test_result "Setup" "FAIL" "Failed to create temporary directory"
        exit 1
    fi
    
    # Cleanup function
    cleanup() {
        rm -rf "$temp_dir"
    }
    trap cleanup EXIT
    
    # Create test repository
    if ! create_test_repo "$temp_dir"; then
        log_test_result "Setup" "FAIL" "Failed to create test repository"
        exit 1
    fi
    
    # Change to test directory for git-based tests
    cd "$temp_dir" || exit 1
    
    # Test list command (only implemented command)
    run_test "List all tags" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list" "v1.0.0\|v1.1.0\|v2.0.0"
    run_test "List tags with pattern" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list v1.*" "v1.0.0\|v1.1.0\|v1.2.0"
    
    # Test create command
    run_test "Create lightweight tag" 0 "${PROJECT_ROOT}/bin/tag-manager.sh create v1.3.0" "Creating tag"
    
    # Test info command
    run_test "Show tag info" 0 "${PROJECT_ROOT}/bin/tag-manager.sh info v1.0.0" "Tag Information"
    run_test "Show annotated tag info" 0 "${PROJECT_ROOT}/bin/tag-manager.sh info v1.0.1" "Tag Information"
    
    # Test cleanup command (this will fail without a remote, which is expected)
    run_test "Cleanup tags" 1 "${PROJECT_ROOT}/bin/tag-manager.sh cleanup 5" "Remote 'origin' not found"
    
    # Test error conditions
    test_error_condition "Invalid command" "${PROJECT_ROOT}/bin/tag-manager.sh invalid-command" "Unknown command"
    test_error_condition "Invalid tag name" "${PROJECT_ROOT}/bin/tag-manager.sh create invalid-tag-name" "Invalid version"
    test_error_condition "Tag already exists" "${PROJECT_ROOT}/bin/tag-manager.sh create v1.0.0" "Tag v1.0.0 already exists"
    test_error_condition "Tag doesn't exist" "${PROJECT_ROOT}/bin/tag-manager.sh info non-existent-tag" "Tag non-existent-tag does not exist"
    
    # Test edge cases
    run_test "Single tag" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list" "v1.0.0\|v1.1.0\|v2.0.0"
    
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
