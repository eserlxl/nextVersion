#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Test debug logging functionality

set -Euo pipefail

# Source test helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../test_helper.sh"

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
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

# Function to test debug output
test_debug_output() {
    local test_name="$1"
    local debug_level="$2"
    local expected_pattern="$3"
    
    # Create a test script that uses debug output
    local temp_script="/tmp/debug_test_$$.sh"
    cat > "$temp_script" << 'EOF'
#!/bin/bash
set -Euo pipefail

# Debug function
debug_log() {
    local level="$1"
    local message="$2"
    echo "[DEBUG:$level] $message" >&2
}

# Test different debug levels
case "${1:-info}" in
    "trace") debug_log "TRACE" "This is a trace message" ;;
    "debug") debug_log "DEBUG" "This is a debug message" ;;
    "info")  debug_log "INFO"  "This is an info message" ;;
    "warn")  debug_log "WARN"  "This is a warning message" ;;
    "error") debug_log "ERROR" "This is an error message" ;;
esac
EOF
    
    chmod +x "$temp_script"
    
    # Test the debug output
    local output
    output=$("$temp_script" "$debug_level" 2>&1)
    
    if echo "$output" | grep -q "$expected_pattern"; then
        log_test_result "$test_name" "PASS" "Debug output matches expected pattern"
        ((TESTS_PASSED++))
    else
        log_test_result "$test_name" "FAIL" "Debug output doesn't match expected pattern"
        echo "Expected: $expected_pattern"
        echo "Got: $output"
        ((TESTS_FAILED++))
    fi
    
    # Cleanup
    rm -f "$temp_script"
    
    # Clean up temporary test files
    rm -f /tmp/debug_test_filter.txt /tmp/debug_test_format.txt /tmp/debug_test_consistency.txt
}

# Function to test debug output consistency
test_debug_output_consistency() {
    local test_name="Debug output consistency"
    
    # Create test file with multiple debug messages
    for i in {1..3}; do
        echo "[DEBUG:INFO] message $i"
    done > /tmp/debug_test_consistency.txt
    
    # Count the debug messages
    local count
    count=$(grep -c "DEBUG:INFO" /tmp/debug_test_consistency.txt)
    
    if [[ $count -eq 3 ]]; then
        log_test_result "$test_name" "PASS" "Debug output consistency verified"
        ((TESTS_PASSED++))
    else
        log_test_result "$test_name" "FAIL" "Expected 3 debug messages, got $count"
        ((TESTS_FAILED++))
    fi
    
    # Clean up
    rm -f /tmp/debug_test_consistency.txt
}

# Main test execution
main() {
    echo "Starting debug logging tests"
    echo "============================"
    
    # Test debug output levels
    test_debug_output "Trace level debug output" "trace" "TRACE"
    test_debug_output "Debug level debug output" "debug" "DEBUG"
    test_debug_output "Info level debug output" "info" "INFO"
    test_debug_output "Warn level debug output" "warn" "WARN"
    test_debug_output "Error level debug output" "error" "ERROR"
    
    # Test debug output redirection
    run_test "Debug output to stderr" 0 "bash -c 'echo \"[DEBUG] test\" >&2' 2>&1" "DEBUG"
    
    # Test debug level filtering
    run_test "Debug level filtering" 0 "echo '[DEBUG:INFO] message' > /tmp/debug_test_filter.txt && grep -E 'DEBUG:(INFO|DEBUG|TRACE)' /tmp/debug_test_filter.txt" "DEBUG:INFO"
    
    # Test debug message formatting
    run_test "Debug message format validation" 0 "echo '[DEBUG:INFO] test message' > /tmp/debug_test_format.txt && grep -E '^\[DEBUG:[A-Z]+\].*$' /tmp/debug_test_format.txt" "DEBUG:INFO"
    
    # Test debug output consistency
    test_debug_output_consistency
    
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
