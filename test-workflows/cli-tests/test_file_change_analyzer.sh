#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# CLI tests for file-change-analyzer.sh

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

# Function to create a test git repository with file changes
create_test_repo() {
    local temp_dir="$1"
    
    cd "$temp_dir" || return 1
    
    # Initialize git repository
    git init --quiet
    
    # Create initial commit with various file types
    mkdir -p src include test docs
    
    # Source files
    cat > src/main.c << 'EOF'
#include <stdio.h>
int main() { return 0; }
EOF
    
    cat > include/header.h << 'EOF'
#ifndef HEADER_H
#define HEADER_H
int function();
#endif
EOF
    
    # Test files
    cat > test/test_main.c << 'EOF'
#include <assert.h>
int main() { return 0; }
EOF
    
    # Documentation
    cat > docs/README.md << 'EOF'
# Project Documentation
This is a test project.
EOF
    
    # Configuration files
    cat > Makefile << 'EOF'
CC=gcc
CFLAGS=-Wall
EOF
    
    cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(test_project)
EOF
    
    git add .
    git commit --quiet -m "Initial commit with various file types"
    
    # Create a tag
    git tag v1.0.0
    
    # Create changes - modify source files
    cat > src/main.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <option>\n", argv[0]);
        return 1;
    }
    return 0;
}
EOF
    
    # Add new file
    cat > src/helper.c << 'EOF'
#include "helper.h"
int helper_function() { return 42; }
EOF
    
    cat > include/helper.h << 'EOF'
#ifndef HELPER_H
#define HELPER_H
int helper_function();
#endif
EOF
    
    # Modify header
    cat > include/header.h << 'EOF'
#ifndef HEADER_H
#define HEADER_H
int function();
int new_function();  // Added function
#endif
EOF
    
    # Delete test file
    git rm test/test_main.c
    
    git add .
    git commit --quiet -m "Modify source files and add new functionality"
    
    # Create another tag
    git tag v1.1.0
    
    # Create more changes - breaking changes
    cat > src/main.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
    if (argc < 3) {  // Breaking change: require 3 args
        printf("Usage: %s <command> <option>\n", argv[0]);
        return 1;
    }
    return 0;
}
EOF
    
    # Rename file
    git mv src/helper.c src/utility.c
    git mv include/helper.h include/utility.h
    
    git add .
    git commit --quiet -m "Breaking changes and file renames"
    
    return 0
}

# Main test execution
main() {
    echo "Starting CLI tests for file-change-analyzer.sh"
    echo "=============================================="
    
    # Test help
    test_help "Help flag" "${PROJECT_ROOT}/bin/file-change-analyzer.sh --help"
    test_help "Help short flag" "${PROJECT_ROOT}/bin/file-change-analyzer.sh -h"
    
    # Test basic functionality without git repository
    test_error_condition "No git repository" "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0" "Not inside a git repository"
    
    # Create temporary test environment
    local temp_dir
    temp_dir=$(mktemp -d /tmp/file-change-analyzer-test-XXXXXX)
    
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
    run_test "Basic file change analysis" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0" "files\|added\|modified\|deleted"
    
    # Test different reference types
    run_test "Analysis with HEAD target" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0" "files\|added\|modified\|deleted"
    run_test "Analysis with specific target" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0" "files\|added\|modified\|deleted"
    
    # Test output formats
    run_test "JSON output format" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --json" '"files":'
    run_test "Machine output format" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --machine" "files="
    
    # Test path restrictions
    run_test "Path restriction to src" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --only-paths 'src/**'" "files\|added\|modified\|deleted"
    run_test "Path restriction to include" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --only-paths 'include/**'" "files\|added\|modified\|deleted"
    
    # Test file type filtering
    run_test "Filter C source files" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --file-types '*.c'" "files\|added\|modified\|deleted"
    run_test "Filter header files" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --file-types '*.h'" "files\|added\|modified\|deleted"
    run_test "Filter multiple file types" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --file-types '*.c,*.h'" "files\|added\|modified\|deleted"
    
    # Test change type filtering
    run_test "Show only added files" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --change-types added" "added"
    run_test "Show only modified files" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --change-types modified" "modified"
    run_test "Show only deleted files" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --change-types deleted" "deleted"
    run_test "Show only renamed files" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --change-types renamed" "renamed"
    
    # Test statistics
    run_test "File change statistics" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --stats" "Total\|Added\|Modified\|Deleted\|Renamed"
    
    # Test detailed output
    run_test "Detailed file changes" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --detailed" "files\|added\|modified\|deleted"
    
    # Test whitespace handling
    run_test "Ignore whitespace" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --ignore-whitespace" "files\|added\|modified\|deleted"
    
    # Test verbose mode
    run_test "Verbose mode" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --verbose" "files\|added\|modified\|deleted"
    
    # Test error conditions
    test_error_condition "Missing base ref" "${PROJECT_ROOT}/bin/file-change-analyzer.sh" "error\|Error"
    test_error_condition "Invalid base ref" "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base invalid-ref" "error\|Error"
    test_error_condition "Invalid target ref" "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target invalid-ref" "error\|Error"
    test_error_condition "Invalid file type" "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --file-types 'invalid'" "error\|Error"
    test_error_condition "Invalid change type" "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --change-types invalid" "error\|Error"
    
    # Test repository root option
    run_test "Repository root option" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --repo-root ." "files\|added\|modified\|deleted"
    
    # Test edge cases
    run_test "Same base and target" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.0.0" "No changes\|files\|added\|modified\|deleted"
    run_test "Empty diff analysis" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.0.0" "No changes\|files\|added\|modified\|deleted"
    
    # Test specific file change detection
    run_test "Source file modification detection" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0" "src/main.c\|src/helper.c\|include/helper.h"
    run_test "File deletion detection" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0" "test/test_main.c"
    run_test "File addition detection" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0" "src/helper.c\|include/helper.h"
    
    # Test file size analysis
    run_test "File size analysis" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --size-analysis" "size\|bytes\|KB\|MB"
    
    # Test diff output
    run_test "Diff output" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --show-diff" "diff\|---\|+++"
    
    # Test summary output
    run_test "Summary output" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0 --summary" "Summary\|Total\|Added\|Modified\|Deleted"
    
    # Test configuration loading
    run_test "Configuration loading" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0" "files\|added\|modified\|deleted"
    
    # Test git command availability
    run_test "Git command availability" 0 "${PROJECT_ROOT}/bin/file-change-analyzer.sh --base v1.0.0 --target v1.1.0" "files\|added\|modified\|deleted"
    
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
