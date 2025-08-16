#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Comprehensive test runner for NEXT-VERSION
# Runs both bash-tests and cpp-tests
# Usage: ./run_tests.sh

# Don't use set -e to allow both test suites to run even if one fails

# Colors for output
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to count C++ tests by parsing CMakeLists.txt
count_cpp_tests() {
    local cmake_file="CMakeLists.txt"
    if [ ! -f "$cmake_file" ]; then
        echo "Error: CMakeLists.txt not found at $cmake_file" >&2
        return 1
    fi
    
    # Count add_test_exe lines in CMakeLists.txt
    local count
    count=$(grep -c "^[[:space:]]*add_test_exe(" "$cmake_file" 2>/dev/null || echo "0")
    echo "$count"
}

# Function to count bash tests by scanning bash-tests directory
count_bash_tests() {
    local test_dir="bash-tests"
    if [ ! -d "$test_dir" ]; then
        echo "0"
        return
    fi
    
    # Count all .sh files in bash-tests and subdirectories
    local count
    count=$(find "$test_dir" -name "*.sh" -type f | wc -l)
    echo "$count"
}

print_ascii_art() {
  # Minimal color handling; uses tput if available
  local nc=""
  if [[ "${NO_COLOR:-}" != "true" ]] && command -v tput >/dev/null 2>&1; then
    nc="$(tput sgr0)"
  fi

  cat <<'ASCII'

  ███╗   ██╗███████╗██╗  ██╗████████╗    ██╗   ██╗███████╗██████╗ ███████╗██╗ ██████╗ ███╗   ██╗
  ████╗  ██║██╔════╝╚██╗██╔╝╚══██╔══╝    ██║   ██║██╔════╝██╔══██╗██╔════╝██║██╔═══██╗████╗  ██║
  ██╔██╗ ██║█████╗   ╚███╔╝    ██║       ██║   ██║█████╗  ██████╔╝███████╗██║██║   ██║██╔██╗ ██║
  ██║╚██╗██║██╔══╝   ██╔██╗    ██║       ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██║██║   ██║██║╚██╗██║
  ██║ ╚████║███████╗██╔╝ ██╗   ██║        ╚████╔╝ ███████╗██║  ██║███████║██║╚██████╔╝██║ ╚████║
  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝   ╚═╝         ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝
ASCII
  printf '%s' "$nc"
}

# Function to print colored output
# Note: These functions are defined for potential future use but not currently called
# print_status() {
#     echo -e "${BLUE}[INFO]${NC} $1"
# }

# print_success() {
#     echo -e "${GREEN}[SUCCESS]${NC} $1"
# }

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to cleanup test artifacts
cleanup_test_artifacts() {
    echo -e "${BLUE}[INFO]${NC} Cleaning up test artifacts..."
    
    # Use the dedicated cleanup script
    "$PROJECT_ROOT/cleanup_tests.sh" >/dev/null 2>&1 || true
    
    echo -e "${GREEN}[SUCCESS]${NC} Test artifacts cleaned up"
}

print_header() {
    echo -e "${BOLD}${CYAN}============================================================${NC}"
    echo -e "${BOLD}${CYAN}       NEXT-VERSION — Comprehensive Test Suite Results${NC}"
    echo -e "${BOLD}${CYAN}============================================================${NC}"
    echo ""
}

print_phase_header() {
    echo -e "${BOLD}${MAGENTA}PHASE $1: $2${NC}"
    echo -e "${MAGENTA}------------------------------------------------------------${NC}"
}

# Function to print test results (defined for potential future use)
# print_test_result() {
#     local test_name="$1"
#     local status="$2"
#     local padding=""
#     
#     # Calculate padding to align test names
#     local name_length=${#test_name}
#     local max_length=40
#     local padding_length=$((max_length - name_length))
#     
#     for ((i=0; i<padding_length; i++)); do
#         padding+=" "
#     done
#     
#     if [ "${status^^}" = "PASSED" ]; then
#         echo -e "  ${GREEN}✔${NC} ${CYAN}$test_name${NC}${padding} ${GREEN}PASSED${NC}"
#     else
#         echo -e "  ${RED}✖${NC} ${CYAN}$test_name${NC}${padding} ${RED}FAILED${NC}"
#     fi
# }

# Function to print section headers (defined for potential future use)
# print_section_header() {
#     echo -e "${BOLD}${YELLOW}$1:${NC}"
# }

