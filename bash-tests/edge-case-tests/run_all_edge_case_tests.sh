#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Comprehensive test runner for edge-case-tests directory

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
    echo -e "${CYAN}Running edge case test: $script_name${NC}"
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
    
    # Extract test counts from output - look for summary lines
    if echo "$output" | grep -q "Tests passed:"; then
        # Extract the numeric values from summary lines
        passed=$(echo "$output" | grep "Tests passed:" | sed 's/.*Tests passed: *\([0-9]*\).*/\1/' | head -1)
        failed=$(echo "$output" | grep "Tests failed:" | sed 's/.*Tests failed: *\([0-9]*\).*/\1/' | head -1)
        
        # Ensure we got valid numbers
        if [[ -z "$passed" || ! "$passed" =~ ^[0-9]+$ ]]; then
            passed=0
        fi
        if [[ -z "$failed" || ! "$failed" =~ ^[0-9]+$ ]]; then
            failed=0
        fi
        
        # Calculate total
        total=$((passed + failed))
    fi
    
    # Debug: Print extracted values
    echo "Debug: Extracted values - passed: '$passed', failed: '$failed', total: '$total'"
    
    # Final validation - ensure all variables are numeric
    if ! [[ "$passed" =~ ^[0-9]+$ ]]; then
        echo "Warning: Invalid passed value '$passed', setting to 0"
        passed=0
    fi
    if ! [[ "$failed" =~ ^[0-9]+$ ]]; then
        echo "Warning: Invalid failed value '$failed', setting to 0"
        failed=0
    fi
    if ! [[ "$total" =~ ^[0-9]+$ ]]; then
        echo "Warning: Invalid total value '$total', setting to 0"
        total=0
    fi
    
    # If total is still 0, calculate it from passed + failed
    if [[ $total -eq 0 ]]; then
        total=$((passed + failed))
        echo "Debug: Calculated total as $total from passed ($passed) + failed ($failed)"
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
    echo -e "${CYAN}Edge Case Tests Summary${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    echo -e "${BLUE}Overall Results:${NC}"
    echo "  Total tests run: $TOTAL_TESTS"
    echo -e "  Tests passed: ${GREEN}$TOTAL_PASSED${NC}"
    echo -e "  Tests failed: ${RED}$TOTAL_FAILED${NC}"
    echo ""
    
    if [[ $TOTAL_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All edge case tests passed successfully!${NC}"
        echo ""
        echo "All edge case handling is working correctly."
    else
        echo -e "${RED}❌ Some edge case tests failed${NC}"
        echo ""
        echo -e "Failed test scripts: ${RED}${FAILED_SCRIPTS[*]}${NC}"
        echo ""
        echo "Please review the failed tests above and fix any issues."
    fi
    
    echo ""
    echo -e "${BLUE}Test Coverage:${NC}"
    echo "  ✓ Breaking case detection tests"
    echo "  ✓ CLI detection and fixes tests"
    echo "  ✓ Environment normalization tests"
    echo "  ✓ Extract and header removal tests"
    echo "  ✓ Minimal repository test mode tests"
    echo "  ✓ NUL safety and whitespace handling tests"
    echo "  ✓ Rename handling and edge case scenarios"
    echo ""
}

# Main execution
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}next-version Edge Case Test Suite${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "This test suite validates edge case handling in the next-version project."
    echo ""
    
    # Check dependencies
    check_dependencies
    
    echo -e "${BLUE}Starting edge case test execution...${NC}"
    echo ""
    
    # Run all test scripts
    local test_scripts=(
        "test_breaking_case_detection.sh:Breaking Case Detection Tests"
        "test_cli_detection_fix.sh:CLI Detection Fix Tests"
        "test_env_normalization.sh:Environment Normalization Tests"
        "test_extract.sh:Extract Tests"
        "test_fixes.sh:Fixes Tests"
        "test_header_removal.sh:Header Removal Tests"
        "test_minimal_repo_test_mode.sh:Minimal Repository Test Mode Tests"
        "test_nul_safety.sh:NUL Safety Tests"
        "test_rename_handling.sh:Rename Handling Tests"
        "test_whitespace_ignore.sh:Whitespace Ignore Tests"
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
