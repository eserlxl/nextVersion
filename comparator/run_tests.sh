#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Test runner for comparator tests

set -Euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# Configuration
TEST_TIMEOUT=${TEST_TIMEOUT:-300}  # Default 5 minutes timeout for comparator tests
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================="
echo "    NEXTVERSION COMPARATOR TEST SUITE"
echo "=========================================="
echo "Script directory: $SCRIPT_DIR"
echo "Project root: $PROJECT_ROOT"
echo "Test timeout: ${TEST_TIMEOUT}s"
echo ""

# Function to run a test file
run_test() {
    local test_file="$1"
    local test_name
    test_name=$(basename "$test_file")
    
    echo -e "${BLUE}Running $test_name...${NC}"
    
    # Check if file exists
    if [[ ! -f "$test_file" ]]; then
        echo -e "${YELLOW}SKIPPED (file not found)${NC}"
        ((SKIPPED_TESTS++))
        ((TOTAL_TESTS++))
        return
    fi
    
    # Make executable if needed
    if [[ ! -x "$test_file" ]]; then
        chmod +x "$test_file" 2>/dev/null || true
    fi
    
    # Change to the script directory before running the test
    cd "$SCRIPT_DIR" || exit 1
    
    # Run the test with timeout and capture output
    local output
    local exit_code
    output=$(timeout "$TEST_TIMEOUT" bash "$test_file" 2>&1)
    exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}PASSED${NC}"
        ((PASSED_TESTS++))
    elif [[ $exit_code -eq 124 ]]; then
        echo -e "${RED}TIMEOUT${NC}"
        ((FAILED_TESTS++))
    else
        echo -e "${RED}FAILED (exit code: $exit_code)${NC}"
        ((FAILED_TESTS++))
    fi
    
    ((TOTAL_TESTS++))
    echo ""
}

# Main execution
echo "Starting comparator test execution..."
echo ""

# Run tests in the tests subdirectory
if [[ -d "$SCRIPT_DIR/tests" ]]; then
    echo -e "${BLUE}=== Running Tests ===${NC}"
    
    # Find all test files in the tests directory
    local test_files
    mapfile -t test_files < <(find "$SCRIPT_DIR/tests" -name "*.sh" -type f | sort)
    
    if [[ ${#test_files[@]} -eq 0 ]]; then
        echo "No test files found in tests directory"
    else
        for test_file in "${test_files[@]}"; do
            run_test "$test_file"
        done
    fi
else
    echo "Tests directory not found"
fi

# Generate summary
echo "=========================================="
echo "          COMPARATOR TEST SUMMARY"
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

echo ""

# Exit with appropriate code
if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}All comparator tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some comparator tests failed!${NC}"
    exit 1
fi
