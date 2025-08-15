#!/bin/bash

# Debug script to test run_test function

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run test
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_exit="$3"
    local expected_output="$4"
    
    printf '%sRunning: %s%s\n' "${YELLOW}" "$test_name" "${NC}"
    
    # Run the test command
    local output
    # Temporarily disable -e to allow capturing non-zero exit codes safely
    set +e
    output=$(eval "$test_cmd" 2>&1)
    local exit_code=$?
    
    # Check exit code
    if [[ $exit_code -eq $expected_exit ]]; then
        printf '%s✓ Exit code correct (%d)%s\n' "${GREEN}" "$exit_code" "${NC}"
    else
        printf '%s✗ Exit code wrong: got %d, expected %d%s\n' "${RED}" "$exit_code" "$expected_exit" "${NC}"
        ((TESTS_FAILED++))
        return 1  # Return 1 to indicate test failure
    fi
    
    # Check output if specified
    if [[ -n "$expected_output" ]]; then
        if echo "$output" | grep -q "$expected_output"; then
            printf '%s✓ Output contains expected text%s\n' "${GREEN}" "${NC}"
        else
            printf '%s✗ Output missing expected text: %s%s\n' "${RED}" "$expected_output" "${NC}"
            printf 'Actual output:\n%s\n' "$output"
            ((TESTS_FAILED++))
            return 1  # Return 1 to indicate test failure
        fi
    fi
    
    ((TESTS_PASSED++))
    printf '%s✓ Test passed%s\n\n' "${GREEN}" "${NC}"
    return 0
}

echo "Starting debug test..."

# Test 1
run_test "Simple test 1" "echo 'test1'" 0 "test1"

echo "After test 1"

# Test 2
run_test "Simple test 2" "echo 'test2'" 0 "test2"

echo "After test 2"

# Test 3 - This test is intentionally designed to fail
run_test "Failing test" "exit 1" 1 ""

echo "After test 3"

# Test 4
run_test "Simple test 4" "echo 'test4'" 0 "test4"

echo "After test 4"

echo "All tests completed"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"

# Exit with appropriate code
if [[ $TESTS_FAILED -eq 0 ]]; then
    exit 0
else
    exit 1
fi
