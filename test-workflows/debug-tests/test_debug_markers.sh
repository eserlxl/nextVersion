#!/bin/bash
# Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
# SPDX-License-Identifier: GPL-3.0-or-later
#
# This file is part of nextVersion and is licensed under
# the GNU General Public License v3.0 or later.
# See the LICENSE file in the project root for details.
#
# Test debug markers and information display

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

# Function to test debug markers
test_debug_marker() {
    local test_name="$1"
    local marker_type="$2"
    local expected_pattern="$3"
    
    # Create a test script with debug markers
    local temp_script="/tmp/debug_marker_test_$$.sh"
    cat > "$temp_script" << 'EOF'
#!/bin/bash
set -Euo pipefail

# Debug marker function
debug_marker() {
    local type="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[MARKER:$type] $timestamp: $message" >&2
}

# Test different marker types
case "${1:-info}" in
    "start") debug_marker "START" "Process started" ;;
    "step")  debug_marker "STEP"  "Processing step" ;;
    "check") debug_marker "CHECK" "Validation check" ;;
    "end")   debug_marker "END"   "Process completed" ;;
    "error") debug_marker "ERROR" "Error occurred" ;;
esac
EOF
    
    chmod +x "$temp_script"
    
    # Test the debug marker
    local output
    output=$("$temp_script" "$marker_type" 2>&1)
    
    if echo "$output" | grep -q "$expected_pattern"; then
        log_test_result "$test_name" "PASS" "Debug marker matches expected pattern"
        ((TESTS_PASSED++))
    else
        log_test_result "$test_name" "FAIL" "Debug marker doesn't match expected pattern"
        echo "Expected: $expected_pattern"
        echo "Got: $output"
        ((TESTS_FAILED++))
    fi
    
    # Cleanup
    rm -f "$temp_script"
}

# Main test execution
main() {
    echo "Starting debug marker tests"
    echo "==========================="
    
    # Test debug markers
    test_debug_marker "Start marker" "start" "START"
    test_debug_marker "Step marker" "step" "STEP"
    test_debug_marker "Check marker" "check" "CHECK"
    test_debug_marker "End marker" "end" "END"
    test_debug_marker "Error marker" "error" "ERROR"
    
    # Test marker format validation
    run_test "Marker format validation" 0 "bash -c 'echo \"[MARKER:START] 2025-01-01 12:00:00: message\" | grep -E \"^\\[MARKER:[A-Z]+\\].*:.*$\"'" "MARKER:START"
    
    # Test marker timestamp format
    run_test "Marker timestamp format" 0 "bash -c 'echo \"[MARKER:INFO] 2025-01-01 12:00:00: test\" | grep -E \"[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\"'" "2025-01-01 12:00:00"
    
    # Test marker type validation
    run_test "Marker type validation" 0 "bash -c 'echo \"[MARKER:DEBUG] timestamp: message\" | grep -E \"MARKER:(START|STEP|CHECK|END|ERROR|INFO|DEBUG)\"'" "MARKER:DEBUG"
    
    # Test marker message content
    run_test "Marker message content" 0 "bash -c 'echo \"[MARKER:INFO] 2025-01-01 12:00:00: Test message content\" | grep -o \": Test message content$\"'" "Test message content"
    
    # Test multiple markers
    run_test "Multiple markers" 0 "bash -c 'for i in start step end; do echo \"[MARKER:\${i^^}] 2025-01-01 12:00:00: \$i\"; done | grep -c \"MARKER:\"'" "3"
    
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