# Function to print test summary (defined for potential future use)
# shellcheck disable=SC2329
print_summary() {
    local total="$1"
    local passed="$2"
    local failed="$3"
    local skipped="$4"
    local success_rate="$5"
    local status="$6"
    
    echo -e "${BOLD}${BLUE}--- $7 Summary ---${NC}"
    echo -e "${CYAN}Total tests :${NC} $total"
    
    # Only show passed count if not all tests failed
    if [ "$failed" -lt "$total" ]; then
        echo -e "${CYAN}Passed      :${NC} ${GREEN}$passed${NC}"
    fi
    
    # Only show failed count if not all tests passed
    if [ "$passed" -lt "$total" ]; then
        echo -e "${CYAN}Failed      :${NC} ${RED}$failed${NC}"
    fi
    
    # Only show skipped if there are any
    if [ "$skipped" -gt 0 ]; then
        echo -e "${CYAN}Skipped     :${NC} ${YELLOW}$skipped${NC}"
    fi
    
    echo -e "${CYAN}Success rate:${NC} ${BOLD}$success_rate%${NC}"
    echo -e "${CYAN}Status      :${NC} $status"
}

print_info_line() {
    local label="$1"
    local value="$2"
    echo -e "${CYAN}$label${NC} : ${YELLOW}$value${NC}"
}



print_separator() {
    echo -e "${MAGENTA}------------------------------------------------------------${NC}"
}

print_final_header() {
    echo -e "${BOLD}${BLUE}FINAL SUMMARY${NC}"
    echo -e "${BLUE}------------------------------------------------------------${NC}"
}

print_final_footer() {
    echo -e "${BOLD}${CYAN}============================================================${NC}"
}

# Initialize variables
BASH_START_TIME=$(date)
PROJECT_ROOT=$(pwd)
BUILD_DIR="$PROJECT_ROOT/build-test"

# --- NEW: Test suite selection menu ---
AVAILABLE_SUITES=("ALL" "Bash" "C++")
SUITE_DESCRIPTIONS=(
    "Run all test suites (Bash + C++)"
    "Run only bash tests"
    "Run only C++ tests"
)

print_suite_menu() {
    echo -e "${BOLD}${CYAN}Select a test suite to run:${NC}"
    for i in "${!AVAILABLE_SUITES[@]}"; do
        echo -e "  ${YELLOW}$i)${NC} ${BOLD}${AVAILABLE_SUITES[$i]}${NC} - ${SUITE_DESCRIPTIONS[$i]}"
    done
    echo -e ""
    echo -e "Press [Enter] or wait 5 seconds to select ${BOLD}${AVAILABLE_SUITES[0]}${NC} (default)"
}

# Print ASCII art at the start
print_ascii_art
echo ""

# Check for TEST_SUITE environment variable override
if [[ -n "$TEST_SUITE" ]]; then
    # Use override value - check if it's a valid suite name
    if [[ "$TEST_SUITE" == "ALL" || "$TEST_SUITE" == "Bash" || "$TEST_SUITE" == "C++" ]]; then
        SELECTED_SUITE="$TEST_SUITE"
        echo -e "${BOLD}${CYAN}Using TEST_SUITE override: $TEST_SUITE${NC}"
    else
        echo -e "${RED}Invalid TEST_SUITE value: $TEST_SUITE. Defaulting to ALL.${NC}"
        SELECTED_SUITE="ALL"
    fi
