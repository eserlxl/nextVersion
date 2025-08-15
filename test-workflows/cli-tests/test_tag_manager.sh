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
YELLOW='\033[1;33m'
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
    
    # Create lightweight tags
    git tag lightweight-tag
    
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
    test_error_condition "No git repository" "${PROJECT_ROOT}/bin/tag-manager.sh list" "Not inside a git repository"
    
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
    
    # Test list command
    run_test "List all tags" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list" "v1.0.0\|v1.1.0\|v2.0.0"
    run_test "List tags with pattern" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list v1.*" "v1.0.0\|v1.1.0\|v1.2.0"
    run_test "List tags with regex" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list --regex 'v[12]\.0\.0'" "v1.0.0\|v2.0.0"
    
    # Test show command
    run_test "Show tag info" 0 "${PROJECT_ROOT}/bin/tag-manager.sh show v1.0.0" "tag\|commit\|tagger"
    run_test "Show annotated tag" 0 "${PROJECT_ROOT}/bin/tag-manager.sh show v1.0.1" "tag\|commit\|tagger"
    run_test "Show lightweight tag" 0 "${PROJECT_ROOT}/bin/tag-manager.sh show lightweight-tag" "commit\|Author"
    
    # Test create command
    run_test "Create lightweight tag" 0 "${PROJECT_ROOT}/bin/tag-manager.sh create v1.3.0" "Created tag v1.3.0"
    run_test "Create annotated tag" 0 "${PROJECT_ROOT}/bin/tag-manager.sh create v1.3.1 -m 'Test annotated tag'" "Created tag v1.3.1"
    
    # Test delete command
    run_test "Delete tag" 0 "${PROJECT_ROOT}/bin/tag-manager.sh delete v1.3.0" "Deleted tag v1.3.0"
    run_test "Delete remote tag" 0 "${PROJECT_ROOT}/bin/tag-manager.sh delete v1.3.1 --remote" "Deleted remote tag v1.3.1"
    
    # Test push command
    run_test "Push tag" 0 "${PROJECT_ROOT}/bin/tag-manager.sh push v1.3.1" "Pushed tag v1.3.1"
    run_test "Push all tags" 0 "${PROJECT_ROOT}/bin/tag-manager.sh push --all" "Pushed all tags"
    
    # Test pull command
    run_test "Pull tags" 0 "${PROJECT_ROOT}/bin/tag-manager.sh pull" "Pulled tags"
    
    # Test output formats
    run_test "JSON output format" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list --json" '"tags":'
    run_test "Machine output format" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list --machine" "tag="
    
    # Test filtering options
    run_test "Filter by date" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list --since 2020-01-01" "v1.0.0\|v1.1.0\|v2.0.0"
    run_test "Filter by author" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list --author test" "v1.0.0\|v1.1.0\|v2.0.0"
    
    # Test sorting options
    run_test "Sort by date" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list --sort date" "v1.0.0\|v1.1.0\|v2.0.0"
    run_test "Sort by version" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list --sort version" "v1.0.0\|v1.1.0\|v2.0.0"
    
    # Test error conditions
    test_error_condition "Invalid command" "${PROJECT_ROOT}/bin/tag-manager.sh invalid-command" "Unknown command"
    test_error_condition "Invalid tag name" "${PROJECT_ROOT}/bin/tag-manager.sh create invalid-tag-name" "Invalid tag name"
    test_error_condition "Tag already exists" "${PROJECT_ROOT}/bin/tag-manager.sh create v1.0.0" "Tag already exists"
    test_error_condition "Tag doesn't exist" "${PROJECT_ROOT}/bin/tag-manager.sh show non-existent-tag" "Tag not found"
    
    # Test edge cases
    run_test "Empty repository" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list" "No tags found"
    run_test "Single tag" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list" "v1.0.0\|v1.1.0\|v2.0.0"
    
    # Test configuration options
    run_test "Custom remote" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list --remote origin" "v1.0.0\|v1.1.0\|v2.0.0"
    run_test "Custom branch" 0 "${PROJECT_ROOT}/bin/tag-manager.sh list --branch main" "v1.0.0\|v1.1.0\|v2.0.0"
    
    # Test batch operations
    run_test "Batch delete" 0 "${PROJECT_ROOT}/bin/tag-manager.sh delete --batch v1.3.0,v1.3.1" "Deleted tags"
    run_test "Batch create" 0 "${PROJECT_ROOT}/bin/tag-manager.sh create --batch v1.4.0,v1.4.1" "Created tags"
    
    # Test validation
    run_test "Validate tag format" 0 "${PROJECT_ROOT}/bin/tag-manager.sh validate v1.0.0" "Valid tag"
    run_test "Validate invalid format" 1 "${PROJECT_ROOT}/bin/tag-manager.sh validate invalid-format" "Invalid tag format"
    
    # Test statistics
    run_test "Tag statistics" 0 "${PROJECT_ROOT}/bin/tag-manager.sh stats" "Total tags\|Annotated\|Lightweight"
    
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
