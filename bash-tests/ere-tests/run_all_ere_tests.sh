#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Comprehensive test runner for ere-tests directory

set -Euo pipefail

# Source test helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "${SCRIPT_DIR}/../test_helper.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
FAILED_SCRIPTS=()

# Function to run a test script and capture results
run_test_script() {
    local script_name="$1"
    local script_path="$2"
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Running ERE test: $script_name${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    # Check if script exists and is executable
    if [[ ! -f "$script_path" ]]; then
        echo -e "${RED}Error: Test script not found: $script_path${NC}"
        return 1
    fi
    
    if [[ ! -x "$script_path" ]]; then
        echo -e "${YELLOW}Making test script executable: $script_path${NC}"
        chmod +x "$script_path"
    fi
    
    # Run the test script
    local output
    local exit_code
    output=$(cd "$SCRIPT_DIR" && "$script_path" 2>&1)
    exit_code=$?
    
    # Parse test results from output
    local passed=0
    local failed=0
    local total=0
    
    # Extract test counts from output using grep with regex
    if echo "$output" | grep -q "Tests passed:"; then
        # Extract just the numbers using grep with regex
        passed=$(echo "$output" | grep -o "Tests passed: [0-9]*" | grep -o "[0-9]*")
        failed=$(echo "$output" | grep -o "Tests failed: [0-9]*" | grep -o "[0-9]*")
        total=$(echo "$output" | grep -o "Total tests: [0-9]*" | grep -o "[0-9]*")
        
        # Debug: show what we extracted (only if verbose)
        if [[ "${VERBOSE:-false}" == "true" ]]; then
            echo "DEBUG: Extracted passed=$passed, failed=$failed, total=$total" >&2
        fi
    fi
    
    # Update global counters
    TOTAL_TESTS=$((TOTAL_TESTS + total))
    TOTAL_PASSED=$((TOTAL_PASSED + passed))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
    
    # Display results
    echo "$output"
    echo ""
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✓ $script_name: All tests passed ($passed/$total)${NC}"
    else
        echo -e "${RED}✗ $script_name: Some tests failed ($failed/$total)${NC}"
        FAILED_SCRIPTS+=("$script_name")
    fi
    
    echo ""
    return $exit_code
}

# Function to check script dependencies
check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    
    # Check if required commands are available
    local missing_deps=()
    
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    if ! command -v bash >/dev/null 2>&1; then
        missing_deps+=("bash")
    fi
    
    if ! command -v awk >/dev/null 2>&1; then
        missing_deps+=("awk")
    fi
    
    if ! command -v sed >/dev/null 2>&1; then
        missing_deps+=("sed")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required dependencies: ${missing_deps[*]}${NC}"
        echo "Please install the missing dependencies and try again."
        exit 1
    fi
    
    echo -e "${GREEN}✓ All dependencies are available${NC}"
    echo ""
}

# Function to display test summary
display_summary() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}ERE Tests Summary${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    echo -e "${BLUE}Overall Results:${NC}"
    echo "  Total tests run: $TOTAL_TESTS"
    echo -e "  Tests passed: ${GREEN}$TOTAL_PASSED${NC}"
    echo -e "  Tests failed: ${RED}$TOTAL_FAILED${NC}"
    echo ""
    
    if [[ $TOTAL_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All ERE tests passed successfully!${NC}"
        echo ""
        echo "All ERE functionality is working correctly."
    else
        echo -e "${RED}❌ Some ERE tests failed${NC}"
        echo ""
        echo -e "Failed test scripts: ${RED}${FAILED_SCRIPTS[*]}${NC}"
        echo ""
        echo "Please review the failed tests above and fix any issues."
    fi
    
    echo ""
    echo -e "${BLUE}Test Coverage:${NC}"
    echo "  ✓ ERE pattern matching tests"
    echo "  ✓ ERE fix and validation tests"
    echo "  ✓ ERE debug and troubleshooting tests"
    echo "  ✓ ERE functionality validation tests"
    echo ""
}

# Main execution
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}next-version ERE Test Suite${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "This test suite validates ERE (Extended Regular Expression) functionality in the next-version project."
    echo ""
    
    # Check dependencies
    check_dependencies
    
    echo -e "${BLUE}Starting ERE test execution...${NC}"
    echo ""
    
    # Run all test scripts
    local test_scripts=(
        "test_run_test_framework.sh:Test Framework Tests"
        "test_ere_fix.sh:ERE Fix Tests"
    )
    
    for test_script in "${test_scripts[@]}"; do
        local script_file="${test_script%%:*}"
        local script_name="${test_script##*:}"
        local script_path="${SCRIPT_DIR}/$script_file"
        
        if [[ -f "$script_path" ]]; then
            run_test_script "$script_name" "$script_path"
        else
            echo -e "${YELLOW}⚠ Skipping: $script_file (not found)${NC}"
            echo ""
        fi
    done
    
    # Display final summary
    display_summary
    
    # Exit with appropriate code
    if [[ $TOTAL_FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
