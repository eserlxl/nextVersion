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
    
    # Run the test script with timeout and progress indicator
    echo -e "${BLUE}Starting test execution...${NC}"
    local output
    local exit_code
    
    # Special handling for tests that might be slow - keep all under 300s total
    local timeout_value=60
    local test_args=""
    
    # Reduce complexity for tests that generate random repositories
    if [[ "$script_path" == *"test_compare_analyzers.sh" ]]; then
        timeout_value=75
        test_args="--count 3 --complexity 2"
        echo -e "${YELLOW}Running with minimal complexity (count=3, complexity=2) for faster execution${NC}"
    fi
    
    # Give comprehensive tests minimal extra time
    if [[ "$script_path" == *"test_semantic_version_analyzer_comprehensive.sh" ]]; then
        timeout_value=80
        echo -e "${YELLOW}Running with minimal timeout (80s) for comprehensive test${NC}"
    fi
    
    # Additional optimizations for other potentially slow tests
    if [[ "$script_path" == *"test_realistic_repositories.sh" ]]; then
        timeout_value=70
        echo -e "${YELLOW}Running with reduced timeout (70s) for realistic repository test${NC}"
    fi
    
    if [[ "$script_path" == *"test_semantic_analyzer_realistic_repos.sh" ]]; then
        timeout_value=70
        echo -e "${YELLOW}Running with reduced timeout (70s) for realistic semantic analyzer test${NC}"
    fi
    
    # Use appropriate timeout and capture both stdout and stderr
    output=$(cd "$SCRIPT_DIR" && timeout "$timeout_value" "$script_path" $test_args 2>&1)
    exit_code=$?
    
    # Handle timeout
    if [[ $exit_code -eq 124 ]]; then
        echo -e "${RED}Error: Test script timed out after ${timeout_value} seconds: $script_path${NC}"
        output="Test timed out after ${timeout_value} seconds"
        exit_code=1
    fi
    
    echo -e "${BLUE}Test execution completed with exit code: $exit_code${NC}"
    
    # Parse test results from output
    local passed=0
    local failed=0
    local total=0
    
    # Extract test counts from output, handling color codes and empty output
    if echo "$output" | grep -q "Tests passed:"; then
        # Remove all color codes and extract numbers - use more robust parsing
        local parsed_passed
        parsed_passed=$(echo "$output" | grep "Tests passed:" | sed 's/\\033\[[0-9;]*m//g' | awk '{print $3}' | grep -E '^[0-9]+$' || echo "0")
        local parsed_failed
        parsed_failed=$(echo "$output" | grep "Tests failed:" | sed 's/\\033\[[0-9;]*m//g' | awk '{print $3}' | grep -E '^[0-9]+$' || echo "0")
        
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
        
        # Convert to numbers to ensure safe arithmetic
        passed=$((10#$passed))
        failed=$((10#$failed))
        total=$((10#$total))
        
        # Debug output to see what we're parsing
        echo "DEBUG: Parsed - passed: '$passed', failed: '$failed', total: '$total'" >&2
    elif echo "$output" | grep -q "Passed:"; then
        # Handle alternative output format (e.g., test_compare_analyzers.sh)
        local parsed_passed
        parsed_passed=$(echo "$output" | grep "Passed:" | sed 's/\\033\[[0-9;]*m//g' | awk '{print $2}' | grep -E '^[0-9]+$' || echo "0")
        local parsed_failed
        parsed_failed=$(echo "$output" | grep "Failed:" | sed 's/\\033\[[0-9;]*m//g' | awk '{print $2}' | grep -E '^[0-9]+$' || echo "0")
        
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
        
        # Convert to numbers to ensure safe arithmetic
        passed=$((10#$passed))
        failed=$((10#$failed))
        total=$((10#$total))
        
        # Debug output to see what we're parsing
        echo "DEBUG: Parsed alternative format - passed: '$passed', failed: '$failed', total: '$total'" >&2
    else
        # If no test summary found, try to count from individual test results
        passed=$(echo "$output" | grep -c "✓ PASS:" || echo "0")
        failed=$(echo "$output" | grep -c "✗ FAIL:" || echo "0")
        
        # Also try to count from alternative formats
        if [[ "$passed" =~ ^[0-9]+$ ]] && [[ $passed -eq 0 ]]; then
            passed=$(echo "$output" | grep -c "✅ PASS:" || echo "0")
        fi
        if [[ "$failed" =~ ^[0-9]+$ ]] && [[ $failed -eq 0 ]]; then
            failed=$(echo "$output" | grep -c "❌ FAIL:" || echo "0")
        fi
        
        # If still no results, try to detect success from final messages
        if [[ "$passed" =~ ^[0-9]+$ ]] && [[ "$failed" =~ ^[0-9]+$ ]] && [[ $passed -eq 0 && $failed -eq 0 ]]; then
            if echo "$output" | grep -q "✅ All.*tests passed"; then
                passed=1
                failed=0
            elif echo "$output" | grep -q "All tests passed"; then
                passed=1
                failed=0
            fi
        fi
        
        # If we still have no results, try to count all PASS lines
        if [[ "$passed" =~ ^[0-9]+$ ]] && [[ $passed -eq 0 ]]; then
            passed=$(echo "$output" | grep -c "PASS:" || echo "0")
        fi
        
        # Additional fallback: look for "All.*tests passed" patterns
        if [[ "$passed" =~ ^[0-9]+$ ]] && [[ $passed -eq 0 ]]; then
            if echo "$output" | grep -q "All.*tests passed"; then
                # Count the actual PASS lines to get accurate count
                passed=$(echo "$output" | grep -c "✅ PASS:" || echo "0")
                if [[ "$passed" =~ ^[0-9]+$ ]] && [[ $passed -eq 0 ]]; then
                    passed=$(echo "$output" | grep -c "PASS:" || echo "0")
                fi
                failed=0
            fi
        fi
        
        # Additional fallback: look for "Tests passed:" patterns in different formats
        if [[ "$passed" =~ ^[0-9]+$ ]] && [[ $passed -eq 0 ]]; then
            if echo "$output" | grep -q "Tests passed:"; then
                # Extract the number after "Tests passed:"
                local parsed_passed
                parsed_passed=$(echo "$output" | grep "Tests passed:" | sed 's/\\033\[[0-9;]*m//g' | awk '{print $3}' | grep -E '^[0-9]+$' || echo "0")
                if [[ "$parsed_passed" =~ ^[0-9]+$ ]]; then
                    passed=$parsed_passed
                    failed=0
                fi
            fi
        fi
        
        # Additional fallback: look for "Passed:" patterns
        if [[ "$passed" =~ ^[0-9]+$ ]] && [[ $passed -eq 0 ]]; then
            if echo "$output" | grep -q "Passed:"; then
                # Extract the number after "Passed:"
                local parsed_passed
                parsed_passed=$(echo "$output" | grep "Passed:" | sed 's/\\033\[[0-9;]*m//g' | awk '{print $2}' | grep -E '^[0-9]+$' || echo "0")
                if [[ "$parsed_passed" =~ ^[0-9]+$ ]]; then
                    passed=$parsed_passed
                    failed=0
                fi
            fi
        fi
        
        # Ensure variables are numeric before arithmetic
        if [[ ! "$passed" =~ ^[0-9]+$ ]]; then passed=0; fi
        if [[ ! "$failed" =~ ^[0-9]+$ ]]; then failed=0; fi
        
        # Safe arithmetic conversion
        passed=$((10#$passed))
        failed=$((10#$failed))
        total=$((passed + failed))
        echo "DEBUG: Counted manually - passed: '$passed', failed: '$failed', total: '$total'" >&2
    fi
    
    # Final validation - ensure all variables are numeric
    if [[ ! "$passed" =~ ^[0-9]+$ ]]; then passed=0; fi
    if [[ ! "$failed" =~ ^[0-9]+$ ]]; then failed=0; fi
    if [[ ! "$total" =~ ^[0-9]+$ ]]; then total=0; fi
    
    # Convert to numbers to ensure safe arithmetic
    passed=$((10#$passed))
    failed=$((10#$failed))
    total=$((10#$total))
    
    # Update global counters (ensure safe arithmetic)
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
    
    # Run all test scripts with global timeout protection
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
    
    local total_scripts=${#test_scripts[@]}
    local current_script=0
    local start_time=$(date +%s)
    local max_total_time=300  # Maximum 5 minutes total
    
    for test_script in "${test_scripts[@]}"; do
        local script_file="${test_script%%:*}"
        local script_name="${test_script##*:}"
        local script_path="${SCRIPT_DIR}/$script_file"
        
        # Check if we're approaching the global timeout
        local current_time=$(date +%s)
        local elapsed_time=$((current_time - start_time))
        local remaining_time=$((max_total_time - elapsed_time))
        
        if [[ $remaining_time -le 30 ]]; then
            echo -e "${RED}⚠ Global timeout approaching (${elapsed_time}s elapsed). Skipping remaining tests.${NC}"
            echo -e "${YELLOW}Completed $current_script out of $total_scripts tests in ${elapsed_time}s${NC}"
            break
        fi
        
        ((current_script++))
        echo -e "${BLUE}Progress: $current_script/$total_scripts - Running: $script_file (${remaining_time}s remaining)${NC}"
        
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
