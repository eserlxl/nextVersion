#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Comprehensive test runner for core-tests directory

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
declare -i TOTAL_TESTS=0
declare -i TOTAL_PASSED=0
declare -i TOTAL_FAILED=0
FAILED_SCRIPTS=()

# Function to run a test script and capture results
run_test_script() {
    local script_name="$1"
    local script_path="$2"
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Running core test: $script_name${NC}"
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
    
    # Extract test counts from output, handling color codes and empty output
    if echo "$output" | grep -q "Tests passed:"; then
        # Remove all color codes and extract numbers - use more robust parsing
        local parsed_passed
        parsed_passed=$(echo "$output" | grep "Tests passed:" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/.*Tests passed: *\([0-9]*\).*/\1/' | grep -E '^[0-9]+$' || echo "0")
        local parsed_failed
        parsed_failed=$(echo "$output" | grep "Tests failed:" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/.*Tests failed: *\([0-9]*\).*/\1/' | grep -E '^[0-9]+$' || echo "0")
        
        # Ensure we have valid numbers
        if [[ "$parsed_passed" =~ ^[0-9]+$ ]] && [[ "$parsed_failed" =~ ^[0-9]+$ ]]; then
            passed=$parsed_passed
            failed=$parsed_failed
            total=$((passed + failed))
        else
            passed=0
            failed=0
            total=0
        fi
        
        # Debug output to see what we're parsing
        echo "DEBUG: Parsed - passed: '$passed', failed: '$failed', total: '$total'" >&2
    elif echo "$output" | grep -q "Passed:"; then
        # Handle alternative output format (e.g., test_compare_analyzers.sh)
        local parsed_passed
        parsed_passed=$(echo "$output" | grep "Passed:" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/.*Passed: *\([0-9]*\).*/\1/' | grep -E '^[0-9]+$' || echo "0")
        local parsed_failed
        parsed_failed=$(echo "$output" | grep "Failed:" | sed 's/\x1b\[[0-9;]*m//g' | sed 's/.*Failed: *\([0-9]*\).*/\1/' | grep -E '^[0-9]+$' || echo "0")
        
        # Ensure we have valid numbers
        if [[ "$parsed_passed" =~ ^[0-9]+$ ]] && [[ "$parsed_failed" =~ ^[0-9]+$ ]]; then
            passed=$parsed_passed
            failed=$parsed_failed
            total=$((passed + failed))
        else
            passed=0
            failed=0
            total=0
        fi
        
        # Debug output to see what we're parsing
        echo "DEBUG: Parsed alternative format - passed: '$passed', failed: '$failed', total: '$total'" >&2
    else
        # If no test summary found, try to count from individual test results
        passed=$(echo "$output" | grep -c "✓ PASS:" || echo "0")
        failed=$(echo "$output" | grep -c "✗ FAIL:" || echo "0")
        total=$((passed + failed))
        echo "DEBUG: Counted manually - passed: '$passed', failed: '$failed', total: '$total'" >&2
    fi
    
    # Final validation - ensure all variables are numeric
    if [[ ! "$passed" =~ ^[0-9]+$ ]]; then passed=0; fi
    if [[ ! "$failed" =~ ^[0-9]+$ ]]; then failed=0; fi
    if [[ ! "$total" =~ ^[0-9]+$ ]]; then total=0; fi
    
    # Update global counters (ensure safe arithmetic)
    TOTAL_TESTS=$((TOTAL_TESTS + total)) || TOTAL_TESTS=0
    TOTAL_PASSED=$((TOTAL_PASSED + passed)) || TOTAL_PASSED=0
    TOTAL_FAILED=$((TOTAL_FAILED + failed)) || TOTAL_FAILED=0
    
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

# Function to list available tests
list_tests() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Available Core Tests${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    local test_scripts=(
        "test_bump_version.sh:Version Bump Tests"
        "test_bump_version_loc_delta.sh:LOC Delta Version Bump Tests"
        "test_compare_analyzers.sh:Analyzer Comparison Tests"
        "test_loc_delta_system.sh:LOC Delta System Tests"
        "test_loc_delta_system_comprehensive.sh:Comprehensive LOC Delta Tests"
        "test_pure_mathematical_bonus.sh:Mathematical Bonus Tests"
        "test_realistic_repositories.sh:Realistic Repository Tests"
        "test_rollover_logic.sh:Rollover Logic Tests"
        "test_semantic_analyzer_realistic_repos.sh:Realistic Semantic Analyzer Tests"
        "test_semantic_version_analyzer.sh:Semantic Version Analyzer Tests"
        "test_semantic_version_analyzer_simple.sh:Simple Semantic Version Tests"
        "test_semantic_version_analyzer_fixes.sh:Semantic Version Fix Tests"
        "test_semantic_version_analyzer_comprehensive.sh:Comprehensive Semantic Version Analyzer Tests"
        "test_version_calculation.sh:Version Calculation Tests"
        "test_version_logic.sh:Version Logic Tests"
        "test_versioning_rules.sh:Versioning Rules Tests"
        "test_versioning_system_integration.sh:Versioning System Integration Tests"
        "test-modular-components.sh:Modular Components Tests"
        "run_loc_delta_tests.sh:LOC Delta Test Runner"
    )
    
    for test_script in "${test_scripts[@]}"; do
        local script_file="${test_script%%:*}"
        local script_name="${test_script##*:}"
        local script_path="${SCRIPT_DIR}/$script_file"
        
        if [[ -f "$script_path" ]]; then
            echo -e "  ${GREEN}✓${NC} $script_file - $script_name"
        else
            echo -e "  ${RED}✗${NC} $script_file - $script_name (not found)"
        fi
    done
    
    echo ""
    echo -e "${BLUE}Total: $(( ${#test_scripts[@]} )) test scripts${NC}"
    echo ""
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
    echo -e "${CYAN}Core Tests Summary${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    echo -e "${BLUE}Overall Results:${NC}"
    echo "  Total tests run: $TOTAL_TESTS"
    echo -e "  Tests passed: ${GREEN}$TOTAL_PASSED${NC}"
    echo -e "  Tests failed: ${RED}$TOTAL_FAILED${NC}"
    echo ""
    
    if [[ $TOTAL_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All core tests passed successfully!${NC}"
        echo ""
        echo "All core functionality is working correctly."
    else
        echo -e "${RED}❌ Some core tests failed${NC}"
        echo ""
        echo -e "Failed test scripts: ${RED}${FAILED_SCRIPTS[*]}${NC}"
        echo ""
        echo "Please review the failed tests above and fix any issues."
    fi
    
    echo ""
    echo -e "${BLUE}Test Coverage:${NC}"
    echo "  ✓ Version calculation and logic tests"
    echo "  ✓ Semantic version analysis tests"
    echo "  ✓ LOC delta system tests"
    echo "  ✓ Mathematical bonus calculation tests"
    echo "  ✓ Versioning rules and integration tests"
    echo "  ✓ Modular components architecture tests"
    echo "  ✓ Comprehensive semantic analyzer tests"
    echo ""
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --list)
                list_tests
                exit 0
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --list     List all available tests and exit"
                echo "  --help, -h Show this help message"
                echo ""
                echo "This test suite validates the core functionality of the next-version project."
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}next-version Core Test Suite${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo "This test suite validates the core functionality of the next-version project."
    echo ""
    
    # Check dependencies
    check_dependencies
    
    echo -e "${BLUE}Starting core test execution...${NC}"
    echo ""
    
    # Run all test scripts
    local test_scripts=(
        "test_bump_version.sh:Version Bump Tests"
        "test_bump_version_loc_delta.sh:LOC Delta Version Bump Tests"
        "test_compare_analyzers.sh:Analyzer Comparison Tests"
        "test_loc_delta_system.sh:LOC Delta System Tests"
        "test_loc_delta_system_comprehensive.sh:Comprehensive LOC Delta Tests"
        "test_pure_mathematical_bonus.sh:Mathematical Bonus Tests"
        "test_realistic_repositories.sh:Realistic Repository Tests"
        "test_rollover_logic.sh:Rollover Logic Tests"
        "test_semantic_analyzer_realistic_repos.sh:Realistic Semantic Analyzer Tests"
        "test_semantic_version_analyzer.sh:Semantic Version Analyzer Tests"
        "test_semantic_version_analyzer_simple.sh:Simple Semantic Version Tests"
        "test_semantic_version_analyzer_fixes.sh:Semantic Version Fix Tests"
        "test_semantic_version_analyzer_comprehensive.sh:Comprehensive Semantic Version Analyzer Tests"
        "test_version_calculation.sh:Version Calculation Tests"
        "test_version_logic.sh:Version Logic Tests"
        "test_versioning_rules.sh:Versioning Rules Tests"
        "test_versioning_system_integration.sh:Versioning System Integration Tests"
        "test-modular-components.sh:Modular Components Tests"
        "run_loc_delta_tests.sh:LOC Delta Test Runner"
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
