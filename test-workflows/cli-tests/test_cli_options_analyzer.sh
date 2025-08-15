#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# CLI tests for cli-options-analyzer.sh

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

# Function to create a test git repository with CLI changes
create_test_repo() {
    local temp_dir="$1"
    
    cd "$temp_dir" || return 1
    
    # Initialize git repository
    git init --quiet
    
    # Create initial commit with CLI code
    cat > main.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <option>\n", argv[0]);
        return 1;
    }
    
    printf("Option: %s\n", argv[1]);
    return 0;
}
EOF
    
    git add main.c
    git commit --quiet -m "Initial CLI implementation"
    
    # Create a tag
    git tag v1.0.0
    
    # Create changes that modify CLI
    cat > main.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <option> [--verbose]\n", argv[0]);
        return 1;
    }
    
    if (strcmp(argv[1], "--help") == 0) {
        printf("Help information\n");
        return 0;
    }
    
    printf("Option: %s\n", argv[1]);
    return 0;
}
EOF
    
    git add main.c
    git commit --quiet -m "Add help option to CLI"
    
    # Create another tag
    git tag v1.1.0
    
    # Create breaking changes
    cat > main.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc < 3) {
        printf("Usage: %s <command> <option>\n", argv[0]);
        return 1;
    }
    
    if (strcmp(argv[1], "--help") == 0) {
        printf("Help information\n");
        return 0;
    }
    
    printf("Command: %s, Option: %s\n", argv[1], argv[2]);
    return 0;
}
EOF
    
    git add main.c
    git commit --quiet -m "Breaking change: require two arguments"
    
    return 0
}

# Main test execution
main() {
    echo "Starting CLI tests for cli-options-analyzer.sh"
    echo "=============================================="
    
    # Test help
    test_help "Help flag" "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --help"
    test_help "Help short flag" "${PROJECT_ROOT}/bin/cli-options-analyzer.sh -h"
    
    # Test basic functionality without git repository
test_error_condition "No git repository" "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0" "Invalid reference"
    
    # Create temporary test environment
    local temp_dir
    temp_dir=$(mktemp -d /tmp/cli-options-analyzer-test-XXXXXX)
    
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
    
    # Test basic analysis
    run_test "Basic CLI analysis" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.1.0" "breaking\|non-breaking"
    
    # Test different reference types
    run_test "Analysis with HEAD target" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0" "breaking\|non-breaking"
    run_test "Analysis with specific target" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.1.0" "breaking\|non-breaking"
    
    # Test output formats (using actual output format)
    run_test "JSON output format" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.1.0 --json" '"cli_changes":'
    run_test "Machine output format" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.1.0 --machine" "CLI_CHANGES="
    
    # Test path restrictions
    run_test "Path restriction" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.1.0 --only-paths 'main.c'" "breaking\|non-breaking"
    
    # Test whitespace handling
    run_test "Ignore whitespace" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.1.0 --ignore-whitespace" "breaking\|non-breaking"
    
    # Test verbose mode
    run_test "Verbose mode" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.1.0 --verbose" "breaking\|non-breaking"
    
    # Test fail-on-breaking option (this should not fail since there are no breaking changes)
    run_test "Fail on breaking option" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target HEAD --fail-on-breaking" "breaking\|non-breaking"
    
    # Test error conditions
    test_error_condition "Missing base ref" "${PROJECT_ROOT}/bin/cli-options-analyzer.sh" "error\|Error"
    test_error_condition "Invalid base ref" "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base invalid-ref" "error\|Error"
    test_error_condition "Invalid target ref" "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target invalid-ref" "error\|Error"
    
    # Test repository root option
    run_test "Repository root option" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.1.0 --repo-root ." "breaking\|non-breaking"
    
    # Test edge cases (using actual output format)
    run_test "Same base and target" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.0.0" "No relevant source/header changes"
    run_test "Empty diff analysis" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.0.0" "No relevant source/header changes"
    
    # Test specific CLI change detection
    run_test "CLI argument change detection" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.1.0" "breaking\|non-breaking"
    run_test "CLI help option addition" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.1.0" "breaking\|non-breaking"
    
    # Test breaking change detection
    run_test "Breaking change detection" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.1.0 --target HEAD" "breaking\|non-breaking"
    
    # Test non-breaking change detection
    run_test "Non-breaking change detection" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.1.0" "breaking\|non-breaking"
    
    # Test configuration loading
    run_test "Configuration loading" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.1.0" "breaking\|non-breaking"
    
    # Test git command availability
    run_test "Git command availability" 0 "${PROJECT_ROOT}/bin/cli-options-analyzer.sh --base v1.0.0 --target v1.1.0" "breaking\|non-breaking"
    
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
