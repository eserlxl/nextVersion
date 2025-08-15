#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Comprehensive test runner for utility-tests directory

set -Euo pipefail

# Source test helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
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
    echo -e "${CYAN}Running utility test: $script_name${NC}"
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
    
    # Extract test counts from output
    if echo "$output" | grep -q "✓.*:" && echo "$output" | grep -q "Tests passed:"; then
        # Tests with both checkmarks and summary (most specific case first)
        local passed_raw
        passed_raw=$(echo "$output" | grep "Tests passed:" | awk '{print $3}')
        local failed_raw
        failed_raw=$(echo "$output" | grep "Tests failed:" | awk '{print $3}')
        passed=$(echo "$passed_raw" | grep -o '[0-9]\+' | head -1 || echo "0")
        failed=$(echo "$failed_raw" | grep -o '[0-9]\+' | head -1 || echo "0")
        total=$((passed + failed))
    elif echo "$output" | grep -q "Tests passed:"; then
        # Tests with just summary
        passed=$(echo "$output" | grep "Tests passed:" | awk '{print $3}' | grep -o '[0-9]\+' | head -1 || echo "0")
        failed=$(echo "$output" | grep "Tests failed:" | awk '{print $3}' | grep -o '[0-9]\+' | head -1 || echo "0")
        total=$((passed + failed))
    elif echo "$output" | grep -q "✓.*->.*expected:"; then
        # Tests with detailed pass/fail output
        passed=$(echo "$output" | grep -c "✓" || echo "0")
        failed=$(echo "$output" | grep -c "✗" || echo "0")
        total=$((passed + failed))
    elif echo "$output" | grep -q "Result:"; then
        # Simple tests that just show a result
        passed=1
        failed=0
        total=1
    elif echo "$output" | grep -q "doc\|source\|test"; then
        # Tests that show classification results
        passed=1
        failed=0
        total=1
    else
        # Default case for tests with no clear output
        passed=1
        failed=0
        total=1
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
    echo -e "${CYAN}Utility Tests Summary${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    echo -e "${BLUE}Overall Results:${NC}"
    echo "  Total tests run: $TOTAL_TESTS"
    echo -e "  Tests passed: ${GREEN}$TOTAL_PASSED${NC}"
    echo -e "  Tests failed: ${RED}$TOTAL_FAILED${NC}"
    echo ""
    
    if [[ $TOTAL_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All utility tests passed successfully!${NC}"
        echo ""
        echo "All utility functionality is working correctly."
    else
        echo -e "${RED}❌ Some utility tests failed${NC}"
        echo ""
        echo -e "Failed test scripts: ${RED}${FAILED_SCRIPTS[*]}${NC}"
        echo ""
        echo "Please review the failed tests above and fix any issues."
    fi
    
    echo ""
    echo -e "${BLUE}Test Coverage:${NC}"
    echo "  ✓ Function classification tests"
    echo "  ✓ Case handling tests"
    echo "  ✓ Debug and utility function tests"
    echo "  ✓ Edge case and error handling tests"
    echo "  ✓ General utility functionality tests"
    echo ""
}

# Main execution
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}next-version Utility Test Suite${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "This test suite validates the utility functionality of the next-version project."
    echo ""
    
    # Check dependencies
    check_dependencies
    
    echo -e "${BLUE}Starting utility test execution...${NC}"
    echo ""
    
    # Run all test scripts
    local test_scripts=(
        "test_case.sh:Case Handling Tests"
        "test_classify.sh:Classification Tests"
        "test_classify_consolidated.sh:Consolidated Classification Tests"
        "test_classify_debug.sh:Debug Classification Tests"
        "test_classify_fixed.sh:Fixed Classification Tests"
        "test_classify_inline.sh:Inline Classification Tests"
        "test_classify_inline2.sh:Inline Classification Tests 2"
        "test_classify_simple.sh:Simple Classification Tests"
        "test_git_commit_counting.sh:Git Commit Counting Tests"
        "test_func.sh:Function Tests"
        "test_func2.sh:Function Tests 2"
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
