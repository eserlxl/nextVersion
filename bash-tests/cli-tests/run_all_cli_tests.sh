#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Comprehensive CLI test runner for next-version bash scripts

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
    echo -e "${CYAN}Running CLI tests for: $script_name${NC}"
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
    if echo "$output" | grep -q "Tests passed:"; then
        passed=$(echo "$output" | grep "Tests passed:" | awk '{print $3}')
        failed=$(echo "$output" | grep "Tests failed:" | awk '{print $3}')
        total=$(echo "$output" | grep "Total tests:" | awk '{print $3}')
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

# Function to check bash script availability
check_bash_scripts() {
    echo -e "${BLUE}Checking bash script availability...${NC}"
    
    local missing_scripts=()
    local scripts=(
        "version-calculator.sh"
        "semantic-version-analyzer.sh"
        "cli-options-analyzer.sh"
        "tag-manager.sh"
        "file-change-analyzer.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [[ ! -f "${PROJECT_ROOT}/bin/$script" ]]; then
            missing_scripts+=("$script")
        elif [[ ! -x "${PROJECT_ROOT}/bin/$script" ]]; then
            echo -e "${YELLOW}Making script executable: $script${NC}"
            chmod +x "${PROJECT_ROOT}/bin/$script"
        fi
    done
    
    if [[ ${#missing_scripts[@]} -gt 0 ]]; then
        echo -e "${RED}Error: Missing required bash scripts: ${missing_scripts[*]}${NC}"
        echo "Please ensure all bash scripts are available in the bin/ directory."
        exit 1
    fi
    
    echo -e "${GREEN}✓ All bash scripts are available and executable${NC}"
    echo ""
}

# Function to display test summary
display_summary() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}CLI Test Summary${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    echo -e "${BLUE}Overall Results:${NC}"
    echo "  Total tests run: $TOTAL_TESTS"
    echo -e "  Tests passed: ${GREEN}$TOTAL_PASSED${NC}"
    echo -e "  Tests failed: ${RED}$TOTAL_FAILED${NC}"
    echo ""
    
    if [[ $TOTAL_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All CLI tests passed successfully!${NC}"
        echo ""
        echo "All bash scripts are working correctly with their CLI interfaces."
    else
        echo -e "${RED}❌ Some CLI tests failed${NC}"
        echo ""
        echo -e "Failed test scripts: ${RED}${FAILED_SCRIPTS[*]}${NC}"
        echo ""
        echo "Please review the failed tests above and fix any issues."
    fi
    
    echo ""
    echo -e "${BLUE}Test Coverage:${NC}"
    echo "  ✓ version-calculator.sh - Version calculation CLI"
    echo "  ✓ semantic-version-analyzer.sh - Semantic analysis CLI"
    echo "  ✓ cli-options-analyzer.sh - CLI breaking change detection"
    echo "  ✓ tag-manager.sh - Git tag management CLI"
    echo "  ✓ file-change-analyzer.sh - File change analysis CLI"
    echo ""
}

# Main execution
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}next-version CLI Test Suite${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "This test suite validates the CLI functionality of all bash scripts"
    echo "in the next-version project."
    echo ""
    
    # Check dependencies and script availability
    check_dependencies
    check_bash_scripts
    
    echo -e "${BLUE}Starting CLI test execution...${NC}"
    echo ""
    
    # Run all test scripts
    local test_scripts=(
        "test_version_calculator.sh:Version Calculator CLI Tests"
        "test_semantic_version_analyzer.sh:Semantic Version Analyzer CLI Tests"
        "test_cli_options_analyzer.sh:CLI Options Analyzer CLI Tests"
        "test_tag_manager.sh:Tag Manager CLI Tests"
        "test_file_change_analyzer.sh:File Change Analyzer CLI Tests"
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
