// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include "../test_helpers.h"
#include "next_version/semver.h"
#include <iostream>
#include <vector>
#include <string>
#include <cassert>
#include <sstream>
#include <iomanip>

using namespace nv;

void test_version_parsing() {
    std::cout << "Testing version parsing..." << std::endl;
    
    // Test valid version parsing
    std::vector<std::string> valid_versions = {
        "1.0.0", "10.5.12", "0.1.0", "999.999.999"
    };
    
    for (const auto& version : valid_versions) {
        if (!isSemverCore(version)) {
            std::cerr << "FAIL: " << version << " should be valid" << std::endl;
            exit(1);
        }
    }
    
    // Test invalid version parsing
    std::vector<std::string> invalid_versions = {
        "1.0", "1.0.0.0", "v1.0.0", "1.0.0-pre", "1.0.0+build"
    };
    
    for (const auto& version : invalid_versions) {
        if (isSemverCore(version)) {
            std::cerr << "FAIL: " << version << " should be invalid" << std::endl;
            exit(1);
        }
    }
    
    std::cout << "✓ Version parsing tests passed" << std::endl;
}

void test_version_comparison_operators() {
    std::cout << "Testing version comparison operators..." << std::endl;
    
    // Test equality
    if (semverCompare("1.0.0", "1.0.0") != 0) {
        std::cerr << "FAIL: 1.0.0 should equal 1.0.0" << std::endl;
        exit(1);
    }
    
    if (semverCompare("10.5.12", "10.5.12") != 0) {
        std::cerr << "FAIL: 10.5.12 should equal 10.5.12" << std::endl;
        exit(1);
    }
    
    // Test less than
    if (semverCompare("1.0.0", "1.0.1") >= 0) {
        std::cerr << "FAIL: 1.0.0 should be less than 1.0.1" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.0.0", "1.1.0") >= 0) {
        std::cerr << "FAIL: 1.0.0 should be less than 1.1.0" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.0.0", "2.0.0") >= 0) {
        std::cerr << "FAIL: 1.0.0 should be less than 2.0.0" << std::endl;
        exit(1);
    }
    
    // Test greater than
    if (semverCompare("1.0.1", "1.0.0") <= 0) {
        std::cerr << "FAIL: 1.0.1 should be greater than 1.0.0" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.1.0", "1.0.0") <= 0) {
        std::cerr << "FAIL: 1.1.0 should be greater than 1.0.0" << std::endl;
        exit(1);
    }
    
    if (semverCompare("2.0.0", "1.0.0") <= 0) {
        std::cerr << "FAIL: 2.0.0 should be greater than 1.0.0" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Version comparison operator tests passed" << std::endl;
}

void test_version_increment_logic() {
    std::cout << "Testing version increment logic..." << std::endl;
    
    // Test patch increment
    if (semverCompare("1.0.0", "1.0.1") >= 0) {
        std::cerr << "FAIL: 1.0.0 should be less than 1.0.1 (patch increment)" << std::endl;
        exit(1);
    }
    
    if (semverCompare("10.5.12", "10.5.13") >= 0) {
        std::cerr << "FAIL: 10.5.12 should be less than 10.5.13 (patch increment)" << std::endl;
        exit(1);
    }
    
    // Test minor increment
    if (semverCompare("1.0.0", "1.1.0") >= 0) {
        std::cerr << "FAIL: 1.0.0 should be less than 1.1.0 (minor increment)" << std::endl;
        exit(1);
    }
    
    if (semverCompare("10.5.12", "10.6.0") >= 0) {
        std::cerr << "FAIL: 10.5.12 should be less than 10.6.0 (minor increment)" << std::endl;
        exit(1);
    }
    
    // Test major increment
    if (semverCompare("1.0.0", "2.0.0") >= 0) {
        std::cerr << "FAIL: 1.0.0 should be less than 2.0.0 (major increment)" << std::endl;
        exit(1);
    }
    
    if (semverCompare("10.5.12", "11.0.0") >= 0) {
        std::cerr << "FAIL: 10.5.12 should be less than 11.0.0 (major increment)" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Version increment logic tests passed" << std::endl;
}

void test_prerelease_comparison() {
    std::cout << "Testing prerelease comparison..." << std::endl;
    
    // Test release vs prerelease
    if (semverCompare("1.0.0", "1.0.0-alpha") <= 0) {
        std::cerr << "FAIL: 1.0.0 should be greater than 1.0.0-alpha" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.0.0", "1.0.0-beta") <= 0) {
        std::cerr << "FAIL: 1.0.0 should be greater than 1.0.0-beta" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.0.0", "1.0.0-rc.1") <= 0) {
        std::cerr << "FAIL: 1.0.0 should be greater than 1.0.0-rc.1" << std::endl;
        exit(1);
    }
    
    // Test prerelease ordering
    if (semverCompare("1.0.0-alpha", "1.0.0-beta") >= 0) {
        std::cerr << "FAIL: 1.0.0-alpha should be less than 1.0.0-beta" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.0.0-beta", "1.0.0-rc.1") >= 0) {
        std::cerr << "FAIL: 1.0.0-beta should be less than 1.0.0-rc.1" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.0.0-rc.1", "1.0.0-rc.2") >= 0) {
        std::cerr << "FAIL: 1.0.0-rc.1 should be less than 1.0.0-rc.2" << std::endl;
        exit(1);
    }
    
    // Test numeric vs non-numeric prerelease
    if (semverCompare("1.0.0-1", "1.0.0-alpha") >= 0) {
        std::cerr << "FAIL: 1.0.0-1 should be less than 1.0.0-alpha" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.0.0-alpha", "1.0.0-1") <= 0) {
        std::cerr << "FAIL: 1.0.0-alpha should be greater than 1.0.0-1" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Prerelease comparison tests passed" << std::endl;
}

void test_version_rollover_logic() {
    std::cout << "Testing version rollover logic..." << std::endl;
    
    // Test patch rollover
    if (semverCompare("1.0.999", "1.1.0") >= 0) {
        std::cerr << "FAIL: 1.0.999 should be less than 1.1.0 (patch rollover)" << std::endl;
        exit(1);
    }
    
    if (semverCompare("10.5.999", "10.6.0") >= 0) {
        std::cerr << "FAIL: 10.5.999 should be less than 10.6.0 (patch rollover)" << std::endl;
        exit(1);
    }
    
    // Test minor rollover
    if (semverCompare("1.999.0", "2.0.0") >= 0) {
        std::cerr << "FAIL: 1.999.0 should be less than 2.0.0 (minor rollover)" << std::endl;
        exit(1);
    }
    
    if (semverCompare("10.999.0", "11.0.0") >= 0) {
        std::cerr << "FAIL: 10.999.0 should be less than 11.0.0 (minor rollover)" << std::endl;
        exit(1);
    }
    
    // Test major rollover
    if (semverCompare("999.0.0", "1000.0.0") >= 0) {
        std::cerr << "FAIL: 999.0.0 should be less than 1000.0.0 (major rollover)" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Version rollover logic tests passed" << std::endl;
}

void test_edge_case_versions() {
    std::cout << "Testing edge case versions..." << std::endl;
    
    // Test zero versions
    if (semverCompare("0.0.0", "0.0.1") >= 0) {
        std::cerr << "FAIL: 0.0.0 should be less than 0.0.1" << std::endl;
        exit(1);
    }
    
    if (semverCompare("0.0.0", "0.1.0") >= 0) {
        std::cerr << "FAIL: 0.0.0 should be less than 0.1.0" << std::endl;
        exit(1);
    }
    
    if (semverCompare("0.0.0", "1.0.0") >= 0) {
        std::cerr << "FAIL: 0.0.0 should be less than 1.0.0" << std::endl;
        exit(1);
    }
    
    // Test very large versions
    if (semverCompare("999.999.999", "1000.0.0") >= 0) {
        std::cerr << "FAIL: 999.999.999 should be less than 1000.0.0" << std::endl;
        exit(1);
    }
    
    // Test single digit vs multi-digit
    if (semverCompare("1.0.0", "10.0.0") >= 0) {
        std::cerr << "FAIL: 1.0.0 should be less than 10.0.0" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.0.0", "1.10.0") >= 0) {
        std::cerr << "FAIL: 1.0.0 should be less than 1.10.0" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.0.0", "1.0.10") >= 0) {
        std::cerr << "FAIL: 1.0.0 should be less than 1.0.10" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Edge case version tests passed" << std::endl;
}

void test_version_validation_edge_cases() {
    std::cout << "Testing version validation edge cases..." << std::endl;
    
    // Test leading zeros (should be invalid)
    if (isSemverCore("01.0.0")) {
        std::cerr << "FAIL: 01.0.0 should be invalid (leading zero in major)" << std::endl;
        exit(1);
    }
    
    if (isSemverCore("1.00.0")) {
        std::cerr << "FAIL: 1.00.0 should be invalid (leading zero in minor)" << std::endl;
        exit(1);
    }
    
    if (isSemverCore("1.0.01")) {
        std::cerr << "FAIL: 1.0.01 should be invalid (leading zero in patch)" << std::endl;
        exit(1);
    }
    
    // Test empty components
    if (isSemverCore("1..0")) {
        std::cerr << "FAIL: 1..0 should be invalid (empty minor)" << std::endl;
        exit(1);
    }
    
    if (isSemverCore("1.0.")) {
        std::cerr << "FAIL: 1.0. should be invalid (empty patch)" << std::endl;
        exit(1);
    }
    
    if (isSemverCore(".1.0")) {
        std::cerr << "FAIL: .1.0 should be invalid (empty major)" << std::endl;
        exit(1);
    }
    
    // Test non-numeric components
    if (isSemverCore("a.0.0")) {
        std::cerr << "FAIL: a.0.0 should be invalid (non-numeric major)" << std::endl;
        exit(1);
    }
    
    if (isSemverCore("1.a.0")) {
        std::cerr << "FAIL: 1.a.0 should be invalid (non-numeric minor)" << std::endl;
        exit(1);
    }
    
    if (isSemverCore("1.0.a")) {
        std::cerr << "FAIL: 1.0.a should be invalid (non-numeric patch)" << std::endl;
        exit(1);
    }
    
    std::cout << "✓ Version validation edge case tests passed" << std::endl;
}

void test_comprehensive_version_sequences() {
    std::cout << "Testing comprehensive version sequences..." << std::endl;
    
    // Test a sequence of versions that should be in order
    std::vector<std::string> version_sequence = {
        "0.0.1", "0.1.0", "0.1.1", "1.0.0", "1.0.1", "1.1.0", "1.1.1",
        "2.0.0", "2.0.1", "2.1.0", "2.1.1", "10.0.0", "10.5.12", "10.5.13"
    };
    
    for (size_t i = 0; i < version_sequence.size() - 1; i++) {
        if (semverCompare(version_sequence[i], version_sequence[i + 1]) >= 0) {
            std::cerr << "FAIL: " << version_sequence[i] << " should be less than " 
                      << version_sequence[i + 1] << std::endl;
            exit(1);
        }
    }
    
    // Test that reverse sequence is in descending order
    for (size_t i = version_sequence.size() - 1; i > 0; i--) {
        if (semverCompare(version_sequence[i], version_sequence[i - 1]) <= 0) {
            std::cerr << "FAIL: " << version_sequence[i] << " should be greater than " 
                      << version_sequence[i - 1] << std::endl;
            exit(1);
        }
    }
    
    std::cout << "✓ Comprehensive version sequence tests passed" << std::endl;
}

int main() {
    std::cout << "Running comprehensive version math tests..." << std::endl;
    
    test_version_parsing();
    test_version_comparison_operators();
    test_version_increment_logic();
    test_prerelease_comparison();
    test_version_rollover_logic();
    test_edge_case_versions();
    test_version_validation_edge_cases();
    test_comprehensive_version_sequences();
    
    std::cout << "All version math tests passed!" << std::endl;
    return 0;
}