else
    # Show menu and prompt
    print_suite_menu
    read -r -t 5 -p "Enter your choice [0-$(( ${#AVAILABLE_SUITES[@]} - 1 ))]: " SUITE_CHOICE
    if [[ -z "$SUITE_CHOICE" ]]; then
        SUITE_CHOICE=0
    fi
    
    # Validate numeric selection
    if ! [[ "$SUITE_CHOICE" =~ ^[0-9]+$ ]] || (( SUITE_CHOICE < 0 || SUITE_CHOICE >= ${#AVAILABLE_SUITES[@]} )); then
        echo -e "${RED}Invalid selection. Defaulting to ${AVAILABLE_SUITES[0]}.${NC}"
        SUITE_CHOICE=0
    fi
    SELECTED_SUITE="${AVAILABLE_SUITES[$SUITE_CHOICE]}"
fi
echo -e "\n${BOLD}Selected suite:${NC} ${CYAN}$SELECTED_SUITE${NC}\n"

# Change to the directory where this script is located
cd "$(dirname "$0")" || exit

# Create test_results directory if it doesn't exist
mkdir -p test_results

# Track overall test results
OVERALL_RESULT=0
BASH_RESULT=0
CPP_RESULT=0
FAILED_SUITES=()

# Initialize bash test counters
BASH_TOTAL=0
BASH_PASSED=0
BASH_FAILED=0
BASH_SKIPPED=0

# Count tests automatically
CPP_TOTAL=$(count_cpp_tests)
BASH_TOTAL=$(count_bash_tests)

if [ "$CPP_TOTAL" -eq 0 ]; then
    echo "Warning: No C++ tests found in CMakeLists.txt" >&2
fi

if [ "$BASH_TOTAL" -eq 0 ]; then
    echo "Warning: No bash tests found in bash-tests directory" >&2
fi

# Initialize C++ test counters
CPP_PASSED=0
CPP_FAILED=0

print_header

# PHASE 1: Bash Tests
# Always runs run_bash_tests.sh to get live test results
if [[ "$SELECTED_SUITE" == "ALL" || "$SELECTED_SUITE" == "Bash" ]]; then
    if [[ "$SELECTED_SUITE" == "ALL" ]]; then
        print_phase_header "1" "Bash Tests"
    else
        echo -e "${BOLD}${MAGENTA}Bash Tests${NC}"
        echo -e "${MAGENTA}------------------------------------------------------------${NC}"
    fi
    print_info_line "Output directory" "test_results"
    print_info_line "Summary file" "test_results/summary.txt (generated by tests)"
    print_info_line "Detailed log" "test_results/detailed.log"
    print_info_line "Start time" "$BASH_START_TIME"
    echo ""

    # Run bash tests and capture results
    if [ -f "./bash-tests/run_bash_tests.sh" ]; then
        echo -e "${BLUE}[INFO]${NC} Running bash tests to get live results..."
        echo -e "${BLUE}[INFO]${NC} This may take a few minutes for comprehensive tests..."
        echo -e "${BLUE}[INFO]${NC} Note: The script will wait for tests to complete or timeout (calculated dynamically)"
        
        # Calculate dynamic timeout for bash tests (same logic as run_bash_tests.sh)
        BASH_TEST_COUNT=$(find bash-tests -name "test_*.sh" -o -name "*.sh" | grep -c -v "run_.*\.sh")
        BASH_TIMEOUT=$((BASH_TEST_COUNT * 30))  # 30 seconds per test
        
        # Run bash tests in background and show progress
        echo -e "${BLUE}[INFO]${NC} Starting bash test execution..."
        echo -e "${BLUE}[INFO]${NC} Found $BASH_TEST_COUNT tests, calculated timeout: ${BASH_TIMEOUT}s"
        
        # Run the tests and show real-time progress
        echo -e "${BLUE}[INFO]${NC} Tests are running... (timeout: ${BASH_TIMEOUT}s)"
        echo -e "${BLUE}[INFO]${NC} Showing real-time progress:"
        echo ""
        
        # Run tests and display output in real-time
        timeout "${BASH_TIMEOUT}s" bash ./bash-tests/run_bash_tests.sh 2>&1 | tee /tmp/bash_test_output.tmp
        BASH_RESULT=${PIPESTATUS[0]}
        BASH_OUTPUT=$(cat /tmp/bash_test_output.tmp 2>/dev/null || echo "")
        rm -f /tmp/bash_test_output.tmp
        
        echo -e "${BLUE}[INFO]${NC} Bash tests completed with exit code: $BASH_RESULT"
        
        # Parse bash test results from the summary file (generated by run_bash_tests.sh)
        if [ "$BASH_RESULT" -eq 0 ] && [ -f "test_results/summary.txt" ]; then
            # Read test counts from the summary file
            BASH_TOTAL=$(grep "Total tests:" "test_results/summary.txt" | grep -o "[0-9]*" || echo "0")
            BASH_PASSED=$(grep "Passed:" "test_results/summary.txt" | grep -o "[0-9]*" || echo "0")
            BASH_FAILED=$(grep "Failed:" "test_results/summary.txt" | grep -o "[0-9]*" || echo "0")
            BASH_SKIPPED=$(grep "Skipped:" "test_results/summary.txt" | grep -o "[0-9]*" || echo "0")
        elif [ "$BASH_RESULT" -eq 124 ]; then
            # Timeout occurred, try to read partial results from summary file if available
            echo -e "${YELLOW}[WARNING]${NC} Bash tests timed out, reading partial results..."
            if [ -f "test_results/summary.txt" ]; then
                BASH_TOTAL=$(grep "Total tests:" "test_results/summary.txt" | grep -o "[0-9]*" || echo "0")
                BASH_PASSED=$(grep "Passed:" "test_results/summary.txt" | grep -o "[0-9]*" || echo "0")
                BASH_FAILED=$(grep "Failed:" "test_results/summary.txt" | grep -o "[0-9]*" || echo "0")
                BASH_SKIPPED=$(grep "Skipped:" "test_results/summary.txt" | grep -o "[0-9]*" || echo "0")
            else
                BASH_TOTAL=0
                BASH_PASSED=0
                BASH_FAILED=0
                BASH_SKIPPED=0
            fi
        else
            # If bash tests failed or summary file not found, set default values
            BASH_TOTAL=0
            BASH_PASSED=0
            BASH_FAILED=1
            BASH_SKIPPED=0
        fi
        
        # Calculate bash success rate (for potential future use)
        # shellcheck disable=SC2034
        BASH_SUCCESS_RATE=0
        if [ "$BASH_TOTAL" -gt 0 ]; then
            # shellcheck disable=SC2034
            BASH_SUCCESS_RATE=$((BASH_PASSED * 100 / BASH_TOTAL))
        fi
        
        # Determine bash status
        if [ "$BASH_RESULT" -eq 124 ]; then
            BASH_STATUS="${YELLOW}⚠️  TIMEOUT${NC}"
            OVERALL_RESULT=1
            FAILED_SUITES+=("Bash")
        elif [ "$BASH_RESULT" -eq 0 ] && [ "$BASH_FAILED" -eq 0 ]; then
            BASH_STATUS="${GREEN}✅ PASSED${NC}"
        else
            BASH_STATUS="${RED}❌ FAILED${NC}"
            OVERALL_RESULT=1
            FAILED_SUITES+=("Bash")
        fi
        
        # Display bash test results summary (only if bash tests failed to avoid duplication)
        if [ "$BASH_RESULT" -ne 0 ]; then
            if [ -f "test_results/summary.txt" ]; then
                echo "Bash Test Results:"
                cat "test_results/summary.txt"
            else
                echo "Bash Test Results:"
                echo "$BASH_OUTPUT"
            fi
        fi
        
        # Summary already displayed by bash test runner, no need to duplicate
        
    else
        print_error "bash-tests/run_bash_tests.sh not found"
        BASH_STATUS="${RED}❌ FAILED (script not found)${NC}"
        OVERALL_RESULT=1
    fi
    if [[ "$SELECTED_SUITE" == "ALL" ]]; then
        echo ""
        print_separator
        echo ""
    fi
fi

# PHASE 2: C++ Tests
# Always runs run_cpp_tests.sh to get live test results
if [[ "$SELECTED_SUITE" == "ALL" || "$SELECTED_SUITE" == "C++" ]]; then
    if [[ "$SELECTED_SUITE" == "ALL" ]]; then
        print_phase_header "2" "C++ Tests"
    else
        echo -e "${BOLD}${MAGENTA}C++ Tests${NC}"
        echo -e "${MAGENTA}------------------------------------------------------------${NC}"
    fi
    print_info_line "Project root" "$PROJECT_ROOT"
    print_info_line "Test directory" "$test_dir"
    print_info_line "Build directory" "$BUILD_DIR"
    echo ""

    # Run C++ tests
    if [ -f "./cpp-tests/run_cpp_tests.sh" ]; then
        echo -e "${BLUE}[INFO]${NC} Running C++ tests to get live results..."
        echo -e "${BLUE}[INFO]${NC} This may take a few minutes for comprehensive tests..."
        
        # Calculate dynamic timeout for C++ tests
        CPP_TEST_COUNT=$(count_cpp_tests)
        CPP_TIMEOUT=$((CPP_TEST_COUNT * 30))  # 30 seconds per test
        
        # Run the tests and show real-time progress
        echo -e "${BLUE}[INFO]${NC} Starting C++ test execution..."
        echo -e "${BLUE}[INFO]${NC} Found $CPP_TEST_COUNT tests, calculated timeout: ${CPP_TIMEOUT}s"
        echo -e "${BLUE}[INFO]${NC} Tests are running... (timeout: ${CPP_TIMEOUT}s)"
        echo -e "${BLUE}[INFO]${NC} Showing real-time progress:"
        echo ""
        
        # Run tests and display output in real-time
        timeout "${CPP_TIMEOUT}s" bash ./cpp-tests/run_cpp_tests.sh 2>&1 | tee /tmp/cpp_test_output.tmp
        CPP_RESULT=${PIPESTATUS[0]}
        CPP_OUTPUT=$(cat /tmp/cpp_test_output.tmp 2>/dev/null || echo "")
        rm -f /tmp/cpp_test_output.tmp
        
        echo -e "${BLUE}[INFO]${NC} C++ tests completed with exit code: $CPP_RESULT"
        
        # Parse C++ test results from the summary file (generated by run_cpp_tests.sh)
        if [ "$CPP_RESULT" -eq 0 ] && [ -f "test_results/cpp_tests_summary.txt" ]; then
            # Read test counts from the summary file (new format)
            CPP_TOTAL=$(grep "Total tests:" "test_results/cpp_tests_summary.txt" | grep -o "[0-9]*" || echo "0")
            CPP_PASSED=$(grep "Passed:" "test_results/cpp_tests_summary.txt" | grep -o "[0-9]*" || echo "0")
            CPP_FAILED=$(grep "Failed:" "test_results/cpp_tests_summary.txt" | grep -o "[0-9]*" || echo "0")
            
            # If no Failed line found, assume 0 failed (since it's not shown when 100% success)
            if [ -z "$CPP_FAILED" ] || [ "$CPP_FAILED" = "" ]; then
                CPP_FAILED=0
            fi
        else
            # If C++ tests failed or summary file not found, set default values
            CPP_TOTAL=0
            CPP_PASSED=0
            CPP_FAILED=1
        fi
        
        # Calculate C++ success rate (for potential future use)
        # shellcheck disable=SC2034
        CPP_SUCCESS_RATE=0
        if [ "$CPP_TOTAL" -gt 0 ]; then
            # shellcheck disable=SC2034
            CPP_SUCCESS_RATE=$((CPP_PASSED * 100 / CPP_TOTAL))
        fi
        
        # Determine C++ status
        if [ "$CPP_RESULT" -eq 0 ] && [ "$CPP_FAILED" -eq 0 ]; then
            CPP_STATUS="${GREEN}✅ PASSED${NC}"
        else
            CPP_STATUS="${RED}❌ FAILED${NC}"
            OVERALL_RESULT=1
            FAILED_SUITES+=("C++")
        fi
        
        # Display C++ test results summary (only if C++ tests failed to avoid duplication)
        if [ "$CPP_RESULT" -ne 0 ]; then
            if [ -f "test_results/cpp_tests_summary.txt" ]; then
                echo "C++ Test Results:"
                cat "test_results/cpp_tests_summary.txt"
            else
                echo "C++ Test Results:"
                echo "$CPP_OUTPUT"
            fi
        fi
        
        # Summary already displayed by C++ test runner, no need to duplicate
        
    else
        print_error "cpp-tests/run_cpp_tests.sh not found"
        CPP_STATUS="${RED}❌ FAILED (script not found)${NC}"
        OVERALL_RESULT=1
    fi
    if [[ "$SELECTED_SUITE" == "ALL" ]]; then
        echo ""
        print_separator
        echo ""
    fi
fi

# FINAL SUMMARY
print_final_header

# Determine final status
if [ $OVERALL_RESULT -eq 0 ]; then
    if [ "$BASH_TOTAL" -eq 0 ] && [ "$CPP_TOTAL" -eq 0 ]; then
        FINAL_STATUS="${YELLOW}⚠️  No tests found to run${NC}"
    else
        FINAL_STATUS="${GREEN}✅ All test suites passed${NC}"
    fi
else
    if [ ${#FAILED_SUITES[@]} -eq 1 ]; then
        FINAL_STATUS="${RED}❌ ${FAILED_SUITES[0]} test suite failed${NC}"
    else
        FINAL_STATUS="${RED}❌ Failed test suites:${NC}"
        for suite in "${FAILED_SUITES[@]}"; do
            echo -e "  ${RED}• $suite${NC}"
        done
    fi
fi

echo -e "${CYAN}Bash tests     :${NC} $BASH_STATUS  ${CYAN}($BASH_PASSED/$BASH_TOTAL passed)${NC}"
echo -e "${CYAN}C++ tests      :${NC} $CPP_STATUS  ${CYAN}($CPP_PASSED/$CPP_TOTAL passed)${NC}"
echo ""
echo -e "${CYAN}Overall result :${NC} $FINAL_STATUS"
echo -e "${CYAN}Comprehensive summary saved to:${NC}"
echo -e "  ${YELLOW}$PROJECT_ROOT/test_results/comprehensive_test_summary.txt${NC}"

# Generate comprehensive test summary
COMPREHENSIVE_SUMMARY="$PROJECT_ROOT/test_results/comprehensive_test_summary.txt"

# Calculate totals
TOTAL_TESTS=$((BASH_TOTAL + CPP_TOTAL))
TOTAL_PASSED=$((BASH_PASSED + CPP_PASSED))
TOTAL_FAILED=$((BASH_FAILED + CPP_FAILED))
TOTAL_SKIPPED=$BASH_SKIPPED

# Calculate overall success rate
OVERALL_SUCCESS_RATE=0
if [ $TOTAL_TESTS -gt 0 ]; then
    OVERALL_SUCCESS_RATE=$((TOTAL_PASSED * 100 / TOTAL_TESTS))
fi

# Generate comprehensive summary
{
    echo "=========================================="
    echo "      NEXT-VERSION COMPREHENSIVE TEST SUMMARY"
    echo "=========================================="
    echo "Generated: $(date)"
    echo ""
    echo "OVERALL RESULTS:"
    echo "Total tests: $TOTAL_TESTS"
    
    # Only show passed count if not all tests failed
    if [ "$TOTAL_FAILED" -lt "$TOTAL_TESTS" ]; then
        echo "Passed: $TOTAL_PASSED"
    fi
    
    # Only show failed count if not all tests passed
    if [ "$TOTAL_PASSED" -lt "$TOTAL_TESTS" ]; then
        echo "Failed: $TOTAL_FAILED"
    fi
    
    # Only show skipped if there are any
    if [ "$TOTAL_SKIPPED" -gt 0 ]; then
        echo "Skipped: $TOTAL_SKIPPED"
    fi
    
    echo "Overall success rate: $OVERALL_SUCCESS_RATE%"
    echo ""
    echo "BREAKDOWN BY TEST TYPE:"
    echo ""
    echo "Bash Tests:"
    echo "  Total: $BASH_TOTAL"
    
    # Only show passed count if not all tests failed
    if [ "$BASH_FAILED" -lt "$BASH_TOTAL" ]; then
        echo "  Passed: $BASH_PASSED"
    fi
    
    # Only show failed count if not all tests passed
    if [ "$BASH_PASSED" -lt "$BASH_TOTAL" ]; then
        echo "  Failed: $BASH_FAILED"
    fi
    
    # Only show skipped if there are any
    if [ "$BASH_SKIPPED" -gt 0 ]; then
        echo "  Skipped: $BASH_SKIPPED"
    fi
    
    if [ "$BASH_TOTAL" -gt 0 ]; then
        BASH_RATE=$((BASH_PASSED * 100 / BASH_TOTAL))
        echo "  Success rate: $BASH_RATE%"
    fi
    echo ""
    echo "C++ Tests:"
    echo "  Total: $CPP_TOTAL"
    
    # Only show passed count if not all tests failed
    if [ "$CPP_FAILED" -lt "$CPP_TOTAL" ]; then
        echo "  Passed: $CPP_PASSED"
    fi
    
    # Only show failed count if not all tests passed
    if [ "$CPP_PASSED" -lt "$CPP_TOTAL" ]; then
        echo "  Failed: $CPP_FAILED"
    fi
    
    # Only show skipped if there are any (C++ tests don't have skipped, but keeping logic consistent)
    if [ 0 -gt 0 ]; then
        echo "  Skipped: 0"
    fi
    
    if [ "$CPP_TOTAL" -gt 0 ]; then
        CPP_RATE=$((CPP_PASSED * 100 / CPP_TOTAL))
        echo "  Success rate: $CPP_RATE%"
    fi
    echo ""
    echo "DETAILED LOGS:"
    echo "Bash test summary: test_results/summary.txt"
    echo "C++ test summary: test_results/cpp_tests_summary.txt"
    echo "Bash detailed log: test_results/detailed.log"
    echo "C++ detailed log: test_results/ctest_cpp_detailed.log"
    echo "C++ build log: test_results/build.log"
    echo "Individual test outputs: test_results/"
    echo ""
    echo "=========================================="
} > "$COMPREHENSIVE_SUMMARY"

print_final_footer

# Cleanup test artifacts
cleanup_test_artifacts

exit $OVERALL_RESULT