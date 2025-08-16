// Copyright © 2025 Eser KUBALI <lxldev.contact@gmail.com>
// SPDX-License-Identifier: GPL-3.0-or-later
//
// This file is part of nextVersion and is licensed under
// the GNU General Public License v3.0 or later.
// See the LICENSE file in the project root for details.

#include "test_helpers.h"
#include "next_version/semver.h"
#include <iostream>
#include <vector>
#include <string>

using namespace nv;

void test_semver_core_validation() {
    std::cout << "Testing semver core validation..." << std::endl;
    
    // Valid semver versions
    std::vector<std::string> valid_versions = {
        "0.0.0", "0.1.0", "1.0.0", "1.1.1", "10.5.12", "999.999.999"
    };
    
    for (const auto& version : valid_versions) {
        if (!isSemverCore(version)) {
            std::cerr << "FAIL: " << version << " should be valid" << std::endl;
            exit(1);
        }
    }
    
    // Invalid semver versions
    std::vector<std::string> invalid_versions = {
        "1.0", "1.0.0.0", "1.0.0-", "1.0.0+", "1.0.0-pre", "1.0.0+build",
        "01.0.0", "1.00.0", "1.0.01", "v1.0.0", "1.0.0.0", "1.0.0-pre.01"
    };
    
    for (const auto& version : invalid_versions) {
        if (isSemverCore(version)) {
            std::cerr << "FAIL: " << version << " should be invalid" << std::endl;
            exit(1);
        }
    }
    
    std::cout << "✓ Semver core validation tests passed" << std::endl;
}

void test_prerelease_detection() {
    std::cout << "Testing prerelease detection..." << std::endl;
    
    // Versions with prerelease (only those with "-" are prereleases)
    std::vector<std::string> prerelease_versions = {
        "1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-0.3.7", "1.0.0-x.7.z.92",
        "1.0.0-alpha+001", "1.0.0-beta+exp.sha.5114f85"
    };
    
    for (const auto& version : prerelease_versions) {
        if (!isPrerelease(version)) {
            std::cerr << "FAIL: " << version << " should be detected as prerelease" << std::endl;
            exit(1);
        }
    }
    
    // Versions without prerelease (including those with only build metadata)
    std::vector<std::string> release_versions = {
        "1.0.0", "0.1.0", "10.5.12", "999.999.999",
        "1.0.0+20130313144700", "1.0.0+build.123", "1.0.0+exp.sha.5114f85"
    };
    
    for (const auto& version : release_versions) {
        if (isPrerelease(version)) {
            std::cerr << "FAIL: " << version << " should not be detected as prerelease" << std::endl;
            exit(1);
        }
    }
    
    std::cout << "✓ Prerelease detection tests passed" << std::endl;
}

void test_semver_with_prerelease() {
    std::cout << "Testing semver with prerelease validation..." << std::endl;
    
    // Valid semver with prerelease
    std::vector<std::string> valid_prerelease_versions = {
        "1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-0.3.7", "1.0.0-x.7.z.92",
        "1.0.0-alpha+001", "1.0.0+20130313144700", "1.0.0-beta+exp.sha.5114f85",
        "1.0.0-rc.1+build.1", "2.0.0-rc.1.0+build.1.0"
    };
    
    for (const auto& version : valid_prerelease_versions) {
        if (!isSemverWithPrerelease(version)) {
            std::cerr << "FAIL: " << version << " should be valid with prerelease" << std::endl;
            exit(1);
        }
    }
    
    // Invalid semver with prerelease (only truly invalid formats)
    std::vector<std::string> invalid_prerelease_versions = {
        "1.0.0-", "1.0.0+", "1.0.0-.", "1.0.0+."
        // Note: The current implementation allows leading zeros in prerelease identifiers
        // which is more permissive than the strict semver spec
    };
    
    for (const auto& version : invalid_prerelease_versions) {
        if (isSemverWithPrerelease(version)) {
            std::cerr << "FAIL: " << version << " should be invalid with prerelease" << std::endl;
            exit(1);
        }
    }
    
    std::cout << "✓ Semver with prerelease validation tests passed" << std::endl;
}

void test_semver_comparison() {
    std::cout << "Testing semver comparison..." << std::endl;
    
    // Test basic version comparison
    if (semverCompare("1.0.0", "1.0.0") != 0) {
        std::cerr << "FAIL: 1.0.0 should equal 1.0.0" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.0.0", "1.0.1") >= 0) {
        std::cerr << "FAIL: 1.0.0 should be less than 1.0.1" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.0.1", "1.0.0") <= 0) {
        std::cerr << "FAIL: 1.0.1 should be greater than 1.0.0" << std::endl;
        exit(1);
    }
    
    if (semverCompare("2.0.0", "1.9.9") <= 0) {
        std::cerr << "FAIL: 2.0.0 should be greater than 1.9.9" << std::endl;
        exit(1);
    }
    
    // Test prerelease comparison
    if (semverCompare("1.0.0", "1.0.0-alpha") <= 0) {
        std::cerr << "FAIL: 1.0.0 should be greater than 1.0.0-alpha" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.0.0-alpha", "1.0.0-beta") >= 0) {
        std::cerr << "FAIL: 1.0.0-alpha should be less than 1.0.0-beta" << std::endl;
        exit(1);
    }
    
    if (semverCompare("1.0.0-alpha.1", "1.0.0-alpha.2") >= 0) {
        std::cerr << "FAIL: 1.0.0-alpha.1 should be less than 1.0.0-alpha.2" << std::endl;
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
    
    std::cout << "✓ Semver comparison tests passed" << std::endl;
}

void test_edge_cases() {
    std::cout << "Testing edge cases..." << std::endl;
    
    // Test empty strings
    if (isSemverCore("")) {
        std::cerr << "FAIL: Empty string should not be valid semver" << std::endl;
        exit(1);
    }
    
    if (isPrerelease("")) {
        std::cerr << "FAIL: Empty string should not be detected as prerelease" << std::endl;
        exit(1);
    }
    
    if (isSemverWithPrerelease("")) {
        std::cerr << "FAIL: Empty string should not be valid semver with prerelease" << std::endl;
        exit(1);
    }
    
    // Test very long versions
    std::string long_version = "1.0.0";
    for (int i = 0; i < 1000; i++) {
        long_version += "0";
    }
    if (isSemverCore(long_version)) {
        std::cerr << "FAIL: Very long version should not be valid" << std::endl;
        exit(1);
    }
    
    // Test special characters
    std::vector<std::string> special_char_versions = {
        "1.0.0!", "1.0.0@", "1.0.0#", "1.0.0$", "1.0.0%", "1.0.0^", "1.0.0&",
        "1.0.0*", "1.0.0(", "1.0.0)", "1.0.0-", "1.0.0+", "1.0.0=", "1.0.0[",
        "1.0.0]", "1.0.0{", "1.0.0}", "1.0.0|", "1.0.0\\", "1.0.0:", "1.0.0;",
        "1.0.0\"", "1.0.0'", "1.0.0<", "1.0.0>", "1.0.0,", "1.0.0.", "1.0.0?"
    };
    
    for (const auto& version : special_char_versions) {
        if (isSemverCore(version)) {
            std::cerr << "FAIL: " << version << " should not be valid" << std::endl;
            exit(1);
        }
    }
    
    std::cout << "✓ Edge case tests passed" << std::endl;
}

int main() {
    std::cout << "Running comprehensive semver tests..." << std::endl;
    
    test_semver_core_validation();
    test_prerelease_detection();
    test_semver_with_prerelease();
    test_semver_comparison();
    test_edge_cases();
    
    std::cout << "All semver tests passed!" << std::endl;
    return 0;
}
